import 'package:mason_logger/mason_logger.dart';
import 'package:melos_dependency_graph/src/models/models.dart';
import 'package:melos_dependency_graph/src/services/cycle_detector.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_formatter.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_loader.dart';
import 'package:melos_dependency_graph/src/services/topological_sorter.dart';

class DependencyGraphService {
  DependencyGraphService({
    required Logger logger,
    DependencyGraphFormatter? formatter,
    DependencyGraphLoader? loader,
    CycleDetector? cycleDetector,
    TopologicalSorter? topologicalSorter,
  })  : _formatter = formatter ?? DependencyGraphFormatter(logger: logger),
        _loader = loader ?? DependencyGraphLoader(),
        _cycleDetector = cycleDetector ?? CycleDetector(),
        _topologicalSorter = topologicalSorter ?? TopologicalSorter();

  final DependencyGraphFormatter _formatter;
  final DependencyGraphLoader _loader;
  final CycleDetector _cycleDetector;
  final TopologicalSorter _topologicalSorter;

  Future<void> processGraph({
    required bool simpleList,
    required DataSource dataSource,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dependencies =
          await _loader.loadDependencies(dataSource: dataSource);

      final graphData = _buildGraph(dependencies);

      final cycles = _cycleDetector.detectCycles(
        graphData.graph,
        graphData.allNodes,
      );

      if (cycles.isNotEmpty) {
        final shouldContinue = await _formatter.showCycleWarnings(
          cycles,
          simpleList: simpleList,
        );

        if (!shouldContinue) {
          throw const UserCancelledException(
            'User cancelled the operation due to cyclic dependencies.',
          );
        }

        _cycleDetector.removeCyclicDependencies(
          cycles,
          graphData.graph,
          graphData.inDegree,
        );
      }

      final sortedPackages = _topologicalSorter.sort(
        graphData.graph,
        graphData.inDegree,
      );

      stopwatch.stop();

      final stats = DependencyStats.fromGraphData(
        originalDependencies: dependencies,
        graph: graphData.graph,
        cyclesCount: cycles.length,
      );

      _formatter.displayResults(
        sortedPackages,
        simpleList: simpleList,
        originalDependencies: dependencies,
        dataSource: dataSource,
        stats: stats,
        processingTime: stopwatch.elapsed,
      );
    } on UserCancelledException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception('Error processing dependency graph: $e');
    }
  }

  GraphData _buildGraph(Map<String, List<String>> dependencies) {
    final graph = <String, List<String>>{};
    final inDegree = <String, int>{};
    final allNodes = <String>{};

    dependencies.forEach((package, deps) {
      allNodes.add(package);
      graph[package] = List<String>.from(deps);

      for (final dep in deps) {
        allNodes.add(dep);
      }
    });

    for (final node in allNodes) {
      if (!graph.containsKey(node)) {
        graph[node] = [];
      }
      inDegree[node] = 0;
    }

    graph.forEach((package, deps) {
      for (final dep in deps) {
        inDegree[dep] = (inDegree[dep] ?? 0) + 1;
      }
    });

    return GraphData(
      graph: graph,
      inDegree: inDegree,
      allNodes: allNodes,
    );
  }
}

class GraphData {
  const GraphData({
    required this.graph,
    required this.inDegree,
    required this.allNodes,
  });

  final Map<String, List<String>> graph;
  final Map<String, int> inDegree;
  final Set<String> allNodes;
}

class UserCancelledException implements Exception {
  const UserCancelledException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'User cancelled the operation.';
}
