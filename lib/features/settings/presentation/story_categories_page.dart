import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';

/// شاشة إدارة أقسام الستوريز — للمدير لإضافة وتعديل وحذف التصنيفات
class StoryCategoriesPage extends ConsumerStatefulWidget {
  const StoryCategoriesPage({super.key});

  @override
  ConsumerState<StoryCategoriesPage> createState() => _StoryCategoriesPageState();
}

class _StoryCategoriesPageState extends ConsumerState<StoryCategoriesPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _future = repo.fetchStoryCategories();
    });
  }

  Future<void> _showAddEditDialog([Map<String, dynamic>? existing]) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final coverCtrl = TextEditingController(text: existing?['cover_url']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'تعديل قسم ستوري' : 'إضافة قسم ستوري جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم القسم *',
                hintText: 'مثلاً: مناسبات، مشاريع، مجالس...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coverCtrl,
              decoration: const InputDecoration(
                labelText: 'رابط صورة الغلاف (اختياري)',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      if (isEdit) {
        await repo.updateStoryCategory(
          existing['id'].toString(),
          nameCtrl.text.trim(),
          coverCtrl.text.trim(),
        );
      } else {
        await repo.createStoryCategory(
          nameCtrl.text.trim(),
          coverCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم تحديث القسم بنجاح' : 'تمت إضافة القسم بنجاح'),
          backgroundColor: AppColors.paid,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(arabicError(e)),
          backgroundColor: AppColors.overdue,
        ),
      );
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف قسم الستوري'),
        content: Text('هل أنت تأكد من حذف قسم "${item['name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.overdue),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteStoryCategory(item['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف القسم بنجاح'),
          backgroundColor: AppColors.paid,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(arabicError(e)),
          backgroundColor: AppColors.overdue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('أقسام الستوريز'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('قسم جديد'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(arabicError(snapshot.error!)));
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections_bookmark_outlined,
                        size: 48,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد أقسام ستوريز حالياً',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط على زر «قسم جديد» لإضافة قسم ستوري أول للموكـب.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final coverUrl = item['cover_url']?.toString();

                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                        backgroundImage: coverUrl != null && coverUrl.isNotEmpty
                            ? NetworkImage(coverUrl)
                            : null,
                        child: coverUrl == null || coverUrl.isEmpty
                            ? const Icon(Icons.collections_bookmark_rounded,
                                color: AppColors.goldDark, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['name']?.toString() ?? 'بلا اسم',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _showAddEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.overdue),
                        onPressed: () => _deleteCategory(item),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
