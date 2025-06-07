import 'dart:convert';
import 'dart:io';

import 'package:melos_dependency_graph/src/services/strategies/dependency_loading_strategy.dart';

class FileLoadingStrategy implements DependencyLoadingStrategy {
  final String filePath;

  FileLoadingStrategy(this.filePath);

  @override
  Future<Map<String, List<String>>> loadDependencies() async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Arquivo não encontrado: $filePath');
    }

    final dependenciesJsonString = await file.readAsString();

    final jsonData =
        json.decode(dependenciesJsonString) as Map<String, dynamic>;
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
