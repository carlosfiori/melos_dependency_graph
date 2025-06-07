abstract class DependencyLoadingStrategy {
  Future<Map<String, List<String>>> loadDependencies();
}
