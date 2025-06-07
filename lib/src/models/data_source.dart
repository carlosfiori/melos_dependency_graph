abstract class DataSource {
  const DataSource();
}

class MelosSource extends DataSource {
  const MelosSource();

  @override
  String toString() => 'MelosSource()';

  @override
  bool operator ==(Object other) => other is MelosSource;

  @override
  int get hashCode => runtimeType.hashCode;
}

class FileSource extends DataSource {
  const FileSource(this.filePath);

  final String filePath;

  @override
  String toString() => 'FileSource($filePath)';

  @override
  bool operator ==(Object other) =>
      other is FileSource && other.filePath == filePath;

  @override
  int get hashCode => filePath.hashCode;
}
