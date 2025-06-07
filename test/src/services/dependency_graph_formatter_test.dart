import 'package:mason_logger/mason_logger.dart';
import 'package:melos_dependency_graph/src/models/models.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_formatter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('DependencyGraphFormatter', () {
    late MockLogger mockLogger;
    late DependencyGraphFormatter formatter;

    setUp(() {
      mockLogger = MockLogger();
      formatter = DependencyGraphFormatter(logger: mockLogger);
    });

    group('showCycleWarnings', () {
      test('should return true when no cycles exist', () async {
        final result = await formatter.showCycleWarnings(
          [],
          simpleList: false,
        );

        expect(result, isTrue);
        verifyNever(() => mockLogger.warn(any()));
      });

      test('should return true for simple list mode regardless of cycles',
          () async {
        final cycles = [
          ['A', 'B', 'A']
        ];

        final result = await formatter.showCycleWarnings(
          cycles,
          simpleList: true,
        );

        expect(result, isTrue);
        verifyNever(() => mockLogger.warn(any()));
      });

      test(
          'should display cycle warnings when cycles exist and not simple list and user cancel',
          () async {
        final cycles = [
          ['A', 'B', 'A'],
          ['C', 'D', 'C']
        ];

        when(() => mockLogger.confirm(any())).thenReturn(false);

        when(() => mockLogger.warn(any())).thenReturn(null);
        when(() => mockLogger.info(any())).thenReturn(null);

        final result = await formatter.showCycleWarnings(
          cycles,
          simpleList: false,
        );

        expect(result, isFalse);

        verify(() =>
                mockLogger.warn('⚠️  WARNING: Cyclic dependencies detected!'))
            .called(1);
        verify(() => mockLogger.info('Cycle 1: A -> B -> A')).called(1);
        verify(() => mockLogger.info('Cycle 2: C -> D -> C')).called(1);
        verify(() => mockLogger.info('Operation cancelled.')).called(1);
        verify(() => mockLogger.confirm(any())).called(1);
      });

      test(
          'should return false and display warnings when cycles exist and not simple list and user confirms',
          () async {
        final cycles = [
          ['A', 'B', 'A'],
          ['C', 'D', 'C']
        ];

        when(() => mockLogger.confirm(any())).thenReturn(true);

        when(() => mockLogger.warn(any())).thenReturn(null);
        when(() => mockLogger.info(any())).thenReturn(null);

        final result = await formatter.showCycleWarnings(
          cycles,
          simpleList: false,
        );

        expect(result, isTrue);

        verify(() => mockLogger.info('Removing cyclic dependencies...\n',
            style: null)).called(1);
        verify(() => mockLogger.confirm(any())).called(1);
      });
    });

    group('displayResults', () {
      test('should display simple list when simpleList is true', () {
        final packages = ['A', 'B', 'C'];
        when(() => mockLogger.info(any())).thenReturn(null);

        formatter.displayResults(
          packages,
          simpleList: true,
        );

        verify(() => mockLogger.info('C')).called(1);
        verify(() => mockLogger.info('B')).called(1);
        verify(() => mockLogger.info('A')).called(1);
      });

      test('should display enhanced results when simpleList is false', () {
        final packages = ['A', 'B'];
        final dependencies = {
          'A': <String>[],
          'B': ['A'],
        };
        final stats = DependencyStats(
          totalPackages: 2,
          basePackages: 1,
          intermediatePackages: 1,
          highLevelPackages: 0,
          maxDependencies: 1,
          packageWithMostDeps: 'B',
          cyclesDetected: 0,
        );

        when(() => mockLogger.info(any())).thenReturn(null);

        formatter.displayResults(
          packages,
          simpleList: false,
          originalDependencies: dependencies,
          dataSource: const MelosSource(),
          stats: stats,
          processingTime: const Duration(milliseconds: 100),
        );

        verify(() => mockLogger.info('📦 MELOS DEPENDENCY ANALYSIS')).called(1);
        verify(() => mockLogger.info('├─ Source: melos list --graph'))
            .called(1);
        verify(() => mockLogger.info('├─ Processing: 100ms')).called(1);
        verify(() => mockLogger.info('└─ Total: 2 packages found\n')).called(1);
      });
    });

    group('helper methods', () {
      test('should return correct source description', () {
        when(() => mockLogger.info(any())).thenReturn(null);

        formatter.displayResults(
          ['A'],
          simpleList: false,
          dataSource: const MelosSource(),
        );

        verify(() => mockLogger.info('├─ Source: melos list --graph'))
            .called(1);

        formatter.displayResults(
          ['A'],
          simpleList: false,
          dataSource: const FileSource('/path/to/file.json'),
        );

        verify(() => mockLogger.info('├─ Source: file /path/to/file.json'))
            .called(1);
      });

      test('should return correct package icons based on dependency count', () {
        final packages = ['base', 'intermediate', 'complex'];
        final dependencies = {
          'base': <String>[],
          'intermediate': ['base'],
          'complex': ['base', 'intermediate', 'dep1', 'dep2', 'dep3', 'dep4'],
        };

        when(() => mockLogger.info(any())).thenReturn(null);

        formatter.displayResults(
          packages,
          simpleList: false,
          originalDependencies: dependencies,
        );

        verify(() => mockLogger.info(any(that: contains('🟢  3. base'))))
            .called(1);
        verify(() =>
                mockLogger.info(any(that: contains('🟡  2. intermediate'))))
            .called(1);
        verify(() => mockLogger.info(any(that: contains('🔴  1. complex'))))
            .called(1);
      });
    });

    group('_displayStatistics (tested via displayResults)', () {
      test('should display cycles detected message when cycles > 0', () {
        final packages = ['package1'];
        final dependencies = {'package1': <String>[]};
        final stats = DependencyStats(
          totalPackages: 5,
          basePackages: 3,
          intermediatePackages: 1,
          highLevelPackages: 1,
          maxDependencies: 6,
          packageWithMostDeps: 'complex_package',
          cyclesDetected: 2,
        );

        when(() => mockLogger.info(any())).thenReturn(null);

        formatter.displayResults(
          packages,
          simpleList: false,
          originalDependencies: dependencies,
          dataSource: const MelosSource(),
          stats: stats,
          processingTime: const Duration(milliseconds: 100),
        );

        verify(() => mockLogger.info(any(that: contains('📊 STATISTICS:'))))
            .called(1);
        verify(() => mockLogger.info(any(
                that: contains('├─ 🟢 Base packages (0 deps): 3 packages'))))
            .called(1);
        verify(() => mockLogger.info(any(
                that: contains(
                    '├─ 🟡 Intermediate packages (1-5 deps): 1 packages'))))
            .called(1);
        verify(() => mockLogger.info(any(
            that: contains(
                '└─ 🔴 High-level packages (6+ deps): 1 packages')))).called(1);
        verify(() => mockLogger.info(
                any(that: contains('   └─ ⚠️  2 cycles detected and removed'))))
            .called(1);
        verify(() => mockLogger.info('')).called(1);
      });

      test('should not display cycles detected message when cycles = 0', () {
        final packages = ['package1'];
        final dependencies = {'package1': <String>[]};
        final stats = DependencyStats(
          totalPackages: 3,
          basePackages: 2,
          intermediatePackages: 1,
          highLevelPackages: 0,
          maxDependencies: 2,
          packageWithMostDeps: 'medium_package',
          cyclesDetected: 0,
        );

        when(() => mockLogger.info(any())).thenReturn(null);

        formatter.displayResults(
          packages,
          simpleList: false,
          originalDependencies: dependencies,
          dataSource: const MelosSource(),
          stats: stats,
          processingTime: const Duration(milliseconds: 50),
        );

        verify(() => mockLogger.info(any(that: contains('📊 STATISTICS:'))))
            .called(1);
        verify(() => mockLogger.info(any(
                that: contains('├─ 🟢 Base packages (0 deps): 2 packages'))))
            .called(1);
        verify(() => mockLogger.info(any(
                that: contains(
                    '├─ 🟡 Intermediate packages (1-5 deps): 1 packages'))))
            .called(1);
        verify(() => mockLogger.info(any(
            that: contains(
                '└─ 🔴 High-level packages (6+ deps): 0 packages')))).called(1);
        verifyNever(() => mockLogger
            .info(any(that: contains('cycles detected and removed'))));
        verify(() => mockLogger.info('')).called(1);
      });
    });
  });
}
