import 'package:cellar/presentation/workspace/sql_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('highlighting keeps the text and marks strings, comments, keywords', () {
    const sql = "select 'a;b', \$\$x\$\$ from t -- note\nwhere id = 42 /* c */";
    final spans = highlightSql(sql);
    expect(spans.map((s) => s.text).join(), sql);
    String styleOf(String piece) => spans.firstWhere((s) => s.text == piece).style?.color?.toARGB32().toRadixString(16) ?? 'plain';
    expect(styleOf('select'), isNot('plain'));
    expect(styleOf("'a;b'"), isNot('plain'));
    expect(styleOf('-- note'), isNot('plain'));
    expect(styleOf('42'), isNot('plain'));
  });

  test('an error position is underlined', () {
    final spans = highlightSql('select nosuch from t', errorAt: 7);
    final bad = spans.firstWhere((s) => s.style?.decoration != null);
    expect(bad.text, 'nosuch');
  });
}
