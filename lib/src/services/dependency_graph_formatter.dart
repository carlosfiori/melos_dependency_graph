import 'package:mason_logger/mason_logger.dart';
import 'package:melos_dependency_graph/src/models/models.dart';

class DependencyGraphFormatter {
  const DependencyGraphFormatter({required Logger logger}) : _logger = logger;

  final Logger _logger;

  Future<bool> showCycleWarnings(
    List<List<String>> cycles, {
    required bool simpleList,
  }) async {
    if (cycles.isEmpty) return true;

    if (!simpleList) {
      _logger.warn('⚠️  WARNING: Cyclic dependencies detected!');
      for (var i = 0; i < cycles.length; i++) {
        _logger.info('Cycle ${i + 1}: ${cycles[i].join(' -> ')}');
      }
      _logger.info('\nThis may cause problems in build order.');
      final response = _logger
          .confirm("Do you want to ignore cyclic dependencies and continue?");

      if (!response) {
        _logger.info('Operation cancelled.');
        return false;
      }
      _logger.info('Removing cyclic dependencies...\n');
    }

    return true;
  }

  void displayResults(
    List<String> sortedPackages, {
    required bool simpleList,
    Map<String, List<String>>? originalDependencies,
    DataSource? dataSource,
    DependencyStats? stats,
    Duration? processingTime,
  }) {
    final reversedResult = sortedPackages.reversed.toList();

    if (simpleList) {
      for (final package in reversedResult) {
        _logger.info(package);
      }
    } else {
      _displayEnhancedResults(
        reversedResult,
        originalDependencies: originalDependencies,
        dataSource: dataSource,
        stats: stats,
        processingTime: processingTime,
      );
    }
  }

  void _displayEnhancedResults(
    List<String> sortedPackages, {
    Map<String, List<String>>? originalDependencies,
    DataSource? dataSource,
    DependencyStats? stats,
    Duration? processingTime,
  }) {
    _displayHeader(dataSource, stats, processingTime);

    if (stats != null) {
      _displayStatistics(stats);
    }

    _displayDependencyList(sortedPackages, originalDependencies);
  }

  void _displayHeader(
    DataSource? dataSource,
    DependencyStats? stats,
    Duration? processingTime,
  ) {
    final sourceDesc = _getSourceDescription(dataSource);
    final timeDesc =
        processingTime != null ? '${processingTime.inMilliseconds}ms' : 'N/A';
    final totalPackages = stats?.totalPackages ?? 0;

    _logger
      ..info('📦 MELOS DEPENDENCY ANALYSIS')
      ..info('├─ Source: $sourceDesc')
      ..info('├─ Processing: $timeDesc')
      ..info('└─ Total: $totalPackages packages found\n');
  }

  void _displayStatistics(DependencyStats stats) {
    _logger
      ..info('📊 STATISTICS:')
      ..info('├─ 🟢 Base packages (0 deps): ${stats.basePackages} packages')
      ..info(
          '├─ 🟡 Intermediate packages (1-5 deps): ${stats.intermediatePackages} packages')
      ..info(
          '└─ 🔴 High-level packages (6+ deps): ${stats.highLevelPackages} packages');

    if (stats.packageWithMostDeps != null) {
      _logger.info(
        '   └─ Highest complexity: ${stats.packageWithMostDeps} (${stats.maxDependencies} deps)',
      );
    }

    if (stats.cyclesDetected > 0) {
      _logger.info(
          '   └─ ⚠️  ${stats.cyclesDetected} cycles detected and removed');
    }

    _logger.info('');
  }

  void _displayDependencyList(
    List<String> sortedPackages,
    Map<String, List<String>>? originalDependencies,
  ) {
    _logger
      ..info('🏗️  TOPOLOGICAL DEPENDENCY ORDER')
      ..info('(From fundamental level to highest level)\n');

    for (var i = 0; i < sortedPackages.length; i++) {
      final package = sortedPackages[i];
      final dependencies = originalDependencies?[package] ?? [];
      final icon = _getPackageIcon(dependencies.length);
      final depInfo = _getDependencyInfo(dependencies);

      final numberPadded = (i + 1).toString().padLeft(2);
      _logger.info('$icon $numberPadded. $package$depInfo');
    }

    _logger.info('\nTotal: ${sortedPackages.length} packages');
  }

  String _getSourceDescription(DataSource? dataSource) {
    return switch (dataSource) {
      MelosSource() => 'melos list --graph',
      FileSource fileSource => 'file ${fileSource.filePath}',
      _ => 'unknown source',
    };
  }

  String _getPackageIcon(int dependencyCount) {
    return switch (dependencyCount) {
      0 => '🟢',
      <= 5 => '🟡',
      _ => '🔴',
    };
  }

  String _getDependencyInfo(List<String> dependencies) {
    if (dependencies.isEmpty) return '';
    if (dependencies.length <= 3) {
      return ' → ${dependencies.join(', ')}';
    }
    return ' → ${dependencies.take(2).join(', ')}, ... (+${dependencies.length - 2} more)';
  }
}
