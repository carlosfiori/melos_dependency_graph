import 'package:melos_dependency_graph/src/services/cycle_detector.dart';
import 'package:test/test.dart';

void main() {
  group('CycleDetector', () {
    late CycleDetector cycleDetector;

    setUp(() {
      cycleDetector = CycleDetector();
    });

    group('detectCycles', () {
      test('should return empty list when no cycles exist', () {
        final graph = {
          'A': ['B'],
          'B': ['C'],
          'C': <String>[],
        };
        final allNodes = {'A', 'B', 'C'};

        final cycles = cycleDetector.detectCycles(graph, allNodes);

        expect(cycles, isEmpty);
      });

      test('should detect simple cycle', () {
        final graph = {
          'A': ['B'],
          'B': ['A'],
        };
        final allNodes = {'A', 'B'};

        final cycles = cycleDetector.detectCycles(graph, allNodes);

        expect(cycles, hasLength(1));
        expect(cycles[0], contains('A'));
        expect(cycles[0], contains('B'));
      });

      test('should detect multiple cycles', () {
        final graph = {
          'A': ['B'],
          'B': ['A'],
          'C': ['D'],
          'D': ['C'],
        };
        final allNodes = {'A', 'B', 'C', 'D'};

        final cycles = cycleDetector.detectCycles(graph, allNodes);

        expect(cycles, hasLength(2));
      });

      test('should detect self-referencing cycle', () {
        final graph = {
          'A': ['A'],
        };
        final allNodes = {'A'};

        final cycles = cycleDetector.detectCycles(graph, allNodes);

        expect(cycles, hasLength(1));
        expect(cycles[0], equals(['A', 'A']));
      });

      test('should detect complex cycle', () {
        final graph = {
          'A': ['B'],
          'B': ['C'],
          'C': ['A'],
        };
        final allNodes = {'A', 'B', 'C'};

        final cycles = cycleDetector.detectCycles(graph, allNodes);

        expect(cycles, hasLength(1));
        expect(cycles[0], hasLength(4));
      });
    });

    group('removeCyclicDependencies', () {
      test('should remove cyclic dependencies and update inDegree', () {
        final graph = {
          'A': ['B'],
          'B': ['A'],
        };
        final inDegree = {'A': 1, 'B': 1};
        final cycles = [
          ['A', 'B', 'A']
        ];

        cycleDetector.removeCyclicDependencies(cycles, graph, inDegree);

        expect(graph['B'], isNot(contains('A')));
        expect(inDegree['A'], equals(0));
      });

      test('should handle multiple cycles removal', () {
        final graph = {
          'A': ['B'],
          'B': ['A'],
          'C': ['D'],
          'D': ['C'],
        };
        final inDegree = {'A': 1, 'B': 1, 'C': 1, 'D': 1};
        final cycles = [
          ['A', 'B', 'A'],
          ['C', 'D', 'C']
        ];

        cycleDetector.removeCyclicDependencies(cycles, graph, inDegree);

        expect(graph['B'], isNot(contains('A')));
        expect(graph['D'], isNot(contains('C')));
        expect(inDegree['A'], equals(0));
        expect(inDegree['C'], equals(0));
      });

      test('should handle cycles with length less than 2', () {
        final graph = {'A': <String>[]};
        final inDegree = {'A': 0};
        final cycles = [
          ['A']
        ];

        expect(
            () =>
                cycleDetector.removeCyclicDependencies(cycles, graph, inDegree),
            returnsNormally);
      });

      test('should not decrease inDegree below 0', () {
        final graph = {
          'A': ['B'],
          'B': <String>[],
        };
        final inDegree = {'A': 0, 'B': 0};
        final cycles = [
          ['A', 'B', 'A']
        ];

        cycleDetector.removeCyclicDependencies(cycles, graph, inDegree);

        expect(inDegree['A'], equals(0));
      });
    });
  });
}
