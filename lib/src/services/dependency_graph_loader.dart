import 'package:melos_dependency_graph/src/models/models.dart';
import 'package:melos_dependency_graph/src/services/strategies/strategies.dart';

class DependencyGraphLoader {
  Future<Map<String, List<String>>> loadDependencies({
    required DataSource dataSource,
  }) async {
    final strategy = _createStrategy(dataSource);
    return strategy.loadDependencies();
  }

  DependencyLoadingStrategy _createStrategy(DataSource dataSource) {
    switch (dataSource) {
      case FileSource fileSource:
        return FileLoadingStrategy(fileSource.filePath);
      case MelosSource _:
        return MelosLoadingStrategy();
      default:
        throw ArgumentError('Fonte não suportada: $dataSource');
    }
  }
}
