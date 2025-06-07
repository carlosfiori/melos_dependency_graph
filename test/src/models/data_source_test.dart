import 'package:melos_dependency_graph/src/models/data_source.dart';
import 'package:test/test.dart';

void main() {
  group('MelosSource', () {
    test('should create instance correctly', () {
      const source = MelosSource();
      expect(source, isA<MelosSource>());
    });

    test('should have correct toString', () {
      const source = MelosSource();
      expect(source.toString(), equals('MelosSource()'));
    });

    test('should be equal to another MelosSource', () {
      const source1 = MelosSource();
      const source2 = MelosSource();
      expect(source1, equals(source2));
      expect(source1.hashCode, equals(source2.hashCode));
    });
  });

  group('FileSource', () {
    test('should create instance with file path', () {
      const filePath = '/path/to/file.json';
      const source = FileSource(filePath);
      expect(source.filePath, equals(filePath));
    });

    test('should have correct toString', () {
      const filePath = '/path/to/file.json';
      const source = FileSource(filePath);
      expect(source.toString(), equals('FileSource($filePath)'));
    });

    test('should be equal when file paths are same', () {
      const filePath = '/path/to/file.json';
      const source1 = FileSource(filePath);
      const source2 = FileSource(filePath);
      expect(source1, equals(source2));
      expect(source1.hashCode, equals(source2.hashCode));
    });

    test('should not be equal when file paths are different', () {
      const source1 = FileSource('/path/to/file1.json');
      const source2 = FileSource('/path/to/file2.json');
      expect(source1, isNot(equals(source2)));
      expect(source1.hashCode, isNot(equals(source2.hashCode)));
    });

    test('should not be equal to MelosSource', () {
      const fileSource = FileSource('/path/to/file.json');
      const melosSource = MelosSource();
      expect(fileSource, isNot(equals(melosSource)));
    });
  });
}
