/// Visual state of a single number on the board.
///
/// The controller owns the game data; this enum is the *only* thing the tile
/// widget needs to know in order to paint itself.
enum CellVisualState {
  /// Not called, not queued -> light green tile.
  uncalled,

  /// Pre-selected by the caller, still waiting -> amber tile + "in N" label.
  queued,

  /// Pre-selected and its counter reached 0 -> strong amber tile + "NEXT".
  queuedReady,

  /// Already called -> red tile, white text.
  called,

  /// Most recently called number -> red tile, white text, black outline.
  latest;

  bool get isQueued => this == queued || this == queuedReady;

  bool get isCalled => this == called || this == latest;

  bool get isUncalled => this == uncalled;
}
