extension MapExtenstion<K, V> on Map<K, V> {
  /// Returns the first element that satisfies the given [test], or `null` if
  /// there is none.
  V? firstWhereOrNull(bool Function(V element) where) {
    try {
      return values.firstWhere(where);
    } catch (e) {
      return null;
    }
  }
}
