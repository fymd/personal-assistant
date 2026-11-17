import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../data/ops_favorite_target.dart';

/// 主机输入旁的收藏快捷条：点选填充；可一键收藏当前主机。
class OpsFavoriteChips extends ConsumerStatefulWidget {
  final String currentHost;
  final ValueChanged<OpsFavoriteTarget> onSelected;
  final VoidCallback? onManage;
  final Future<void> Function()? onSaveCurrent;

  const OpsFavoriteChips({
    super.key,
    required this.currentHost,
    required this.onSelected,
    this.onManage,
    this.onSaveCurrent,
  });

  @override
  ConsumerState<OpsFavoriteChips> createState() => _OpsFavoriteChipsState();
}

class _OpsFavoriteChipsState extends ConsumerState<OpsFavoriteChips> {
  List<OpsFavoriteTarget> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await OpsFavoriteTargetStore().list();
    if (!mounted) return;
    setState(() {
      _items = list.take(12).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    if (_loading) {
      return const SizedBox(height: 8);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('收藏目标', style: TextStyle(fontSize: 12, color: colors.secondaryText)),
            const Spacer(),
            if (widget.onSaveCurrent != null)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: widget.currentHost.trim().isEmpty
                    ? null
                    : () async {
                        await widget.onSaveCurrent!();
                        await _reload();
                      },
                child: const Text('收藏当前', style: TextStyle(fontSize: 12)),
              ),
            if (widget.onManage != null)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: widget.onManage,
                child: const Text('管理', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '暂无收藏，可点「收藏当前」',
              style: TextStyle(fontSize: 11, color: colors.secondaryText),
            ),
          )
        else
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final t = _items[i];
                return ActionChip(
                  label: Text(t.label, style: const TextStyle(fontSize: 12)),
                  onPressed: () async {
                    await OpsFavoriteTargetStore().touch(t.id);
                    widget.onSelected(t);
                    await _reload();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
