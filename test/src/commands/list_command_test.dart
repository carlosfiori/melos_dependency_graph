import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:melos_dependency_graph/src/commands/list_command.dart';
import 'package:melos_dependency_graph/src/services/services.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockDependencyGraphService extends Mock
    implements DependencyGraphService {}

class FakeDataSource extends Fake implements DataSource {}

// Custom test command runner that allows injecting mocked service
class TestCommandRunner extends CommandRunner<int> {
  TestCommandRunner({
    required Logger logger,
    required DependencyGraphService service,
  }) : super('test', 'test runner') {
    addCommand(ListCommand(logger: logger, service: service));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDataSource());
  });

  group('ListCommand', () {
    late Logger logger;
    late DependencyGraphService service;
    late TestCommandRunner commandRunner;
    late ListCommand command;

    setUp(() {
      logger = MockLogger();
      service = MockDependencyGraphService();
      commandRunner = TestCommandRunner(logger: logger, service: service);
      command = ListCommand(logger: logger, service: service);

      when(() => service.processGraph(
            simpleList: any(named: 'simpleList'),
            dataSource: any(named: 'dataSource'),
          )).thenAnswer((_) async {});
    });

    group('constructor', () {
      test('should initialize with required dependencies', () {
        expect(command, isA<ListCommand>());
        expect(command.name, equals('list'));
        expect(command.description,
            equals('List dependencies in topological order'));
      });

      test('should configure argParser with correct options', () {
        final argParser = command.argParser;

        // Check flags
        expect(argParser.options.containsKey('simple'), isTrue);
        expect(argParser.options['simple']!.abbr, equals('s'));
        expect(argParser.options['simple']!.negatable, isFalse);
        expect(argParser.options['simple']!.help,
            equals('Display a simple list of packages'));

        // Check source option
        expect(argParser.options.containsKey('source'), isTrue);
        expect(argParser.options['source']!.allowed, equals(['file', 'melos']));
        expect(argParser.options['source']!.defaultsTo, equals('melos'));
        expect(argParser.options['source']!.help,
            equals('Dependency data source'));

        // Check file-path option
        expect(argParser.options.containsKey('file-path'), isTrue);
        expect(argParser.options['file-path']!.help,
            equals('Path to JSON file (required when --source=file)'));
      });
    });

    group('run', () {
      group('with default arguments', () {
        test('should run successfully with melos source and no simple flag',
            () async {
          final result = await commandRunner.run(['list']);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: false,
                dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
              )).called(1);
        });
      });

      group('with simple flag', () {
        test('should pass simpleList=true to service when --simple is provided',
            () async {
          final result = await commandRunner.run(['list', '--simple']);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: true,
                dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
              )).called(1);
        });

        test('should pass simpleList=true to service when -s is provided',
            () async {
          final result = await commandRunner.run(['list', '-s']);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: true,
                dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
              )).called(1);
        });
      });

      group('with melos source', () {
        test('should use MelosSource when --source=melos', () async {
          final result = await commandRunner.run(['list', '--source', 'melos']);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: false,
                dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
              )).called(1);
        });
      });

      group('with file source', () {
        test('should use FileSource when --source=file with valid file path',
            () async {
          final result = await commandRunner.run([
            'list',
            '--source',
            'file',
            '--file-path',
            '/path/to/file.json'
          ]);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: false,
                dataSource: any(named: 'dataSource', that: isA<FileSource>()),
              )).called(1);
        });

        test('should exit with error when --source=file without file path',
            () async {
          try {
            await commandRunner.run(['list', '--source', 'file']);
            fail('Expected UsageException to be thrown');
          } catch (e) {
            expect(e, isA<UsageException>());
            expect(
              (e as UsageException).message,
              contains(
                  'The --file-path parameter is required when --source=file'),
            );
          }

          verifyNever(() => service.processGraph(
                simpleList: any(named: 'simpleList'),
                dataSource: any(named: 'dataSource'),
              ));
        });

        test('should exit with error when --source=file with empty file path',
            () async {
          try {
            await commandRunner
                .run(['list', '--source', 'file', '--file-path', '']);
            fail('Expected UsageException to be thrown');
          } catch (e) {
            expect(e, isA<UsageException>());
            expect(
              (e as UsageException).message,
              contains(
                  'The --file-path parameter is required when --source=file'),
            );
          }

          verifyNever(() => service.processGraph(
                simpleList: any(named: 'simpleList'),
                dataSource: any(named: 'dataSource'),
              ));
        });
      });

      group('with invalid source', () {
        test('should exit with error when --source has invalid value',
            () async {
          try {
            await commandRunner.run(['list', '--source', 'invalid']);
            fail('Expected UsageException to be thrown');
          } catch (e) {
            expect(e, isA<UsageException>());
            expect(e.toString(), contains('not an allowed value'));
          }

          verifyNever(() => service.processGraph(
                simpleList: any(named: 'simpleList'),
                dataSource: any(named: 'dataSource'),
              ));
        });
      });

      group('error handling', () {
        test(
            'should return software exit code when UserCancelledException is thrown',
            () async {
          when(() => service.processGraph(
                simpleList: any(named: 'simpleList'),
                dataSource: any(named: 'dataSource'),
              )).thenThrow(UserCancelledException());

          final result = await commandRunner.run(['list']);

          expect(result, equals(ExitCode.software.code));
          verify(() => service.processGraph(
                simpleList: false,
                dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
              )).called(1);
        });

        test('should propagate other exceptions', () async {
          final exception = Exception('Unexpected error');
          when(() => service.processGraph(
                simpleList: any(named: 'simpleList'),
                dataSource: any(named: 'dataSource'),
              )).thenThrow(exception);

          expect(
            () => commandRunner.run(['list']),
            throwsA(equals(exception)),
          );

          verify(() => service.processGraph(
                simpleList: false,
                dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
              )).called(1);
        });
      });

      group('integration scenarios', () {
        test('should work with combined flags and options', () async {
          final result = await commandRunner.run([
            'list',
            '--simple',
            '--source',
            'file',
            '--file-path',
            '/custom/path/deps.json'
          ]);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: true,
                dataSource: any(named: 'dataSource', that: isA<FileSource>()),
              )).called(1);
        });

        test('should work with short flag and file source', () async {
          final result = await commandRunner.run([
            'list',
            '-s',
            '--source',
            'file',
            '--file-path',
            '/another/path/dependencies.json'
          ]);

          expect(result, equals(ExitCode.success.code));
          verify(() => service.processGraph(
                simpleList: true,
                dataSource: any(named: 'dataSource', that: isA<FileSource>()),
              )).called(1);
        });
      });
    });

    group('_createDataSource', () {
      // Note: _createDataSource is private, so it's tested indirectly through run() method
      // The tests above verify the correct DataSource is created for different scenarios

      test('creates MelosSource for melos source type', () async {
        await commandRunner.run(['list', '--source', 'melos']);

        verify(() => service.processGraph(
              simpleList: any(named: 'simpleList'),
              dataSource: any(named: 'dataSource', that: isA<MelosSource>()),
            )).called(1);
      });

      test('creates FileSource for file source type with valid path', () async {
        await commandRunner.run(
            ['list', '--source', 'file', '--file-path', '/test/path.json']);

        verify(() => service.processGraph(
              simpleList: any(named: 'simpleList'),
              dataSource: any(named: 'dataSource', that: isA<FileSource>()),
            )).called(1);
      });
    });
  });
}
