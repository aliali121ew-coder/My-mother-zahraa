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

    // نخزّن كل نوع في مفتاح مستقل داخل نفس الصندوق
    final res = await fetchList(
      boxName: AppConfig.boxContributors,
      idOf: (m) => m['id'].toString(),
      sensitive: true, // أسماء ومبالغ — لا ارتداد من مخزّن جلسة سابقة (P1)
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

    final list = res.data
        .map(ContributorModel.fromJson)
        .where((c) => type == null || c.type == type)
        .toList();

    return CachedResult(
      data: list,
      fromCache: res.fromCache,
      error: res.error,
    );
  }

  /// إضافة مساهم — في الديمو يُحفظ محلياً في Hive، وفي الإنتاج يُرسل لـ Supabase.
  Future<ContributorModel> create(ContributorModel c) async {
    if (!isLive) {
      await cache.put(_demoBox, c.id, c.toJson());
      return c;
    }

    final row = await db
        .from('contributors')
        .insert(c.toWriteJson()..remove('id'))
        .select()
        .single();
    return ContributorModel.fromJson(row);
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

  /// جلب سجل الدفعات الشهرية لسنة مالية معينة لمشترك
  Future<Map<int, Map<String, dynamic>>> loadMonthlyLedger(
      String contributorId, int year) async {
    try {
      final boxKey = 'ledger_${contributorId}_$year';
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

      // دعم احتياطي ضامن: إذا كان للمشترك تاريخ دفع أخير ومبلغ مسدد، نضمن ظهور شهر تلك الدفعة
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

      if (isPaid && amount > 0) {
        map[month.toString()] = {
          'amount': amount,
          'paid_at': paidAt.toUtc().toIso8601String(),
          'is_paid': true,
        };
      } else {
        map.remove(month.toString());
      }

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
      final existing = cache.readOne(AppConfig.boxContributors, boxKey);
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

      await cache.put(AppConfig.boxContributors, boxKey, map);
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
      final existing = cache.readOne(AppConfig.boxContributors, boxKey);
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
      await cache.put(AppConfig.boxContributors, boxKey, map);
    } catch (_) {}
  }
}

