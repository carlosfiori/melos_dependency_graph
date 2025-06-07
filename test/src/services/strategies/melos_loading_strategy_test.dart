import 'dart:convert';
import 'dart:io';

import 'package:melos_dependency_graph/src/services/process_runner.dart';
import 'package:melos_dependency_graph/src/services/strategies/melos_loading_strategy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockProcessRunner extends Mock implements ProcessRunner {}

void main() {
  group('MelosLoadingStrategy', () {
    late MelosLoadingStrategy strategy;
    late _MockProcessRunner mockProcessRunner;

    setUp(() {
      mockProcessRunner = _MockProcessRunner();
      strategy = MelosLoadingStrategy(processRunner: mockProcessRunner);
    });

    group('constructor', () {
      test(
          'should create instance with default ProcessRunner when none provided',
          () {
        // Act
        final defaultStrategy = MelosLoadingStrategy();

        // Assert
        expect(defaultStrategy, isA<MelosLoadingStrategy>());
      });

      test('should create instance with provided ProcessRunner', () {
        // Arrange
        final customProcessRunner = _MockProcessRunner();

        // Act
        final customStrategy =
            MelosLoadingStrategy(processRunner: customProcessRunner);

        // Assert
        expect(customStrategy, isA<MelosLoadingStrategy>());
      });
    });

    group('loadDependencies', () {
      test('should load dependencies from valid melos output', () async {
        // Arrange
        final testData = <String, List<String>>{
          'package_a': ['package_b', 'package_c'],
          'package_b': ['package_d'],
          'package_c': <String>[],
          'package_d': <String>[],
        };
        final mockResult = ProcessResult(0, 0, json.encode(testData), '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result, equals(testData));
        expect(result.keys, hasLength(4));
        expect(result['package_a'], equals(['package_b', 'package_c']));
        expect(result['package_b'], equals(['package_d']));
        expect(result['package_c'], isEmpty);
        expect(result['package_d'], isEmpty);

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should handle empty dependencies from melos', () async {
        // Arrange
        final mockResult = ProcessResult(0, 0, '{}', '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result, isEmpty);

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should convert null values to empty lists', () async {
        // Arrange
        final jsonWithNulls = {
          'package_a': ['package_b'],
          'package_b': null,
          'package_c': ['package_d'],
          'package_d': null,
        };
        final mockResult = ProcessResult(0, 0, json.encode(jsonWithNulls), '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result['package_a'], equals(['package_b']));
        expect(result['package_b'], equals(<String>[]));
        expect(result['package_c'], equals(['package_d']));
        expect(result['package_d'], equals(<String>[]));

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should convert non-list values to empty lists', () async {
        // Arrange
        final jsonWithMixedTypes = {
          'package_a': ['package_b'],
          'package_b': 'not_a_list',
          'package_c': 123,
          'package_d': {'key': 'value'},
          'package_e': true,
        };
        final mockResult =
            ProcessResult(0, 0, json.encode(jsonWithMixedTypes), '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result['package_a'], equals(['package_b']));
        expect(result['package_b'], equals(<String>[]));
        expect(result['package_c'], equals(<String>[]));
        expect(result['package_d'], equals(<String>[]));
        expect(result['package_e'], equals(<String>[]));

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should handle complex dependency structures', () async {
        // Arrange
        final complexData = <String, List<String>>{
          'frontend': ['shared_utils', 'ui_components', 'api_client'],
          'backend': ['database', 'shared_utils', 'auth_service'],
          'mobile_app': ['shared_utils', 'ui_components'],
          'shared_utils': <String>[],
          'ui_components': ['shared_utils'],
          'api_client': ['shared_utils', 'auth_service'],
          'database': <String>[],
          'auth_service': ['database', 'shared_utils'],
        };
        final mockResult = ProcessResult(0, 0, json.encode(complexData), '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, equals(complexData));
        expect(result.keys, hasLength(8));

        // Verify specific relationships
        expect(result['frontend'],
            containsAll(['shared_utils', 'ui_components', 'api_client']));
        expect(result['backend'],
            containsAll(['database', 'shared_utils', 'auth_service']));
        expect(result['shared_utils'], isEmpty);
        expect(
            result['auth_service'], containsAll(['database', 'shared_utils']));

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should throw exception when melos command fails', () async {
        // Arrange
        final mockResult = ProcessResult(0, 1, '', 'melos: command not found');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
                'Error executing melos list --graph: melos: command not found'),
          )),
        );

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should throw exception when melos returns invalid JSON', () async {
        // Arrange
        final mockResult = ProcessResult(0, 0, '{ invalid json }', '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<FormatException>()),
        );

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should throw exception when JSON is not a map', () async {
        // Arrange
        final mockResult =
            ProcessResult(0, 0, '["this", "is", "an", "array"]', '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<TypeError>()),
        );

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should throw exception when stdout is empty', () async {
        // Arrange
        final mockResult = ProcessResult(0, 0, '', '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<FormatException>()),
        );

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });

      test('should handle different exit codes with specific errors', () async {
        // Arrange
        final mockResult =
            ProcessResult(0, 127, '', 'bash: melos: command not found');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf([
              contains('Error executing melos list --graph'),
              contains('bash: melos: command not found'),
            ]),
          )),
        );

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });
    });

    group('integration with real dependencies', () {
      test('should work with realistic melos output structure', () async {
        // Arrange
        final realisticMelosOutput = <String, List<String>>{
          'my_app': ['flutter', 'provider', 'http'],
          'shared_lib': ['flutter'],
          'utils': <String>[],
          'flutter': <String>[],
          'provider': ['flutter'],
          'http': ['flutter'],
        };
        final mockResult =
            ProcessResult(0, 0, json.encode(realisticMelosOutput), '');

        when(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .thenAnswer((_) async => mockResult);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, equals(realisticMelosOutput));

        // Verify app dependencies
        expect(result['my_app'], containsAll(['flutter', 'provider', 'http']));

        // Verify flutter is a leaf dependency
        expect(result['flutter'], isEmpty);
        expect(result['utils'], isEmpty);

        // Verify dependencies chain
        expect(result['provider'], contains('flutter'));
        expect(result['http'], contains('flutter'));

        verify(() => mockProcessRunner.run('melos', ['list', '--graph']))
            .called(1);
      });
    });
  });
}
