import 'dart:convert';
import 'dart:io';

import 'package:melos_dependency_graph/src/models/models.dart';
import 'package:melos_dependency_graph/src/services/dependency_graph_loader.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyGraphLoader', () {
    late DependencyGraphLoader loader;
    late Directory tempDir;

    setUp(() {
      loader = DependencyGraphLoader();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('loadDependencies', () {
      group('with FileSource', () {
        test('should load dependencies from valid JSON file', () async {
          // Arrange
          tempDir = await Directory.systemTemp.createTemp('test_');
          final testFile = File('${tempDir.path}/deps.json');
          final testData = <String, List<String>>{
            'package_a': ['package_b', 'package_c'],
            'package_b': ['package_c'],
            'package_c': <String>[],
          };
          await testFile.writeAsString(json.encode(testData));

          final fileSource = FileSource(testFile.path);

          // Act
          final result = await loader.loadDependencies(dataSource: fileSource);

          // Assert
          expect(result, equals(testData));
        });

        test('should handle empty JSON file', () async {
          // Arrange
          tempDir = await Directory.systemTemp.createTemp('test_');
          final testFile = File('${tempDir.path}/empty.json');
          await testFile.writeAsString('{}');

          final fileSource = FileSource(testFile.path);

          // Act
          final result = await loader.loadDependencies(dataSource: fileSource);

          // Assert
          expect(result, isEmpty);
        });

        test('should handle file with null values', () async {
          // Arrange
          tempDir = await Directory.systemTemp.createTemp('test_');
          final testFile = File('${tempDir.path}/null_deps.json');
          final testData = {
            'package_a': ['package_b'],
            'package_b': null,
            'package_c': ['package_d'],
          };
          await testFile.writeAsString(json.encode(testData));

          final fileSource = FileSource(testFile.path);

          // Act
          final result = await loader.loadDependencies(dataSource: fileSource);

          // Assert
          expect(result['package_a'], equals(['package_b']));
          expect(result['package_b'], equals(<String>[]));
          expect(result['package_c'], equals(['package_d']));
        });

        test('should throw exception when file does not exist', () async {
          // Arrange
          final fileSource = FileSource('/path/that/does/not/exist.json');

          // Act & Assert
          expect(
            () => loader.loadDependencies(dataSource: fileSource),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Arquivo não encontrado'),
            )),
          );
        });

        test('should throw exception when file contains invalid JSON',
            () async {
          // Arrange
          tempDir = await Directory.systemTemp.createTemp('test_');
          final testFile = File('${tempDir.path}/invalid.json');
          await testFile.writeAsString('{ invalid json }');

          final fileSource = FileSource(testFile.path);

          // Act & Assert
          expect(
            () => loader.loadDependencies(dataSource: fileSource),
            throwsA(isA<FormatException>()),
          );
        });
      });

      group('with MelosSource', () {
        test('should throw exception when melos command fails', () async {
          // Arrange
          const melosSource = MelosSource();

          // Act & Assert
          // Nota: Este teste vai falhar se melos estiver instalado e funcionando
          // Em um ambiente de CI/CD, você pode mockar o Process.run
          expect(
            () => loader.loadDependencies(dataSource: melosSource),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Error executing melos list --graph'),
            )),
          );
        });
      });

      group('with unsupported DataSource', () {
        test('should throw ArgumentError for unsupported data source',
            () async {
          // Arrange
          final unsupportedSource = _UnsupportedDataSource();

          // Act & Assert
          expect(
            () => loader.loadDependencies(dataSource: unsupportedSource),
            throwsA(isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('Fonte não suportada'),
            )),
          );
        });
      });
    });

    group('integration tests', () {
      test('should work end-to-end with real file', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('test_');
        final realDepsFile = File('${tempDir.path}/real_deps.json');
        final realData = <String, List<String>>{
          'frontend': ['shared_utils', 'api_client'],
          'backend': ['database', 'shared_utils'],
          'shared_utils': <String>[],
          'api_client': ['shared_utils'],
          'database': <String>[],
        };
        await realDepsFile.writeAsString(json.encode(realData));

        final fileSource = FileSource(realDepsFile.path);

        // Act
        final result = await loader.loadDependencies(dataSource: fileSource);

        // Assert
        expect(result, isA<Map<String, List<String>>>());
        expect(result.keys, hasLength(5));
        expect(result['frontend'], contains('shared_utils'));
        expect(result['frontend'], contains('api_client'));
        expect(result['shared_utils'], isEmpty);
        expect(result['api_client'], contains('shared_utils'));
      });

      test('should handle complex dependency structures', () async {
        // Arrange
        tempDir = await Directory.systemTemp.createTemp('test_');
        final complexFile = File('${tempDir.path}/complex_deps.json');
        final complexData = <String, List<String>>{
          'app': ['core', 'ui', 'network'],
          'core': ['utils'],
          'ui': ['core', 'theme'],
          'network': ['core', 'http_client'],
          'utils': <String>[],
          'theme': ['utils'],
          'http_client': ['utils'],
        };
        await complexFile.writeAsString(json.encode(complexData));

        final fileSource = FileSource(complexFile.path);

        // Act
        final result = await loader.loadDependencies(dataSource: fileSource);

        // Assert
        expect(result, equals(complexData));
        expect(result.keys, hasLength(7));

        // Verify specific relationships
        expect(result['app'], containsAll(['core', 'ui', 'network']));
        expect(result['ui'], containsAll(['core', 'theme']));
        expect(result['utils'], isEmpty);
      });
    });
  });
}

// Helper class for testing unsupported data sources
class _UnsupportedDataSource extends DataSource {
  const _UnsupportedDataSource();
}
