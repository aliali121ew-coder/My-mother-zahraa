import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../home/data/demo_data.dart';

/// قوائم المتبرعين والمشتركين والدفعات.
///
/// القراءة متاحة للمدير والمسؤول المالي فقط (سياسة RLS)، ودور العضو سيحصل
/// على قائمة فارغة — وهذا **سلوك صحيح مقصود** لا خطأ، لأنه لا يُصرَّح له
/// برؤية الأسماء. الواجهة تُظهر له الإحصائيات المجمّعة بدلاً منها.
class ContributorsRepository extends SupabaseRepository {
  // اسم صندوق Hive الخاص بالإضافات المحلية في وضع الديمو
  static const _demoBox = AppConfig.boxContributors;

  /// جلب كل المساهمين من نوع محدّد، مرتّبين بالأعلى مبلغاً
  Future<CachedResult<List<ContributorModel>>> load(ContributorType? type) async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final rawAll = cache.readAll(_demoBox);
      final deletedIds = <String>{};
      final localMap = <String, ContributorModel>{};

      for (final entry in rawAll) {
        try {
          final id = entry['id']?.toString();
          if (entry.containsKey('deleted_at') && entry['deleted_at'] != null) {
            if (id != null) deletedIds.add(id);
          } else {
            final model = ContributorModel.fromJson(entry);
            localMap[model.id] = model;
          }
        } catch (_) {}
      }

      final allMap = <String, ContributorModel>{};

      for (final c in DemoData.donors) {
        if (!deletedIds.contains(c.id)) {
          allMap[c.id] = c;
        }
      }
      for (final c in DemoData.subscribers) {
        if (!deletedIds.contains(c.id)) {
          allMap[c.id] = c;
        }
      }
      for (final entry in rawAll) {
        try {
          final id = entry['id']?.toString();
          if (entry.containsKey('deleted_at') && entry['deleted_at'] != null) {
            if (id != null) allMap.remove(id);
          } else {
            final model = ContributorModel.fromJson(entry);
            allMap[model.id] = model;
          }
        } catch (_) {}
      }

      final allList = allMap.values.toList();
      final List<ContributorModel> combined;

      if (type == null) {
        combined = allList;
      } else {
        combined = allList.where((c) => c.type == type).toList();
      }

