import 'package:melos_dependency_graph/src/models/dependency_stats.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyStats', () {
    group('constructor', () {
      test('should create instance with all parameters', () {
        const stats = DependencyStats(
          totalPackages: 10,
          basePackages: 3,
          intermediatePackages: 5,
          highLevelPackages: 2,
          maxDependencies: 8,
          packageWithMostDeps: 'complex_package',
          cyclesDetected: 1,
        );

        expect(stats.totalPackages, equals(10));
        expect(stats.basePackages, equals(3));
        expect(stats.intermediatePackages, equals(5));
        expect(stats.highLevelPackages, equals(2));
        expect(stats.maxDependencies, equals(8));
        expect(stats.packageWithMostDeps, equals('complex_package'));
        expect(stats.cyclesDetected, equals(1));
      });

      test('should create instance with null packageWithMostDeps', () {
        const stats = DependencyStats(
          totalPackages: 0,
          basePackages: 0,
          intermediatePackages: 0,
          highLevelPackages: 0,
          maxDependencies: 0,
          packageWithMostDeps: null,
          cyclesDetected: 0,
        );

        expect(stats.packageWithMostDeps, isNull);
      });
    });

    group('fromGraphData', () {
      test('should calculate stats correctly for simple graph', () {
        final originalDependencies = {
          'base1': <String>[],
          'base2': <String>[],
          'intermediate': ['base1'],
          'complex': ['base1', 'base2', 'intermediate'],
        };

        final graph = {
          'base1': <String>[],
          'base2': <String>[],
          'intermediate': ['base1'],
          'complex': ['base1', 'base2', 'intermediate'],
        };

        final stats = DependencyStats.fromGraphData(
          originalDependencies: originalDependencies,
          graph: graph,
          cyclesCount: 0,
        );

        expect(stats.totalPackages, equals(4));
        expect(stats.basePackages, equals(2));
        expect(stats.intermediatePackages, equals(2));
        expect(stats.highLevelPackages, equals(0));
        expect(stats.maxDependencies, equals(3));
        expect(stats.packageWithMostDeps, equals('complex'));
        expect(stats.cyclesDetected, equals(0));
      });

      test('should handle empty graph', () {
        final stats = DependencyStats.fromGraphData(
          originalDependencies: <String, List<String>>{},
          graph: <String, List<String>>{},
          cyclesCount: 0,
        );

        expect(stats.totalPackages, equals(0));
        expect(stats.basePackages, equals(0));
        expect(stats.intermediatePackages, equals(0));
        expect(stats.highLevelPackages, equals(0));
        expect(stats.maxDependencies, equals(0));
        expect(stats.packageWithMostDeps, isNull);
        expect(stats.cyclesDetected, equals(0));
      });

      test('should categorize packages correctly by dependency count', () {
        final originalDependencies = {
          'zero_deps': <String>[],
          'one_dep': ['zero_deps'],
          'five_deps': ['zero_deps', 'one_dep', 'dep1', 'dep2', 'dep3'],
          'six_deps': ['zero_deps', 'one_dep', 'dep1', 'dep2', 'dep3', 'dep4'],
        };

        final graph = Map<String, List<String>>.from(originalDependencies);

        final stats = DependencyStats.fromGraphData(
          originalDependencies: originalDependencies,
          graph: graph,
          cyclesCount: 2,
        );

        expect(stats.basePackages, equals(1));
        expect(stats.intermediatePackages, equals(2));
        expect(stats.highLevelPackages, equals(1));
        expect(stats.maxDependencies, equals(6));
        expect(stats.packageWithMostDeps, equals('six_deps'));
        expect(stats.cyclesDetected, equals(2));
      });

      test('should handle multiple packages with same max dependencies', () {
        final originalDependencies = {
          'package1': ['dep1', 'dep2'],
          'package2': ['dep3', 'dep4'],
        };

        final graph = Map<String, List<String>>.from(originalDependencies);

        final stats = DependencyStats.fromGraphData(
          originalDependencies: originalDependencies,
          graph: graph,
          cyclesCount: 0,
        );

        expect(stats.maxDependencies, equals(2));
        expect(['package1', 'package2'], contains(stats.packageWithMostDeps));
      });

      test('should handle packages not in original dependencies', () {
        final originalDependencies = {
          'A': ['B'],
        };

        final graph = {
          'A': ['B'],
          'B': <String>[],
        };

        final stats = DependencyStats.fromGraphData(
          originalDependencies: originalDependencies,
          graph: graph,
          cyclesCount: 0,
        );

        expect(stats.totalPackages, equals(2));
        expect(stats.basePackages, equals(0));
        expect(stats.intermediatePackages, equals(1));
        expect(stats.maxDependencies, equals(1));
        expect(stats.packageWithMostDeps, equals('A'));
      });
    });
  });
}
