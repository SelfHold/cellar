import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

const _keywords = {
  'select', 'from', 'where', 'and', 'or', 'not', 'in', 'is', 'null', 'as', 'on', 'join', 'left', 'right', 'inner', 'outer',
  'full', 'cross', 'natural', 'using', 'group', 'by', 'order', 'having', 'limit', 'offset', 'fetch', 'first', 'next', 'rows',
  'only', 'distinct', 'all', 'union', 'intersect', 'except', 'insert', 'into', 'values', 'update', 'set', 'delete', 'returning',
  'create', 'alter', 'drop', 'table', 'view', 'materialized', 'index', 'unique', 'primary', 'key', 'foreign', 'references',
  'constraint', 'check', 'default', 'schema', 'database', 'sequence', 'function', 'procedure', 'trigger', 'extension', 'type',
  'if', 'exists', 'cascade', 'restrict', 'begin', 'commit', 'rollback', 'savepoint', 'transaction', 'with', 'recursive',
  'case', 'when', 'then', 'else', 'end', 'like', 'ilike', 'between', 'asc', 'desc', 'nulls', 'last', 'true', 'false',
  'grant', 'revoke', 'to', 'explain', 'analyze', 'verbose', 'vacuum', 'truncate', 'copy', 'returns', 'language', 'replace',
  'do', 'declare', 'lateral', 'window', 'over', 'partition', 'filter', 'conflict', 'nothing', 'any', 'some', 'array', 'cast',
  'interval', 'add', 'column', 'rename', 'owner', 'temp', 'temporary', 'show', 'reset', 'listen', 'notify', 'lock', 'for',
  'share', 'nowait', 'skip', 'locked', 'collate', 'similar', 'escape', 'generated', 'always', 'identity', 'stored', 'serial',
};

const _types = {
  'int', 'integer', 'bigint', 'smallint', 'text', 'varchar', 'char', 'character', 'varying', 'boolean', 'bool', 'numeric',
  'decimal', 'real', 'double', 'precision', 'float', 'date', 'time', 'timestamp', 'timestamptz', 'jsonb', 'json', 'uuid',
  'bytea', 'inet', 'cidr', 'serial', 'bigserial', 'money', 'xml', 'tsvector', 'oid', 'regclass', 'zone', 'without',
};

/// A text controller that colours SQL (keywords, strings, comments,
/// numbers) the way DataGrip's console does.
class SqlController extends TextEditingController {
  SqlController({super.text});

  /// The error position to underline (UTF-16 offset), -1 = none.
  int errorAt = -1;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final base = HmText.jb(13, height: 1.5);
    return TextSpan(style: base, children: highlightSql(text, errorAt: errorAt));
  }
}

final _kw = TextStyle(color: const Color(0xFFCC7832).withValues(alpha: 1), fontWeight: FontWeight.w600);
const _str = TextStyle(color: Color(0xFF6A8759));
const _com = TextStyle(color: Color(0xFF808080), fontStyle: FontStyle.italic);
const _num = TextStyle(color: Color(0xFF6897BB));
const _typ = TextStyle(color: HmColors.purpleLight);
const _ident = TextStyle(color: Color(0xFFA9B7C6));

final _wordCh = RegExp(r'[\w$."]');
final _dollar = RegExp(r'\$([A-Za-z_][A-Za-z0-9_]*)?\$');
final _alpha = RegExp(r'[A-Za-z_]');
final _alnum = RegExp(r'[A-Za-z0-9_$]');
final _digit = RegExp(r'[0-9]');
final _numCh = RegExp(r'[0-9.eE]');

/// Spans of SQL text with colours.
List<TextSpan> highlightSql(String s, {int errorAt = -1}) {
  final out = <TextSpan>[];
  var i = 0;
  final n = s.length;
  void add(int from, int to, [TextStyle? st]) {
    if (to <= from) return;
    if (errorAt >= from && errorAt < to) {
      // Underline the word with the error.
      var e = errorAt;
      while (e < to && _wordCh.hasMatch(s[e])) {
        e++;
      }
      if (e == errorAt) e = errorAt + 1;
      if (errorAt > from) out.add(TextSpan(text: s.substring(from, errorAt), style: st));
      out.add(TextSpan(
        text: s.substring(errorAt, e.clamp(errorAt + 1, to)),
        style: (st ?? const TextStyle()).copyWith(decoration: TextDecoration.underline, decorationColor: HmColors.error, decorationStyle: TextDecorationStyle.wavy, decorationThickness: 2),
      ));
      if (e < to) out.add(TextSpan(text: s.substring(e, to), style: st));
      return;
    }
    out.add(TextSpan(text: s.substring(from, to), style: st));
  }

  var plain = 0;
  void flush(int to) {
    add(plain, to);
  }

  while (i < n) {
    final c = s[i];
    if (c == '-' && i + 1 < n && s[i + 1] == '-') {
      flush(i);
      final e = s.indexOf('\n', i);
      final end = e < 0 ? n : e;
      add(i, end, _com);
      i = plain = end;
    } else if (c == '/' && i + 1 < n && s[i + 1] == '*') {
      flush(i);
      final e = s.indexOf('*/', i + 2);
      final end = e < 0 ? n : e + 2;
      add(i, end, _com);
      i = plain = end;
    } else if (c == "'") {
      flush(i);
      var j = i + 1;
      while (j < n) {
        if (s[j] == "'") {
          if (j + 1 < n && s[j + 1] == "'") {
            j += 2;
            continue;
          }
          break;
        }
        j++;
      }
      final end = j < n ? j + 1 : n;
      add(i, end, _str);
      i = plain = end;
    } else if (c == r'$') {
      final m = _dollar.matchAsPrefix(s, i);
      if (m != null) {
        flush(i);
        final tag = m.group(0)!;
        final e = s.indexOf(tag, i + tag.length);
        final end = e < 0 ? n : e + tag.length;
        add(i, end, _str);
        i = plain = end;
      } else {
        i++;
      }
    } else if (c == '"') {
      flush(i);
      final e = s.indexOf('"', i + 1);
      final end = e < 0 ? n : e + 1;
      add(i, end, _ident);
      i = plain = end;
    } else if (_alpha.hasMatch(c)) {
      var j = i + 1;
      while (j < n && _alnum.hasMatch(s[j])) {
        j++;
      }
      final w = s.substring(i, j).toLowerCase();
      final prevDot = i > 0 && s[i - 1] == '.';
      if (!prevDot && _keywords.contains(w)) {
        flush(i);
        add(i, j, _kw);
        plain = j;
      } else if (!prevDot && _types.contains(w)) {
        flush(i);
        add(i, j, _typ);
        plain = j;
      }
      i = j;
    } else if (_digit.hasMatch(c) && (i == 0 || !_alpha.hasMatch(s[i - 1]))) {
      var j = i + 1;
      while (j < n && _numCh.hasMatch(s[j])) {
        j++;
      }
      flush(i);
      add(i, j, _num);
      i = plain = j;
    } else {
      i++;
    }
  }
  flush(n);
  return out;
}
