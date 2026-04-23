enum SnatchDir { north, south, east, west }

extension SnatchDirX on SnatchDir {
  /// Returns the grid-index offset for this direction.
  int get indexDelta => const {
    SnatchDir.north: -4,
    SnatchDir.south:  4,
    SnatchDir.east:   1,
    SnatchDir.west:  -1,
  }[this]!;
}