import 'package:flutter/material.dart';

import '../models/cell_visual_state.dart';
import '../state/tambola_controller.dart';
import '../theme/app_theme.dart';
import 'number_tile.dart';

/// The 9 x 10 Housie board (1..90).
///
/// The tile size is derived from the available space, so the grid always fills
/// its section exactly on a 5" phone or a 13" tablet without scrolling.
class NumberGrid extends StatelessWidget {
  const NumberGrid({
    super.key,
    required this.controller,
    required this.onTileTap,
  });

  final TambolaController controller;

  /// Called with the tapped number (queue toggle / cancel).
  final ValueChanged<int> onTileTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const int columns = AppMetrics.boardColumns;
        const int rows = AppMetrics.boardRows;
        const double gap = AppMetrics.boardGap;

        final double tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final double tileHeight =
            (constraints.maxHeight - gap * (rows - 1)) / rows;

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: TambolaController.totalNumbers,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: tileWidth <= 0 || tileHeight <= 0
                ? 1
                : tileWidth / tileHeight,
          ),
          itemBuilder: (BuildContext context, int index) {
            final int number = index + 1;
            final CellVisualState state = controller.stateOf(number);
            return NumberTile(
              number: number,
              state: state,
              queueDelay: controller.queueDelayOf(number) ?? 0,
              onTap: () => onTileTap(number),
            );
          },
        );
      },
    );
  }
}
