import 'dart:convert';
import 'dart:io';

import 'package:melos_dependency_graph/src/services/strategies/file_loading_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('FileLoadingStrategy', () {
    group('constructor', () {
      test('should create instance with correct file path', () {
        // Arrange
        const filePath = '/path/to/file.json';

        // Act
        final strategy = FileLoadingStrategy(filePath);

        // Assert
        expect(strategy, isA<FileLoadingStrategy>());
        expect(strategy.filePath, equals(filePath));
      });
    });
  });

  group('FileLoadingStrategy loadDependencies', () {
    late FileLoadingStrategy strategy;
    late Directory tempDir;

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('loadDependencies', () {
      test('should load dependencies from valid JSON file', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/valid_deps.json');
        final testData = <String, List<String>>{
          'package_a': ['package_b', 'package_c'],
          'package_b': ['package_d'],
          'package_c': <String>[],
          'package_d': <String>[],
        };
        await testFile.writeAsString(json.encode(testData));
        strategy = FileLoadingStrategy(testFile.path);

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
      });

      test('should handle empty JSON file', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/empty.json');
        await testFile.writeAsString('{}');
        strategy = FileLoadingStrategy(testFile.path);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result, isEmpty);
      });

      test('should convert null values to empty lists', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/null_values.json');
        final jsonWithNulls = {
          'package_a': ['package_b'],
          'package_b': null,
          'package_c': ['package_d'],
          'package_d': null,
        };
        await testFile.writeAsString(json.encode(jsonWithNulls));
        strategy = FileLoadingStrategy(testFile.path);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result['package_a'], equals(['package_b']));
        expect(result['package_b'], equals(<String>[]));
        expect(result['package_c'], equals(['package_d']));
        expect(result['package_d'], equals(<String>[]));
      });

      test('should convert non-list values to empty lists', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/mixed_types.json');
        final jsonWithMixedTypes = {
          'package_a': ['package_b'],
          'package_b': 'not_a_list',
          'package_c': 123,
          'package_d': {'key': 'value'},
          'package_e': true,
        };
        await testFile.writeAsString(json.encode(jsonWithMixedTypes));
        strategy = FileLoadingStrategy(testFile.path);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result['package_a'], equals(['package_b']));
        expect(result['package_b'], equals(<String>[]));
        expect(result['package_c'], equals(<String>[]));
        expect(result['package_d'], equals(<String>[]));
        expect(result['package_e'], equals(<String>[]));
      });

      test('should handle complex dependency structures', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/complex_deps.json');
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
        await testFile.writeAsString(json.encode(complexData));
        strategy = FileLoadingStrategy(testFile.path);

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
      });

      test('should throw exception when list contains non-string values',
          () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/mixed_list_types.json');
        final jsonWithMixedListTypes = {
          'package_a': ['string_dep', 123, true],
          'package_b': ['valid_dep'],
        };
        await testFile.writeAsString(json.encode(jsonWithMixedListTypes));
        strategy = FileLoadingStrategy(testFile.path);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should throw exception when file does not exist', () async {
        // Arrange
        const nonExistentPath = '/path/that/definitely/does/not/exist.json';
        strategy = FileLoadingStrategy(nonExistentPath);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Arquivo não encontrado: $nonExistentPath'),
          )),
        );
      });

      test('should throw exception when file contains invalid JSON', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/invalid.json');
        await testFile.writeAsString('{ this is not valid json }');
        strategy = FileLoadingStrategy(testFile.path);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw exception when JSON is not a map', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/array.json');
        await testFile.writeAsString('["this", "is", "an", "array"]');
        strategy = FileLoadingStrategy(testFile.path);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle empty file', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/empty_file.json');
        await testFile.writeAsString('');
        strategy = FileLoadingStrategy(testFile.path);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle file with only whitespace', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/whitespace.json');
        await testFile.writeAsString('   \n\t  \r\n  ');
        strategy = FileLoadingStrategy(testFile.path);

        // Act & Assert
        expect(
          () => strategy.loadDependencies(),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('integration tests', () {
      test('should work with realistic package dependency file', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('file_strategy_test_');
        final testFile = File('${tempDir.path}/realistic_deps.json');
        final realisticData = <String, List<String>>{
          'my_app': ['flutter', 'provider', 'http'],
          'flutter': <String>[],
          'provider': ['flutter'],
          'http': ['flutter'],
          'test_package': ['flutter', 'mockito'],
          'mockito': ['flutter'],
        };
        await testFile.writeAsString(json.encode(realisticData));
        strategy = FileLoadingStrategy(testFile.path);

        // Act
        final result = await strategy.loadDependencies();

        // Assert
        expect(result, equals(realisticData));

        // Verify app has its dependencies
        expect(result['my_app'], containsAll(['flutter', 'provider', 'http']));

        // Verify flutter is a leaf dependency
        expect(result['flutter'], isEmpty);

        // Verify provider depends on flutter
        expect(result['provider'], contains('flutter'));

        // Verify test dependencies
        expect(result['test_package'], containsAll(['flutter', 'mockito']));
      });
    });
  });
}
