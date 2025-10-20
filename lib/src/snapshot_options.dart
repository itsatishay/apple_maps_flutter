part of apple_maps_flutter;

class SnapshotOptions {
  const SnapshotOptions({
    this.showBuildings = true,
    this.showPointsOfInterest = true,
    this.showAnnotations = true,
    this.showOverlays = true,
    this.darkMode,
  });

  final bool showBuildings;
  final bool showPointsOfInterest;
  final bool showAnnotations;
  final bool showOverlays;
  final bool? darkMode;

  dynamic _toMap() => <String, dynamic>{
        'showBuildings': showBuildings,
        'showPointsOfInterest': showPointsOfInterest,
        'showAnnotations': showAnnotations,
        'showOverlays': showOverlays,
        if (darkMode != null) 'darkMode': darkMode,
      };

  @visibleForTesting
  static SnapshotOptions? fromMap(dynamic json) {
    if (json == null) {
      return null;
    }
    return SnapshotOptions(
      showBuildings: json['showBuildings'],
      showPointsOfInterest: json['showPointsOfInterest'],
      showAnnotations: json['showAnnotations'],
      showOverlays: json['showOverlays'],
      darkMode: json['darkMode'],
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SnapshotOptions typedOther = other;
    return showBuildings == typedOther.showBuildings &&
        showPointsOfInterest == typedOther.showPointsOfInterest &&
        showAnnotations == typedOther.showAnnotations &&
        showOverlays == typedOther.showOverlays &&
        darkMode == typedOther.darkMode;
  }

  @override
  int get hashCode => Object.hash(showBuildings, showPointsOfInterest, showAnnotations, showOverlays, darkMode);

  @override
  String toString() =>
      'SnapshotOptions(showBuildings: $showBuildings, showPointsOfInterest: $showPointsOfInterest, showAnnotations: $showAnnotations, showOverlays: $showOverlays, darkMode: $darkMode)';
}
