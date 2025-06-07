import 'dart:convert';

import 'package:melos_dependency_graph/src/services/process_runner.dart';
import 'package:melos_dependency_graph/src/services/strategies/dependency_loading_strategy.dart';

class MelosLoadingStrategy implements DependencyLoadingStrategy {
  final ProcessRunner _processRunner;

  MelosLoadingStrategy({ProcessRunner? processRunner})
      : _processRunner = processRunner ?? DefaultProcessRunner();

  @override
  Future<Map<String, List<String>>> loadDependencies() async {
    final melosResult = await _processRunner.run('melos', ['list', '--graph']);

    if (melosResult.exitCode != 0) {
      throw Exception(
        'Error executing melos list --graph: ${melosResult.stderr}',
      );
    }

    final jsonData =
        json.decode(melosResult.stdout as String) as Map<String, dynamic>;
    final dependencies = <String, List<String>>{};

    jsonData.forEach((key, value) {
      if (value is List) {
        dependencies[key] = value.cast<String>();
      } else {
        dependencies[key] = <String>[];
      }
    });

    return dependencies;
  }
}
