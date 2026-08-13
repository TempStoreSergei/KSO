import 'package:flutter/cupertino.dart';

/// Виртуализированная секция в стиле inset grouped.
///
/// В отличие от `CupertinoListSection(children: ...)` создаёт только те
/// элементы, которые нужны текущей области прокрутки.
class SliverCupertinoListSection extends StatelessWidget {
  const SliverCupertinoListSection({
    super.key,
    this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.bottomSpacing = 12,
  });

  final Widget? header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[];

    if (header != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: DefaultTextStyle(
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              child: header!,
            ),
          ),
        ),
      );
    }

    if (itemCount > 0) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final isFirst = index == 0;
                final isLast = index == itemCount - 1;
                final borderRadius = BorderRadius.vertical(
                  top: isFirst ? const Radius.circular(12) : Radius.zero,
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                );

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: borderRadius,
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: CupertinoColors.separator.resolveFrom(context),
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: itemBuilder(context, index),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      );
    }

    if (bottomSpacing > 0) {
      slivers.add(
        SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }
}
