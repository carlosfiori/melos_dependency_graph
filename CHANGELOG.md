# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-08

### Added

- Initial release of Melos Dependency Graph CLI tool
- **Dependency Analysis**: Analyze package dependencies in Melos-managed Dart/Flutter monorepos
- **Topological Sorting**: Display packages in proper build/dependency order
- **Cycle Detection**: Identify and handle circular dependencies with detailed reporting
- **Statistics**: Get insights about package complexity levels and dependency metrics
- **Beautiful Output**: Rich, colorful CLI output with emojis and formatting for better readability
- **Multiple Data Sources**: Support for both live Melos data and JSON dependency files
- **Command-line Interface**:
  - `list` command for displaying dependency graphs and statistics
  - `update` command for updating dependency information
- **Comprehensive Testing**: Full test coverage with unit tests for all components
- **Documentation**: Complete README with installation instructions, usage examples, and API documentation

### Features

- Fast and reliable dependency graph analysis
- Support for complex monorepo structures
- Detailed error reporting and validation
- Configurable output formats
- Cross-platform compatibility (Windows, macOS, Linux)

[1.0.0]: https://github.com/carlosfiori/melos_dependency_graph/releases/tag/v1.0.0
