class CycleDetector {
  List<List<String>> detectCycles(
    Map<String, List<String>> graph,
    Set<String> allNodes,
  ) {
    final visited = <String>{};
    final recursionStack = <String>{};
    final cycles = <List<String>>[];
    final currentPath = <String>[];

    void dfs(String node) {
      visited.add(node);
      recursionStack.add(node);
      currentPath.add(node);

      final dependencies = graph[node] ?? [];
      for (final dep in dependencies) {
        if (!visited.contains(dep)) {
          dfs(dep);
        } else if (recursionStack.contains(dep)) {
          final cycleStart = currentPath.indexOf(dep);
          final cycle = currentPath.sublist(cycleStart)..add(dep);
          cycles.add(cycle);
        }
      }

      recursionStack.remove(node);
      currentPath.removeLast();
    }

    for (final node in allNodes) {
      if (!visited.contains(node)) {
        dfs(node);
      }
    }

    return cycles;
  }

  void removeCyclicDependencies(
    List<List<String>> cycles,
    Map<String, List<String>> graph,
    Map<String, int> inDegree,
  ) {
    for (final cycle in cycles) {
      if (cycle.length >= 2) {
        final from = cycle[cycle.length - 2];
        final to = cycle[cycle.length - 1];

        graph[from]?.remove(to);
        if (inDegree[to]! > 0) {
          inDegree[to] = inDegree[to]! - 1;
        }
      }
    }
  }
}
