class DependencyStats {
  const DependencyStats({
    required this.totalPackages,
    required this.basePackages,
    required this.intermediatePackages,
    required this.highLevelPackages,
    required this.maxDependencies,
    required this.packageWithMostDeps,
    required this.cyclesDetected,
  });

  final int totalPackages;

  final int basePackages;

  final int intermediatePackages;

  final int highLevelPackages;

  final int maxDependencies;

  final String? packageWithMostDeps;

  final int cyclesDetected;

  factory DependencyStats.fromGraphData({
    required Map<String, List<String>> originalDependencies,
    required Map<String, List<String>> graph,
    required int cyclesCount,
  }) {
    final totalPackages = graph.keys.length;
    var basePackages = 0;
    var intermediatePackages = 0;
    var highLevelPackages = 0;
    var maxDependencies = 0;
    String? packageWithMostDeps;

    for (final entry in originalDependencies.entries) {
      final depCount = entry.value.length;

      if (depCount == 0) {
        basePackages++;
      } else if (depCount <= 5) {
        intermediatePackages++;
      } else {
        highLevelPackages++;
      }

      if (depCount > maxDependencies) {
        maxDependencies = depCount;
        packageWithMostDeps = entry.key;
      }
    }

    return DependencyStats(
      totalPackages: totalPackages,
      basePackages: basePackages,
      intermediatePackages: intermediatePackages,
      highLevelPackages: highLevelPackages,
      maxDependencies: maxDependencies,
      packageWithMostDeps: packageWithMostDeps,
      cyclesDetected: cyclesCount,
    );
  }
}
