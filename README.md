# Melos Dependency Graph 📦

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: BSD-3-Clause][license_badge]][license_link]
[![Pub Version](https://img.shields.io/pub/v/melos_dependency_graph.svg)](https://pub.dev/packages/melos_dependency_graph)

A powerful CLI tool for analyzing and visualizing dependency graphs in **Melos-managed Dart/Flutter monorepos**. Get insights into your package dependencies, detect cycles, and understand build order with beautiful, detailed output.

## ✨ Features

- 🔍 **Dependency Analysis**: Analyze package dependencies in Melos monorepos
- 📊 **Topological Sorting**: Display packages in proper build/dependency order
- 🔄 **Cycle Detection**: Identify and handle circular dependencies
- 📈 **Statistics**: Get insights about package complexity levels
- 🎨 **Beautiful Output**: Rich, colorful CLI output with emojis and formatting
- 📁 **Multiple Sources**: Work with live Melos data or JSON dependency files
- ⚡ **Fast & Reliable**: Built with performance and accuracy in mind

## 🚀 Installation

### Global Installation (Recommended)

```bash
dart pub global activate melos_dependency_graph
```

### Local Installation

```bash
dart pub global activate --source=path <path-to-this-package>
```

## 📋 Prerequisites

- **Dart SDK**: `>=3.5.0`
- **Melos**: Must be installed and configured in your monorepo (for Melos source)

## 💻 Usage

### Quick Start

Navigate to your Melos-managed monorepo and run:

```bash
# Analyze dependencies with enhanced output
melos_dependency_graph list

# Simple list output
melos_dependency_graph list --simple
```

### Commands

#### `list` - Analyze Dependencies

The main command for dependency analysis with multiple options:

```bash
# Basic usage with enhanced output
melos_dependency_graph list

# Simple list format (package names only)
melos_dependency_graph list --simple

# Use a custom JSON file as source
melos_dependency_graph list --source=file --file-path=deps.json

# Short flags
melos_dependency_graph list -s  # simple output
```

#### `update` - Update CLI

Keep your CLI up to date:

```bash
melos_dependency_graph update
```

#### Help & Version

```bash
# Show help
melos_dependency_graph --help
melos_dependency_graph list --help

# Show version
melos_dependency_graph --version
```

### Command Options

| Option        | Short | Description                                       | Default |
| ------------- | ----- | ------------------------------------------------- | ------- |
| `--simple`    | `-s`  | Display simple list output                        | `false` |
| `--source`    |       | Data source: `melos` or `file`                    | `melos` |
| `--file-path` |       | Path to JSON file (required when `--source=file`) |         |

## 📊 Output Examples

### Enhanced Output (Default)

```
📦 MELOS DEPENDENCY ANALYSIS
├─ Source: melos list --graph
├─ Processing: 45ms
└─ Total: 8 packages found

📊 STATISTICS:
├─ 🟢 Base packages (0 deps): 2 packages
├─ 🟡 Intermediate packages (1-5 deps): 4 packages
└─ 🔴 High-level packages (6+ deps): 2 packages

🏆 Most complex: mobile_app (12 dependencies)

📦 DEPENDENCY ORDER (build order):
├─ core_utils
├─ shared_models
├─ api_client → [core_utils, shared_models]
├─ data_layer → [core_utils, shared_models, api_client]
├─ business_logic → [core_utils, shared_models, data_layer]
├─ ui_components → [core_utils, shared_models]
├─ feature_auth → [core_utils, shared_models, data_layer, business_logic, ui_components]
└─ mobile_app → [core_utils, shared_models, api_client, data_layer, business_logic, ui_components, feature_auth]
```

### Simple Output

```bash
melos_dependency_graph list --simple
```

```
core_utils
shared_models
api_client
data_layer
business_logic
ui_components
feature_auth
mobile_app
```

### Cycle Detection

When circular dependencies are detected:

```
⚠️  WARNING: Cyclic dependencies detected!
Cycle 1: package_a -> package_b -> package_c -> package_a

This may cause problems in build order.
? Do you want to ignore cyclic dependencies and continue? (y/N)
```

## 🗂️ Data Sources

### 1. Melos Source (Default)

Directly integrates with Melos to analyze your monorepo:

- Executes `melos list --graph` automatically
- Real-time analysis of current dependency state
- Requires Melos to be properly configured

### 2. File Source

Use a pre-generated JSON dependency file:

```bash
melos_dependency_graph list --source=file --file-path=my-deps.json
```

**Expected JSON format:**

```json
{
  "package_a": ["package_b", "package_c"],
  "package_b": ["package_c"],
  "package_c": [],
  "package_d": ["package_a", "package_c"]
}
```

## 🎯 Use Cases

### 1. **Build Order Optimization**

Understand the correct order to build packages in your CI/CD pipeline:

```bash
melos_dependency_graph list --simple > build-order.txt
```

### 2. **Dependency Audit**

Review and analyze package relationships:

```bash
melos_dependency_graph list  # See detailed dependency tree
```

### 3. **Cycle Detection**

Identify problematic circular dependencies before they cause issues:

```bash
melos_dependency_graph list  # Will warn about cycles
```

### 4. **Monorepo Health Check**

Get statistics about your repository's dependency complexity:

```bash
melos_dependency_graph list  # Shows package complexity levels
```

## 🔧 Integration Examples

### CI/CD Pipeline

```yaml
# .github/workflows/build.yml
- name: Generate build order
  run: |
    dart pub global activate melos_dependency_graph
    melos_dependency_graph list --simple > .build-order

- name: Build packages in order
  run: |
    while read package; do
      echo "Building $package..."
      melos run build --scope="$package"
    done < .build-order
```

### Makefile Integration

```makefile
.PHONY: analyze-deps
analyze-deps:
	@echo "Analyzing dependencies..."
	@melos_dependency_graph list

.PHONY: build-order
build-order:
	@melos_dependency_graph list --simple
```

## 🛠️ Development

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd melos_dependency_graph

# Install dependencies
dart pub get

# Run tests
dart test

# Run with coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

### Building

```bash
# Build the executable
dart compile exe bin/melos_dependency_graph.dart
```

## 📝 Requirements

- **Dart SDK**: `>=3.5.0`
- **Melos**: Required when using the default Melos source
- **Monorepo**: Your project should be structured as a Melos monorepo

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 👥 Contributors

We thank the following people for their contributions to this project:

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/carlosfiori">
        <img src="https://github.com/carlosfiori.png" width="100px;" alt="Carlos Fiori"/><br />
        <sub><b>Carlos Fiori</b></sub>
      </a><br />
    </td>
  </tr>
</table>

**Want to contribute?** Check out our [contributing guidelines](#-contributing) and feel free to submit a pull request or open an issue!

## 📄 License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [documentation](https://pub.dev/packages/melos_dependency_graph)
2. [Open an issue](https://github.com/carlosfiori/melos_dependency_graph/issues) on GitHub

---

Built with ❤️ using [Very Good CLI](https://github.com/VeryGoodOpenSource/very_good_cli)

[license_badge]: https://img.shields.io/badge/license-BSD--3--Clause-blue.svg
[license_link]: https://opensource.org/licenses/BSD-3-Clause
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
