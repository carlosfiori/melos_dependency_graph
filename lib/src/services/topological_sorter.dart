class TopologicalSorter {
  List<String> sort(
    Map<String, List<String>> graph,
    Map<String, int> inDegree,
  ) {
    final result = <String>[];
    final queue = <String>[];
    final tempInDegree = Map<String, int>.from(inDegree)
      ..forEach((node, degree) {
        if (degree == 0) {
          queue.add(node);
        }
      });

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      final deps = graph[current] ?? [];
      for (final dep in deps) {
        tempInDegree[dep] = tempInDegree[dep]! - 1;

        if (tempInDegree[dep] == 0) {
          queue.add(dep);
        }
      }
    }

    return result;
  }
}
