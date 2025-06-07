import 'package:mason_logger/mason_logger.dart';
import 'package:melos_dependency_graph/src/models/models.dart';
import 'package:melos_dependency_graph/src/services/cycle_detector.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_formatter.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_loader.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_service.dart';
import 'package:melos_dependency_graph/src/services/topological_sorter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockDependencyGraphFormatter extends Mock
    implements DependencyGraphFormatter {}

class _MockDependencyGraphLoader extends Mock
    implements DependencyGraphLoader {}

class _MockCycleDetector extends Mock implements CycleDetector {}

class _MockTopologicalSorter extends Mock implements TopologicalSorter {}

void main() {
  group('DependencyGraphService', () {
    late Logger mockLogger;

    setUp(() {
      mockLogger = _MockLogger();
    });

    group('constructor', () {
      test('should create instance with required dependencies', () {
        final service = DependencyGraphService(logger: mockLogger);
        expect(service, isA<DependencyGraphService>());
      });
    });

    group('processGraph', () {
      late _MockDependencyGraphFormatter mockFormatter;
      late _MockDependencyGraphLoader mockLoader;
      late _MockCycleDetector mockCycleDetector;
      late _MockTopologicalSorter mockTopologicalSorter;
      late DependencyGraphService service;

      setUp(() {
        mockFormatter = _MockDependencyGraphFormatter();
        mockLoader = _MockDependencyGraphLoader();
        mockCycleDetector = _MockCycleDetector();
        mockTopologicalSorter = _MockTopologicalSorter();

        // Create service with mocked dependencies
        service = DependencyGraphService(
          logger: mockLogger,
          formatter: mockFormatter,
          loader: mockLoader,
          cycleDetector: mockCycleDetector,
          topologicalSorter: mockTopologicalSorter,
        );
      });

      test('should process graph successfully with no cycles', () async {
        // Arrange
        const dataSource = MelosSource();
        const simpleList = false;
        final dependencies = {
          'A': <String>[],
          'B': ['A'],
          'C': ['A', 'B'],
        };
        final sortedPackages = ['A', 'B', 'C'];

        when(() => mockLoader.loadDependencies(dataSource: dataSource))
            .thenAnswer((_) async => dependencies);

        when(() => mockCycleDetector.detectCycles(any(), any()))
            .thenReturn(<List<String>>[]);

        when(() => mockTopologicalSorter.sort(any(), any()))
            .thenReturn(sortedPackages);

        when(() => mockFormatter.displayResults(
              any(),
              simpleList: any(named: 'simpleList'),
              originalDependencies: any(named: 'originalDependencies'),
              dataSource: any(named: 'dataSource'),
              stats: any(named: 'stats'),
              processingTime: any(named: 'processingTime'),
            )).thenReturn(null);

        // Act
        await service.processGraph(
          simpleList: simpleList,
          dataSource: dataSource,
        );

        // Assert
        verify(() => mockLoader.loadDependencies(dataSource: dataSource))
            .called(1);
        verify(() => mockCycleDetector.detectCycles(any(), any())).called(1);
        verify(() => mockTopologicalSorter.sort(any(), any())).called(1);
        verify(() => mockFormatter.displayResults(
              sortedPackages,
              simpleList: simpleList,
              originalDependencies: dependencies,
              dataSource: dataSource,
              stats: any(named: 'stats'),
              processingTime: any(named: 'processingTime'),
            )).called(1);
      });

      test('should handle cycles and continue when user confirms', () async {
        // Arrange
        const dataSource = FileSource('test.json');
        const simpleList = true;
        final dependencies = {
          'A': ['B'],
          'B': ['A'],
        };
        final cycles = [
          ['A', 'B']
        ];
        final sortedPackages = ['A', 'B'];

        when(() => mockLoader.loadDependencies(dataSource: dataSource))
            .thenAnswer((_) async => dependencies);

        when(() => mockCycleDetector.detectCycles(any(), any()))
            .thenReturn(cycles);

        when(() => mockFormatter.showCycleWarnings(
              cycles,
              simpleList: simpleList,
            )).thenAnswer((_) async => true);

        when(() => mockCycleDetector.removeCyclicDependencies(
              cycles,
              any(),
              any(),
            )).thenReturn(null);

        when(() => mockTopologicalSorter.sort(any(), any()))
            .thenReturn(sortedPackages);

        when(() => mockFormatter.displayResults(
              any(),
              simpleList: any(named: 'simpleList'),
              originalDependencies: any(named: 'originalDependencies'),
              dataSource: any(named: 'dataSource'),
              stats: any(named: 'stats'),
              processingTime: any(named: 'processingTime'),
            )).thenReturn(null);

        // Act
        await service.processGraph(
          simpleList: simpleList,
          dataSource: dataSource,
        );

        // Assert
        verify(() => mockLoader.loadDependencies(dataSource: dataSource))
            .called(1);
        verify(() => mockCycleDetector.detectCycles(any(), any())).called(1);
        verify(() =>
                mockFormatter.showCycleWarnings(cycles, simpleList: simpleList))
            .called(1);
        verify(() => mockCycleDetector.removeCyclicDependencies(
              cycles,
              any(),
              any(),
            )).called(1);
        verify(() => mockTopologicalSorter.sort(any(), any())).called(1);
        verify(() => mockFormatter.displayResults(
              sortedPackages,
              simpleList: simpleList,
              originalDependencies: dependencies,
              dataSource: dataSource,
              stats: any(named: 'stats'),
              processingTime: any(named: 'processingTime'),
            )).called(1);
      });

      test('should exit when user declines to continue with cycles', () async {
        // Arrange
        const dataSource = MelosSource();
        const simpleList = false;
        final dependencies = {
          'A': ['B'],
          'B': ['A'],
        };
        final cycles = [
          ['A', 'B']
        ];

        when(() => mockLoader.loadDependencies(dataSource: dataSource))
            .thenAnswer((_) async => dependencies);

        when(() => mockCycleDetector.detectCycles(any(), any()))
            .thenReturn(cycles);

        when(() => mockFormatter.showCycleWarnings(
              cycles,
              simpleList: simpleList,
            )).thenAnswer((_) async => false);

        // Act & Assert
        await expectLater(
          () => service.processGraph(
            simpleList: simpleList,
            dataSource: dataSource,
          ),
          throwsA(isA<UserCancelledException>()),
        );

        verify(() => mockLoader.loadDependencies(dataSource: dataSource))
            .called(1);
        verify(() => mockCycleDetector.detectCycles(any(), any())).called(1);
        verify(() =>
                mockFormatter.showCycleWarnings(cycles, simpleList: simpleList))
            .called(1);
        verifyNever(() => mockCycleDetector.removeCyclicDependencies(
              any(),
              any(),
              any(),
            ));
        verifyNever(() => mockTopologicalSorter.sort(any(), any()));
      });

      test('should throw exception when loader fails', () async {
        // Arrange
        const dataSource = FileSource('nonexistent.json');
        const simpleList = false;

        when(() => mockLoader.loadDependencies(dataSource: dataSource))
            .thenThrow(Exception('File not found'));

        // Act & Assert
        expect(
          () => service.processGraph(
            simpleList: simpleList,
            dataSource: dataSource,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Error processing dependency graph'),
            ),
          ),
        );

        verify(() => mockLoader.loadDependencies(dataSource: dataSource))
            .called(1);
        verifyNever(() => mockCycleDetector.detectCycles(any(), any()));
      });

      test('should pass correct parameters to displayResults', () async {
        // Arrange
        const dataSource = MelosSource();
        const simpleList = true;
        final dependencies = {
          'package1': <String>[],
          'package2': ['package1'],
        };
        final sortedPackages = ['package1', 'package2'];

        when(() => mockLoader.loadDependencies(dataSource: dataSource))
            .thenAnswer((_) async => dependencies);

        when(() => mockCycleDetector.detectCycles(any(), any()))
            .thenReturn(<List<String>>[]);

        when(() => mockTopologicalSorter.sort(any(), any()))
            .thenReturn(sortedPackages);

        when(() => mockFormatter.displayResults(
              any(),
              simpleList: any(named: 'simpleList'),
              originalDependencies: any(named: 'originalDependencies'),
              dataSource: any(named: 'dataSource'),
              stats: any(named: 'stats'),
              processingTime: any(named: 'processingTime'),
            )).thenReturn(null);

        // Act
        await service.processGraph(
          simpleList: simpleList,
          dataSource: dataSource,
        );

        // Assert
        final captured = verify(() => mockFormatter.displayResults(
              captureAny(),
              simpleList: captureAny(named: 'simpleList'),
              originalDependencies: captureAny(named: 'originalDependencies'),
              dataSource: captureAny(named: 'dataSource'),
              stats: captureAny(named: 'stats'),
              processingTime: captureAny(named: 'processingTime'),
            )).captured;

        expect(captured[0], equals(sortedPackages));
        expect(captured[1], equals(simpleList));
        expect(captured[2], equals(dependencies));
        expect(captured[3], equals(dataSource));
        expect(captured[4], isA<DependencyStats>());
        expect(captured[5], isA<Duration>());
      });
    });

    group('GraphData', () {
      test('should create instance with all required fields', () {
        final graph = {
          'A': ['B'],
          'B': <String>[]
        };
        final inDegree = {'A': 0, 'B': 1};
        final allNodes = {'A', 'B'};

        final graphData = GraphData(
          graph: graph,
          inDegree: inDegree,
          allNodes: allNodes,
        );

        expect(graphData.graph, equals(graph));
        expect(graphData.inDegree, equals(inDegree));
        expect(graphData.allNodes, equals(allNodes));
      });
    });

    group('_buildGraph (tested indirectly)', () {
      test('should build correct graph structure through processGraph',
          () async {
        // This test verifies the _buildGraph method indirectly by checking
        // the parameters passed to other methods
        final mockFormatter = _MockDependencyGraphFormatter();
        final mockLoader = _MockDependencyGraphLoader();
        final mockCycleDetector = _MockCycleDetector();
        final mockTopologicalSorter = _MockTopologicalSorter();

        final service = DependencyGraphService(
          logger: mockLogger,
          formatter: mockFormatter,
          loader: mockLoader,
          cycleDetector: mockCycleDetector,
          topologicalSorter: mockTopologicalSorter,
        );

        const dataSource = MelosSource();
        final dependencies = {
          'A': <String>[],
          'B': ['A'],
          'C': ['A', 'external'],
        };

        when(() => mockLoader.loadDependencies(dataSource: dataSource))
            .thenAnswer((_) async => dependencies);

        when(() => mockCycleDetector.detectCycles(any(), any()))
            .thenReturn(<List<String>>[]);

        when(() => mockTopologicalSorter.sort(any(), any()))
            .thenReturn(['external', 'A', 'B', 'C']);

        when(() => mockFormatter.displayResults(
              any(),
              simpleList: any(named: 'simpleList'),
              originalDependencies: any(named: 'originalDependencies'),
              dataSource: any(named: 'dataSource'),
              stats: any(named: 'stats'),
              processingTime: any(named: 'processingTime'),
            )).thenReturn(null);

        await service.processGraph(
          simpleList: false,
          dataSource: dataSource,
        );

        // Verify that detectCycles was called with the expected graph structure
        final capturedDetectCycles =
            verify(() => mockCycleDetector.detectCycles(
                  captureAny(),
                  captureAny(),
                )).captured;

        final graph = capturedDetectCycles[0] as Map<String, List<String>>;
        final allNodes = capturedDetectCycles[1] as Set<String>;

        // Verify graph structure
        expect(graph.keys, containsAll(['A', 'B', 'C', 'external']));
        expect(graph['A'], equals(<String>[]));
        expect(graph['B'], equals(['A']));
        expect(graph['C'], equals(['A', 'external']));
        expect(graph['external'],
            equals(<String>[])); // Added for missing dependency

        // Verify all nodes are captured
        expect(allNodes, containsAll(['A', 'B', 'C', 'external']));

        // Verify sort was called with the expected graph and inDegree
        final capturedSort = verify(() => mockTopologicalSorter.sort(
              captureAny(),
              captureAny(),
            )).captured;

        final sortGraph = capturedSort[0] as Map<String, List<String>>;
        final inDegree = capturedSort[1] as Map<String, int>;

        expect(sortGraph, equals(graph));
        expect(inDegree['A'], equals(2)); // Referenced by B and C
        expect(inDegree['B'], equals(0)); // Not referenced by anyone
        expect(inDegree['C'], equals(0)); // Not referenced by anyone
        expect(inDegree['external'], equals(1)); // Referenced by C
      });
    });
  });

  group('UserCancelledException', () {
    test('should return default message when no message is provided', () {
      const exception = UserCancelledException();

      expect(exception.toString(), equals('User cancelled the operation.'));
    });

    test('should return custom message when message is provided', () {
      const exception = UserCancelledException('Custom cancellation message');

      expect(exception.toString(), equals('Custom cancellation message'));
    });

    test('should return default message when null message is provided', () {
      const exception = UserCancelledException(null);

      expect(exception.toString(), equals('User cancelled the operation.'));
    });
  });
}
