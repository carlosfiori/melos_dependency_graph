import 'package:melos_dependency_graph/src/services/topological_sorter.dart';
import 'package:test/test.dart';

void main() {
  group('TopologicalSorter', () {
    late TopologicalSorter sorter;

    setUp(() {
      sorter = TopologicalSorter();
    });

    test('should sort simple linear dependency chain', () {
      final graph = {
        'a': ['b'],
        'b': ['c'],
        'c': <String>[],
      };
      final inDegree = {'a': 0, 'b': 1, 'c': 1};

      final result = sorter.sort(graph, inDegree);

      expect(result, equals(['a', 'b', 'c']));
    });

    test('should sort independent nodes', () {
      final graph = {
        'a': <String>[],
        'b': <String>[],
        'c': <String>[],
      };
      final inDegree = {'a': 0, 'b': 0, 'c': 0};

      final result = sorter.sort(graph, inDegree);

      expect(result, hasLength(3));
      expect(result, containsAll(['a', 'b', 'c']));
    });

    test('should sort diamond dependency structure', () {
      final graph = {
        'a': ['b', 'c'],
        'b': ['d'],
        'c': ['d'],
        'd': <String>[],
      };
      final inDegree = {'a': 0, 'b': 1, 'c': 1, 'd': 2};

      final result = sorter.sort(graph, inDegree);

      expect(result.first, equals('a'));
      expect(result.last, equals('d'));
      expect(result, hasLength(4));
    });

    test('should handle empty graph', () {
      final graph = <String, List<String>>{};
      final inDegree = <String, int>{};

      final result = sorter.sort(graph, inDegree);

      expect(result, isEmpty);
    });

    test('should handle single node with no dependencies', () {
      final graph = {'a': <String>[]};
      final inDegree = {'a': 0};

      final result = sorter.sort(graph, inDegree);

      expect(result, equals(['a']));
    });

    test('should sort complex dependency tree', () {
      final graph = {
        'root': ['a', 'b'],
        'a': ['c'],
        'b': ['c', 'd'],
        'c': ['e'],
        'd': ['e'],
        'e': <String>[],
      };
      final inDegree = {'root': 0, 'a': 1, 'b': 1, 'c': 2, 'd': 1, 'e': 2};

      final result = sorter.sort(graph, inDegree);

      expect(result.first, equals('root'));
      expect(result.last, equals('e'));
      expect(result, hasLength(6));
      expect(result.indexOf('a'), lessThan(result.indexOf('c')));
      expect(result.indexOf('b'), lessThan(result.indexOf('c')));
      expect(result.indexOf('b'), lessThan(result.indexOf('d')));
    });

    test('should handle multiple root nodes', () {
      final graph = {
        'root1': ['a'],
        'root2': ['b'],
        'a': ['c'],
        'b': ['c'],
        'c': <String>[],
      };
      final inDegree = {'root1': 0, 'root2': 0, 'a': 1, 'b': 1, 'c': 2};

      final result = sorter.sort(graph, inDegree);

      expect(result, hasLength(5));
      expect(result.last, equals('c'));
      expect(result.take(2), containsAll(['root1', 'root2']));
    });
  });
}
