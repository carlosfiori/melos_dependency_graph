import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:melos_dependency_graph/src/services/services.dart';

class ListCommand extends Command<int> {
  ListCommand({
    required Logger logger,
    required DependencyGraphService service,
  }) : _service = service {
    argParser
      ..addFlag(
        'simple',
        abbr: 's',
        help: 'Display a simple list of packages',
        negatable: false,
      )
      ..addOption(
        'source',
        help: 'Dependency data source',
        allowed: ['file', 'melos'],
        defaultsTo: 'melos',
        allowedHelp: {
          'file':
              'Load dependencies from specified file (requires --file-path)',
          'melos': 'Execute melos list --graph command',
        },
      )
      ..addOption(
        'file-path',
        help: 'Path to JSON file (required when --source=file)',
      );
  }

  final DependencyGraphService _service;

  @override
  String get description => 'List dependencies in topological order';

  @override
  String get name => 'list';

  @override
  Future<int> run() async {
    final simpleList = argResults!['simple'] == true;
    final source = argResults!['source'] as String;
    final filePath = argResults!['file-path'] as String?;

    final dataSource = _createDataSource(source, filePath);

    try {
      await _service.processGraph(
        simpleList: simpleList,
        dataSource: dataSource,
      );
    } on UserCancelledException catch (_) {
      return ExitCode.software.code;
    }
    return ExitCode.success.code;
  }

  DataSource _createDataSource(String source, String? filePath) {
    switch (source) {
      case 'melos':
        return const MelosSource();
      case 'file':
        if (filePath == null || filePath.isEmpty) {
          throw UsageException(
            'The --file-path parameter is required when --source=file',
            usage,
          );
        }
        return FileSource(filePath);
      default:
        throw UsageException('Invalid source: $source', usage);
    }
  }
}
