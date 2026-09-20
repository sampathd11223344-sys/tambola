import 'package:flutter/material.dart';

import '../models/cell_visual_state.dart';
import '../theme/app_theme.dart';

/// A single number on the board.
///
/// Only three things are ever painted: uncalled, called and latest. The amber
/// `queued` / `queuedReady` styles below are used exclusively in REVEALED mode
/// (`TambolaController(showQueueHints: true)`) - in the default discreet mode a
/// pre-selected number is reported as `uncalled` by the controller, so the
/// upcoming number is never shown on the board.
///
/// Painting rules:
///   uncalled     -> light green fill, dark text
///   queued       -> amber fill, amber border, badge "IN 2" / "IN 1"
///   queuedReady  -> strong amber fill + "NEXT" badge (called on next tick)
///   called       -> red fill, white text
///   latest       -> red fill, white text, thick black outline
class NumberTile extends StatelessWidget {
  const NumberTile({
    super.key,
    required this.number,
    required this.state,
    required this.onTap,
    this.queueDelay = 0,
  });

  final int number;
  final CellVisualState state;
  final VoidCallback onTap;

  /// Remaining delay shown on the badge while the number is queued.
  final int queueDelay;

  @override
  Widget build(BuildContext context) {
    final _TileStyle style = _TileStyle.of(state);
    final String? badge = _badgeLabel();

    return Semantics(
      button: true,
      label: _semanticsLabel(badge),
      child: Material(
        color: style.fill,
        borderRadius: BorderRadius.circular(AppMetrics.tileRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppMetrics.tileRadius),
          splashColor: Colors.black.withOpacity(0.08),
          highlightColor: Colors.black.withOpacity(0.04),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppMetrics.tileRadius),
              border: style.border,
              boxShadow: state == CellVisualState.latest
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33101010),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: <Widget>[
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$number',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: style.text,
                        ),
                      ),
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _QueueBadge(
                      label: badge,
                      ready: state == CellVisualState.queuedReady,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _badgeLabel() {
    switch (state) {
      case CellVisualState.queued:
        return queueDelay <= 1 ? 'IN 1' : 'IN $queueDelay';
      case CellVisualState.queuedReady:
        return 'NEXT';
      case CellVisualState.uncalled:
      case CellVisualState.called:
      case CellVisualState.latest:
        return null;
    }
  }

  String _semanticsLabel(String? badge) {
    final String stateLabel = switch (state) {
      CellVisualState.uncalled => 'not called',
      CellVisualState.queued => 'queued, called after $queueDelay more numbers',
      CellVisualState.queuedReady => 'queued and will be called next',
      CellVisualState.called => 'called',
      CellVisualState.latest => 'just called',
    };
    return 'Number $number, $stateLabel';
  }
}

/// Small pill drawn in the corner of a queued tile.
class _QueueBadge extends StatelessWidget {
  const _QueueBadge({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: ready ? AppColors.tileCalled : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ready ? Colors.white : AppColors.tileQueuedReadyBorder,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          height: 1.2,
          color: ready ? Colors.white : AppColors.tileQueuedReadyBorder,
        ),
      ),
    );
  }
}

/// Colour + border bundle for each [CellVisualState].
class _TileStyle {
  const _TileStyle({required this.fill, required this.text, this.border});

  final Color fill;
  final Color text;
  final BoxBorder? border;

  static _TileStyle of(CellVisualState state) {
    switch (state) {
      case CellVisualState.uncalled:
        return const _TileStyle(
          fill: AppColors.tileUncalled,
          text: AppColors.tileUncalledText,
        );
      case CellVisualState.queued:
        return _TileStyle(
          fill: AppColors.tileQueued,
          text: AppColors.ink,
          border: Border.all(color: AppColors.tileQueuedBorder, width: 2),
        );
      case CellVisualState.queuedReady:
        return _TileStyle(
          fill: AppColors.tileQueuedReady,
          text: AppColors.ink,
          border: Border.all(color: AppColors.tileQueuedReadyBorder, width: 2.5),
        );
      case CellVisualState.called:
        return const _TileStyle(
          fill: AppColors.tileCalled,
          text: AppColors.tileCalledText,
        );
      case CellVisualState.latest:
        return _TileStyle(
          fill: AppColors.tileCalled,
          text: AppColors.tileCalledText,
          border: Border.all(color: AppColors.tileLatestBorder, width: 3),
        );
    }
  }
}
