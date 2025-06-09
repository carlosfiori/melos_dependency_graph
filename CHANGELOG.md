# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-06-08

### Added

- **Contributors Section**: Added comprehensive contributors section to README with visual table format
- **GitHub Integration**: Contributor profiles now display GitHub avatars automatically

### Changed

- **Documentation**: Enhanced README with better contributor recognition
- **Links**: Updated all repository links to use correct GitHub repository URL
- **License References**: Corrected license badge and links to reflect BSD 3-Clause License

### Fixed

- **README Links**: Fixed placeholder GitHub URLs in documentation and support sections
- **License Badge**: Corrected license badge from MIT to BSD 3-Clause to match actual license

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

[1.0.1]: https://github.com/carlosfiori/melos_dependency_graph/releases/tag/v1.0.1
[1.0.0]: https://github.com/carlosfiori/melos_dependency_graph/releases/tag/v1.0.0