      combined.sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
      return CachedResult(data: combined, fromCache: false);
    }

    // دمج السجلات المحلية المخزنة مع سجلات الخادم لضمان الظهور الفوري
    final localRaw = cache.readAll(_demoBox);
    final localMap = <String, ContributorModel>{};
    for (final entry in localRaw) {
      try {
        if (entry.containsKey('deleted_at') && entry['deleted_at'] != null) {
          // محذوف
        } else {
          final model = ContributorModel.fromJson(entry);
          if (type == null || model.type == type) {
            localMap[model.id] = model;
          }
        }
      } catch (_) {}
    }

    try {
      final res = await fetchList(
        boxName: AppConfig.boxContributors,
        idOf: (m) => m['id'].toString(),
        sensitive: false,
        fetch: () async {
          var query = db.from('contributors').select();
          if (type != null) {
            query = query.eq('type', type.value);
          }
          final rows = await query
              .isFilter('deleted_at', null)
              .order('total_paid', ascending: false);
          return List<Map<String, dynamic>>.from(rows);
        },
      );

      final serverList = res.data
          .map(ContributorModel.fromJson)
          .where((c) => type == null || c.type == type)
          .toList();

      for (final s in serverList) {
        localMap[s.id] = s;
      }

      final combined = localMap.values.toList();
      combined.sort((a, b) => b.totalPaid.compareTo(a.totalPaid));

      return CachedResult(
        data: combined,
        fromCache: res.fromCache,
        error: res.error,
      );
    } catch (e) {
      // الارتداد للبيانات المحلية المتاحة
      final demoList = type == ContributorType.donor
          ? DemoData.donors
          : (type == ContributorType.subscriber
              ? DemoData.subscribers
              : [...DemoData.donors, ...DemoData.subscribers]);

      for (final d in demoList) {
        if (!localMap.containsKey(d.id)) {
          localMap[d.id] = d;
        }
      }

      final combined = localMap.values.toList();
      combined.sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
      return CachedResult(data: combined, fromCache: true, error: e);
    }
  }

  /// إضافة مساهم — يُحفظ محلياً فوراً ويُرسل لـ Supabase عند توفر الاتصال
  Future<ContributorModel> create(ContributorModel c) async {
    // 1. حفظ فوري في المخزن المحلي لضمان عدم توقف الواجهة
    await cache.put(_demoBox, c.id, c.toJson());

    if (isLive) {
      try {
        final writeData = c.toWriteJson()..remove('id');
        final row = await db
            .from('contributors')
            .insert(writeData)
            .select()
            .maybeSingle()
            .timeout(const Duration(seconds: 4));

        if (row != null) {
          final serverModel = ContributorModel.fromJson(row);
          await cache.put(_demoBox, serverModel.id, serverModel.toJson());
          return serverModel;
        }
      } catch (_) {
        // في حال بطء الشبكة أو خطأ RLS، المساهم محفوظ محلياً بنجاح
      }
    }

    return c;
  }

  Future<ContributorModel> update(ContributorModel c) async {
    if (!isLive) {
      await cache.put(_demoBox, c.id, c.toJson());
      return c;
    }

    final row = await db
        .from('contributors')
        .update(c.toWriteJson()..remove('id'))
        .eq('id', c.id)
        .select()
        .single();
    return ContributorModel.fromJson(row);
  }

  /// حذف ناعم: نحفظ السجل ونخفيه، فلا تُفقد الدفعات المرتبطة به
  Future<void> softDelete(String id) async {
    if (!isLive) {
      final existing = cache.readOne(_demoBox, id);
      if (existing != null) {
        final map = Map<String, dynamic>.from(existing);
        map['deleted_at'] = DateTime.now().toUtc().toIso8601String();
        await cache.put(_demoBox, id, map);
      } else {
        await cache.put(_demoBox, 'del_$id', {
          'id': id,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      return;
    }

    await db
        .from('contributors')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  /// مسح جميع البيانات السابقة والوهمية من التخزين المحلي
  Future<void> clearAllDemoData() async {
    await cache.box(_demoBox).clear();
  }

  /// مسح سجلات قسم محدد (متبرعين / مشتركون / داعمون) من التخزين المحلي فقط
  Future<void> clearDemoDataByType(ContributorType? type) async {
    if (type == null) {
      await cache.box(_demoBox).clear();
      return;
    }

    if (!isLive) {
      final rawAll = cache.readAll(_demoBox);
      final nowStr = DateTime.now().toUtc().toIso8601String();

      for (final entry in rawAll) {
        try {
          final model = ContributorModel.fromJson(entry);
          if (model.type == type) {
            final map = Map<String, dynamic>.from(entry);
            map['deleted_at'] = nowStr;
            await cache.put(_demoBox, model.id, map);
          }
        } catch (_) {}
      }

      final demoList = type == ContributorType.donor
          ? DemoData.donors
          : (type == ContributorType.subscriber
              ? DemoData.subscribers
              : <ContributorModel>[]);

      for (final c in demoList) {
        await cache.put(_demoBox, 'del_${c.id}', {
          'id': c.id,
          'deleted_at': nowStr,
        });
      }
    } else {
      await db
          .from('contributors')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('type', type.value);
    }
  }

  /// تجاوز المدير اليدوي لحالة السداد. null = عُد للحساب التلقائي.
  Future<void> setLateOverride(String id, bool? isLate) =>
      db.from('contributors').update({'is_late_override': isLate}).eq('id', id);

  /// سجل دفعات مشترك، الأحدث أولاً
  Future<List<Map<String, dynamic>>> payments(String contributorId) async {
    if (!isLive) {
      return [];
    }
    final rows = await db
        .from('payments')
        .select()
        .eq('contributor_id', contributorId)
        .order('paid_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// تسجيل دفعة. المشغّل في قاعدة البيانات يحدّث تلقائياً آخر دفعة
  /// والمجموع ويلغي أي تجاوز يدوي سابق.
  Future<Map<String, dynamic>> addPayment({
    required String contributorId,
    required num amount,
    DateTime? paidAt,
    String? note,
  }) async {
    final paymentDate = paidAt ?? DateTime.now();
    if (!isLive) {
      final existing = cache.readOne(_demoBox, contributorId);
      if (existing != null) {
        final map = Map<String, dynamic>.from(existing);
        final currentTotal = (map['total_paid'] as num?) ?? 0;
        map['total_paid'] = currentTotal + amount;
        map['last_payment_at'] = paymentDate.toUtc().toIso8601String();
        await cache.put(_demoBox, contributorId, map);
      } else {
        final demoList = [...DemoData.donors, ...DemoData.subscribers];
        final match = demoList.firstWhere(
          (c) => c.id == contributorId,
          orElse: () => ContributorModel(
            id: contributorId,
            type: ContributorType.donor,
            fullName: 'مساهم',
            totalPaid: 0,
            createdAt: DateTime.now(),
          ),
        );
        final updated = match.copyWith(
          totalPaid: match.totalPaid + amount,
          lastPaymentAt: paymentDate,
        );
        await cache.put(_demoBox, contributorId, updated.toJson());
      }

      return {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'contributor_id': contributorId,
        'amount': amount,
        'paid_at': paymentDate.toUtc().toIso8601String(),
        'note': note,
      };
    }

    final row = await db
        .from('payments')
        .insert({
          'contributor_id': contributorId,
          'amount': amount,
          'paid_at': paymentDate.toUtc().toIso8601String(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        })
        .select()
        .single();
    return row;
  }

  /// جلب سجل الدفعات الشهرية لسنة مالية معينة لمشترك — يقرأ أولًا من جدول
  /// `payments` على الخادم (المصدر الموثوق)، ويخزّن النتيجة محليًا في Hive
  /// للسرعة خارج الاتصال، ثم يرتدّ للمخزن فقط عند فشل الشبكة.
  Future<Map<int, Map<String, dynamic>>> loadMonthlyLedger(
      String contributorId, int year) async {
    try {
      final boxKey = 'ledger_${contributorId}_$year';

      // المصدر الأساسي: جدول الدفعات على الخادم — كل دفعة مسددة هنا
      // تُكتب عبر addPayment فتظهر مباشرة في هذا الاستعلام
      if (isLive) {
        try {
          final rows = await db
              .from('payments')
              .select()
              .eq('contributor_id', contributorId)
              .gte('paid_at', DateTime.utc(year, 1, 1).toIso8601String())
              .lt('paid_at', DateTime.utc(year + 1, 1, 1).toIso8601String())
              .order('paid_at', ascending: false);
          final res = <int, Map<String, dynamic>>{};
          for (final row in List<Map<String, dynamic>>.from(rows)) {
            final paidAt = DateTime.tryParse(
              (row['paid_at'] as String?) ?? '',
            );
            if (paidAt == null) continue;
            final m = paidAt.month;
            // لو تكررت دفعات في الشهر نفسه نجمعها
            final prev = res[m];
            res[m] = {
              'amount': ((prev?['amount'] as num?) ?? 0) +
                  ((row['amount'] as num?) ?? 0),
              'paid_at': row['paid_at'],
              'is_paid': true,
            };
          }
          await cache.put(
            AppConfig.boxPayments,
            boxKey,
            {'ledger': res.map((k, v) => MapEntry(k.toString(), v))},
          );
          return res;
        } catch (_) {
          // فشل الشبكة — نكمل للمخزن المحلي أسفله
        }
      }

      var raw = cache.readOne(AppConfig.boxPayments, boxKey);
      raw ??= cache.readOne(AppConfig.boxContributors, boxKey);

      final res = <int, Map<String, dynamic>>{};

      if (raw != null) {
        for (final e in raw.entries) {
          final m = int.tryParse(e.key.toString());
          if (m != null && e.value is Map) {
            res[m] = Map<String, dynamic>.from(e.value as Map);
          }
        }
      }

      if (raw == null) {
        // دعم احتياطي ضامن: ينفّذ فقط إذا لم يكن هنالك أي سجل دفعات مخزن للسنة المالية
        final contribRaw = cache.readOne(_demoBox, contributorId);
        if (contribRaw != null) {
          try {
            final c = ContributorModel.fromJson(contribRaw);
            if (c.lastPaymentAt != null && c.lastPaymentAt!.year == year && c.totalPaid > 0) {
              final m = c.lastPaymentAt!.month;
              if (!res.containsKey(m)) {
                res[m] = {
                  'amount': c.subscriptionAmount ?? c.totalPaid,
                  'paid_at': c.lastPaymentAt!.toUtc().toIso8601String(),
                  'is_paid': true,
                };
              }
            }
          } catch (_) {}
        } else {
          // فحص في الديمو الثابت إن وجد
          final demoList = [...DemoData.donors, ...DemoData.subscribers];
          final match = demoList.where((c) => c.id == contributorId).firstOrNull;
          if (match != null && match.lastPaymentAt != null && match.lastPaymentAt!.year == year && match.totalPaid > 0) {
            final m = match.lastPaymentAt!.month;
            if (!res.containsKey(m)) {
              res[m] = {
                'amount': match.subscriptionAmount ?? match.totalPaid,
                'paid_at': match.lastPaymentAt!.toUtc().toIso8601String(),
                'is_paid': true,
              };
            }
          }
        }
      }

      return res;
    } catch (_) {}
    return {};
  }

  /// حفظ أو تعديل تسديد شهر معين لمشترك
  Future<void> saveMonthPayment({
    required String contributorId,
    required int year,
    required int month,
    required num amount,
    required DateTime paidAt,
    required bool isPaid,
  }) async {
    try {
      final boxKey = 'ledger_${contributorId}_$year';
      var existing = cache.readOne(AppConfig.boxPayments, boxKey);
      existing ??= cache.readOne(AppConfig.boxContributors, boxKey);

      final map = existing != null
          ? Map<String, dynamic>.from(existing)
          : <String, dynamic>{};

      final monthStr = month.toString();

      if (isPaid && amount > 0) {
        final monthData = map.containsKey(monthStr) && map[monthStr] is Map
            ? Map<String, dynamic>.from(map[monthStr] as Map)
            : <String, dynamic>{};

        final donationsList = monthData.containsKey('donations') &&
                monthData['donations'] is List
            ? List<Map<String, dynamic>>.from(monthData['donations'] as List)
            : <Map<String, dynamic>>[];

        if (donationsList.isEmpty &&
            monthData.containsKey('amount') &&
            (monthData['amount'] as num? ?? 0) > 0) {
          donationsList.add({
            'id': 'legacy_1',
            'kind': 'cash',
            'amount': monthData['amount'],
            'date': monthData['paid_at'] ?? paidAt.toUtc().toIso8601String(),
          });
        }

        donationsList.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'kind': 'cash',
          'amount': amount,
          'date': paidAt.toUtc().toIso8601String(),
        });

        num totalCash = 0;
        DateTime latestDate = paidAt;
        for (final d in donationsList) {
          totalCash += (d['amount'] as num? ?? 0);
          final dDateStr = d['date']?.toString();
          if (dDateStr != null) {
            final parsed = DateTime.tryParse(dDateStr);
            if (parsed != null && parsed.isAfter(latestDate)) {
              latestDate = parsed;
            }
          }
        }

        monthData['amount'] = totalCash;
        monthData['paid_at'] = latestDate.toUtc().toIso8601String();
        monthData['is_paid'] = true;
        monthData['donations'] = donationsList;

        map[monthStr] = monthData;
      } else {
        map[monthStr] = {
          'amount': 0,
          'is_paid': false,
          'donations': <Map<String, dynamic>>[],
        };
      }

      await cache.put(AppConfig.boxPayments, boxKey, map);
      await cache.put(AppConfig.boxContributors, boxKey, map);

      await cache.put(AppConfig.boxPayments, boxKey, map);

      final existingContrib = cache.readOne(_demoBox, contributorId);
      if (existingContrib != null) {
        final cMap = Map<String, dynamic>.from(existingContrib);
        if (isPaid && amount > 0) {
          cMap['last_payment_at'] = paidAt.toUtc().toIso8601String();
        }
        await cache.put(_demoBox, contributorId, cMap);
      }

      if (isLive && isPaid && amount > 0) {
        await addPayment(
          contributorId: contributorId,
          amount: amount,
          paidAt: paidAt,
          note: 'تسديد شهر $month لسنة $year',
        );
      }
    } catch (_) {}
  }

  /// جلب تفاصيل التبرع (مواد غذائية وإنشائية) لشهر محدد (مفيد للطباعة)
  Future<String?> getDonationDescForMonth(String contributorId, int year, int? month) async {
    final boxKey = 'ledger_${contributorId}_$year';
    var existing = cache.readOne(AppConfig.boxPayments, boxKey);
    existing ??= cache.readOne(AppConfig.boxContributors, boxKey);
    
    if (existing == null) return null;
    final map = Map<String, dynamic>.from(existing);
    
    // إذا كان التقرير شهري
    if (month != null) {
      final monthStr = month.toString();
      if (!map.containsKey(monthStr) || map[monthStr] == null) return null;
      final mData = Map<String, dynamic>.from(map[monthStr]);
      
      final parts = <String>[];
      final f = mData['food_desc']?.toString().trim();
      if (f != null && f.isNotEmpty) parts.add('غذائية: $f');
      final c = mData['construction_desc']?.toString().trim();
      if (c != null && c.isNotEmpty) parts.add('أنشائية: $c');
      
      if (parts.isNotEmpty) return parts.join(' - ');
      return null;
    } else {
      // إذا كان التقرير سنوي (جميع الأشهر)
      final parts = <String>[];
      for (int m = 1; m <= 12; m++) {
        final monthStr = m.toString();
        if (map.containsKey(monthStr) && map[monthStr] != null) {
          final mData = Map<String, dynamic>.from(map[monthStr]);
          final f = mData['food_desc']?.toString().trim();
          if (f != null && f.isNotEmpty) parts.add('شهر $m غذائية: $f');
          final c = mData['construction_desc']?.toString().trim();
          if (c != null && c.isNotEmpty) parts.add('شهر $m أنشائية: $c');
        }
      }
      if (parts.isNotEmpty) return parts.join(' | ');
      return null;
    }
  }

  /// إضافة تبرع جديد لشهر متبرع (مبالغ مالية / مواد أنشائية / مواد غذائية)
  Future<void> addDonorDonation({
    required String contributorId,
    required int year,
    required int month,
    required String kind, // 'cash', 'food', 'construction'
    required num amount,
    required String textValue,
    required DateTime date,
  }) async {
    try {
      final boxKey = 'ledger_${contributorId}_$year';
      var existing = cache.readOne(AppConfig.boxPayments, boxKey);
      existing ??= cache.readOne(AppConfig.boxContributors, boxKey);

      final map = existing != null
          ? Map<String, dynamic>.from(existing)
          : <String, dynamic>{};

      final monthStr = month.toString();
      final monthData = map.containsKey(monthStr) && map[monthStr] is Map
          ? Map<String, dynamic>.from(map[monthStr] as Map)
          : <String, dynamic>{
              'amount': 0,
              'food_desc': '',
              'construction_desc': '',
              'paid_at': date.toUtc().toIso8601String(),
              'is_paid': true,
              'donations': <Map<String, dynamic>>[],
            };

      final donationsList = monthData.containsKey('donations') &&
              monthData['donations'] is List
          ? List<Map<String, dynamic>>.from(monthData['donations'] as List)
          : <Map<String, dynamic>>[];

      donationsList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'kind': kind,
        'amount': amount,
        'text_value': textValue,
        'date': date.toUtc().toIso8601String(),
      });

      num totalCash = 0;
      final foodTexts = <String>[];
      final constrTexts = <String>[];
      DateTime latestDate = date;

      for (final d in donationsList) {
        final dKind = d['kind']?.toString() ?? 'cash';
        final dAmt = (d['amount'] as num?) ?? 0;
        final dText = d['text_value']?.toString() ?? '';
        final dDateStr = d['date']?.toString();
        if (dDateStr != null) {
          final parsed = DateTime.tryParse(dDateStr);
          if (parsed != null && parsed.isAfter(latestDate)) {
            latestDate = parsed;
          }
        }

        if (dKind == 'cash') {
          totalCash += dAmt;
        } else if (dKind == 'food' && dText.isNotEmpty) {
          foodTexts.add(dText);
        } else if (dKind == 'construction' && dText.isNotEmpty) {
          constrTexts.add(dText);
        }
      }

      monthData['amount'] = totalCash;
      monthData['food_desc'] = foodTexts.join(' ، ');
      monthData['construction_desc'] = constrTexts.join(' ، ');
      monthData['paid_at'] = latestDate.toUtc().toIso8601String();
      monthData['is_paid'] = true;
      monthData['donations'] = donationsList;

      map[monthStr] = monthData;
      await cache.put(AppConfig.boxPayments, boxKey, map);

      final existingContrib = cache.readOne(_demoBox, contributorId);
      if (existingContrib != null) {
        final cMap = Map<String, dynamic>.from(existingContrib);
        cMap['total_paid'] = ((cMap['total_paid'] as num?) ?? 0) + amount;
        cMap['last_payment_at'] = latestDate.toUtc().toIso8601String();
        
        if (kind != 'cash' && textValue.trim().isNotEmpty) {
           final kindLabel = kind == 'food' ? 'مواد غذائية' : 'مواد أنشائية';
           cMap['latest_donation_desc'] = '$kindLabel: $textValue';
        }

        await cache.put(_demoBox, contributorId, cMap);
      }
    } catch (_) {}
  }

  /// حذف تبرع محدد لشهر متبرع
  Future<void> deleteDonorDonation({
    required String contributorId,
    required int year,
    required int month,
    required String donationId,
  }) async {
    try {
      final boxKey = 'ledger_${contributorId}_$year';
      var existing = cache.readOne(AppConfig.boxPayments, boxKey);
      existing ??= cache.readOne(AppConfig.boxContributors, boxKey);
      if (existing == null) return;

      final map = Map<String, dynamic>.from(existing);
      final monthStr = month.toString();
      if (!map.containsKey(monthStr) || map[monthStr] is! Map) return;

      final monthData = Map<String, dynamic>.from(map[monthStr] as Map);
      final donationsList = monthData.containsKey('donations') &&
              monthData['donations'] is List
          ? List<Map<String, dynamic>>.from(monthData['donations'] as List)
          : <Map<String, dynamic>>[];

      donationsList.removeWhere((d) => d['id']?.toString() == donationId);

      if (donationsList.isEmpty) {
        map.remove(monthStr);
      } else {
        num totalCash = 0;
        final foodTexts = <String>[];
        final constrTexts = <String>[];
        DateTime latestDate = DateTime(year, month);

        for (final d in donationsList) {
          final dKind = d['kind']?.toString() ?? 'cash';
          final dAmt = (d['amount'] as num?) ?? 0;
          final dText = d['text_value']?.toString() ?? '';
          final dDateStr = d['date']?.toString();
          if (dDateStr != null) {
            final parsed = DateTime.tryParse(dDateStr);
            if (parsed != null && parsed.isAfter(latestDate)) {
              latestDate = parsed;
            }
          }

          if (dKind == 'cash') {
            totalCash += dAmt;
          } else if (dKind == 'food' && dText.isNotEmpty) {
            foodTexts.add(dText);
          } else if (dKind == 'construction' && dText.isNotEmpty) {
            constrTexts.add(dText);
          }
        }

        monthData['amount'] = totalCash;
        monthData['food_desc'] = foodTexts.join(' ، ');
        monthData['construction_desc'] = constrTexts.join(' ، ');
        monthData['paid_at'] = latestDate.toUtc().toIso8601String();
        monthData['donations'] = donationsList;
        map[monthStr] = monthData;
      }

      await cache.put(AppConfig.boxPayments, boxKey, map);
    } catch (_) {}
  }

  /// تعديل تبرع محدد لشهر متبرع
  Future<void> updateDonorDonation({
    required String contributorId,
    required int year,
    required int month,
    required String donationId,
    required String kind,
    required num amount,
    required String textValue,
    required DateTime date,
  }) async {
    try {
      final boxKey = 'ledger_${contributorId}_$year';
      var existing = cache.readOne(AppConfig.boxPayments, boxKey);
      existing ??= cache.readOne(AppConfig.boxContributors, boxKey);
      if (existing == null) return;

      final map = Map<String, dynamic>.from(existing);
      final monthStr = month.toString();
      if (!map.containsKey(monthStr) || map[monthStr] is! Map) return;

      final monthData = Map<String, dynamic>.from(map[monthStr] as Map);
      final donationsList = monthData.containsKey('donations') &&
              monthData['donations'] is List
          ? List<Map<String, dynamic>>.from(monthData['donations'] as List)
          : <Map<String, dynamic>>[];

      final idx =
          donationsList.indexWhere((d) => d['id']?.toString() == donationId);
      if (idx == -1) return;

      donationsList[idx] = {
        'id': donationId,
        'kind': kind,
        'amount': amount,
        'text_value': textValue,
        'date': date.toUtc().toIso8601String(),
      };

      num totalCash = 0;
      final foodTexts = <String>[];
      final constrTexts = <String>[];
      DateTime latestDate = date;

      for (final d in donationsList) {
        final dKind = d['kind']?.toString() ?? 'cash';
        final dAmt = (d['amount'] as num?) ?? 0;
        final dText = d['text_value']?.toString() ?? '';
        final dDateStr = d['date']?.toString();
        if (dDateStr != null) {
          final parsed = DateTime.tryParse(dDateStr);
          if (parsed != null && parsed.isAfter(latestDate)) {
            latestDate = parsed;
          }
        }

        if (dKind == 'cash') {
          totalCash += dAmt;
        } else if (dKind == 'food' && dText.isNotEmpty) {
          foodTexts.add(dText);
        } else if (dKind == 'construction' && dText.isNotEmpty) {
          constrTexts.add(dText);
        }
      }

      monthData['amount'] = totalCash;
      monthData['food_desc'] = foodTexts.join(' ، ');
      monthData['construction_desc'] = constrTexts.join(' ، ');
      monthData['paid_at'] = latestDate.toUtc().toIso8601String();
      monthData['donations'] = donationsList;
      map[monthStr] = monthData;

      await cache.put(AppConfig.boxPayments, boxKey, map);
    } catch (_) {}
  }
}

