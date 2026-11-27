// Drives the real app (real core, real SSH and PostgreSQL) through a
// scenario from inside its own process and writes a screenshot after each
// step. Pointer events go straight into the gesture binding, text into the
// fields' editing state: nothing touches the desktop. The app starts in
// English (no app.json in the isolated config dir), so the scenario matches
// the English strings.
//
//   SHOTS=/tmp/shots E2E_PG_PASSWORD=secret flutter run -d linux -t tool/e2e.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cellar/app.dart';
import 'package:cellar/core/settings/app_settings.dart';
import 'package:cellar/data/rpc/endpoint.dart';
import 'package:cellar/presentation/common/buttons.dart';
import 'package:cellar/presentation/core/core_cubit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

final _out = Directory(Platform.environment['SHOTS'] ?? 'shots');
var _shot = 0;
var _pointer = 100;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  _out.createSync(recursive: true);
  final core = CoreCubit(CoreLauncher.forPlatform())..connect();
  runApp(CellarApp(core: core));
  unawaited(_scenario().then((_) => exit(0), onError: (Object e, StackTrace st) async {
    stderr.writeln('E2E FAILED: $e\n$st');
    await _snap('failure');
    exit(1);
  }));
}

Future<void> _scenario() async {
  final pgPassword = Platform.environment['E2E_PG_PASSWORD'] ?? 'secret';
  await _waitText('local-docker');
  await _snap('tree');

  // Server → context menu → find databases.
  await _tap(await _waitText('local-docker'), secondary: true);
  await _snap('server-menu');
  await _tap(await _waitText('Find databases…'));
  // First connection: the host key.
  await _waitText('New server', exact: true);
  await _snap('host-key');
  await _tap(await _waitText('Trust and connect'));
  await _waitText('docker: cellar-e2e-pg', timeout: 40);
  await _pause(800);
  await _snap('discovered');

  // Connect the container found.
  final row = await _waitText('docker: cellar-e2e-pg');
  await _tap(_nearest(row, 'Connect…'));
  await _waitText('New connection');
  await _type('Password', pgPassword);
  await _tap(await _waitText('Test', exact: true));
  await _waitText('Connected: PostgreSQL', timeout: 20);
  await _snap('connection-test');
  await _tap(await _waitText('Save', exact: true));
  await _pause(600);
  await _tap(await _waitText('Close', exact: true));
  await _pause(500);

  // Tree: server → connection → shop → public → tables.
  await _tap(await _waitText('local-docker'));
  await _pause(400);
  await _tap(await _waitText('cellar-e2e-pg'));
  await _tap(await _waitText('shop', exact: true, timeout: 20));
  await _tap(await _waitText('public', exact: true, timeout: 20));
  await _tap(await _waitText('tables', exact: true, timeout: 20));
  await _tap(await _waitText('views', exact: true));
  await _tap(await _waitText('routines', exact: true));
  await _pause(500);
  await _snap('tree-expanded');

  // Data viewer: open customers, sort by city, edit a cell, submit.
  await _tap(await _waitText('customers', exact: true), double: true);
  await _waitText('Customer 1', exact: true, timeout: 20);
  await _snap('table');
  await _tap(await _waitText('city', exact: true));
  await _pause(1500);
  await _tap(await _waitText('city', exact: true));
  await _pause(1500);
  await _snap('table-sorted');
  final cell = (await _waitTexts('Tokyo')).first;
  await _tap(cell, double: true);
  await _pause(400);
  await _typeFocused('Kyoto');
  await _pause(400);
  await _snap('table-edited');
  await _tap(await _waitText('Submit (1)'));
  await _waitText('1 rows saved', timeout: 10);
  await _pause(800);
  await _snap('table-saved');

  // Filter.
  await _typeHint('price > 10', "city = 'Kyoto'", submit: true);
  await _pause(1500);
  await _snap('table-filtered');

  // Console on shop: two statements, run the second, then everything.
  await _tap(await _waitText('shop', exact: true), secondary: true);
  await _tap(await _waitText('New console'));
  await _waitText('Connected: PostgreSQL', timeout: 20);
  await _setEditor(
    "select status, count(*), round(avg(total), 2) as avg_total\nfrom orders\ngroup by status\norder by 2 desc;\n\n"
    "select c.name, c.city, order_count(c.id) from customers c where c.city = 'Kyoto' limit 5;",
    cursor: 10,
  );
  await _tap(_iconButton('Run the statement at the cursor'));
  await _waitText('3 rows in', timeout: 20);
  await _pause(500);
  await _snap('console-result');
  await _setEditor('begin;\nupdate orders set status = status where id < 10;\nselect nosuch from orders;', cursor: 0);
  await _tap(_iconButton('Run everything'));
  await _waitText('transaction failed', timeout: 20);
  await _pause(500);
  await _snap('console-error');
  await _tap(await _waitText('Rollback', exact: true));
  await _pause(1500);

  // Structure of orders.
  await _tap(await _waitText('orders', exact: true), secondary: true);
  await _tap(await _waitText('Structure and DDL'));
  await _waitText('DDL', exact: true, timeout: 20);
  await _pause(800);
  await _snap('structure');
  await _tap(await _waitText('DDL', exact: true));
  await _pause(500);
  await _snap('ddl');

  // Settings / Shard.
  await _tap(_iconButton('Settings and Shard'));
  await _pause(800);
  await _snap('settings');
}

// --- finding -------------------------------------------------------------

Iterable<Element> _all() sync* {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;
  final stack = <Element>[root];
  while (stack.isNotEmpty) {
    final e = stack.removeLast();
    yield e;
    e.visitChildren(stack.add);
  }
}

String? _textOf(Widget w) => switch (w) {
  Text(:final data?) => data,
  Text(:final textSpan?) => textSpan.toPlainText(),
  RichText(:final text) => text.toPlainText(),
  _ => null,
};

List<Element> _find(String text, {bool exact = false}) => [
  for (final e in _all())
    if (e.widget is RichText && _visible(e))
      if (_textOf(e.widget) case final t? when exact ? t == text : t.contains(text)) e,
];

bool _visible(Element e) {
  final ro = e.renderObject;
  if (ro is! RenderBox || !ro.attached || !ro.hasSize) return false;
  // Not in an IndexedStack's hidden child or offstage.
  var ok = true;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Offstage && w.offstage) ok = false;
    if (w is Visibility && !w.visible) ok = false;
    return ok;
  });
  if (!ok) return false;
  final r = MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size);
  final view = WidgetsBinding.instance.renderViews.first.size;
  return r.width > 0 && r.overlaps(Offset.zero & view) && _hittable(ro, r.center);
}

/// The point really reaches this render object (not covered, not in a
/// hidden IndexedStack child).
bool _hittable(RenderBox ro, Offset p) {
  final res = HitTestResult();
  WidgetsBinding.instance.hitTestInView(res, p, WidgetsBinding.instance.renderViews.first.flutterView.viewId);
  return res.path.any((entry) => entry.target == ro);
}

Future<Element> _waitText(String text, {bool exact = false, int timeout = 10}) async => (await _waitTexts(text, exact: exact, timeout: timeout)).last;

Future<List<Element>> _waitTexts(String text, {bool exact = false, int timeout = 10}) async {
  final end = DateTime.now().add(Duration(seconds: timeout));
  while (true) {
    final f = _find(text, exact: exact);
    if (f.isNotEmpty) return f;
    if (DateTime.now().isAfter(end)) throw StateError('no "$text" on screen');
    await _pause(100);
  }
}

/// The element with [text] closest below/right of [anchor] on its row.
Element _nearest(Element anchor, String text) {
  final a = _center(anchor);
  final c = _find(text).toList()..sort((x, y) => ((_center(x).dy - a.dy).abs()).compareTo((_center(y).dy - a.dy).abs()));
  if (c.isEmpty) throw StateError('no "$text" near the row');
  return c.first;
}

Element _iconButton(String label) {
  for (final e in _all()) {
    final w = e.widget;
    if (w is HmIconButton && w.label.startsWith(label) && _visible(e)) return e;
  }
  throw StateError('no icon button "$label"');
}

Offset _center(Element e) {
  final ro = e.renderObject! as RenderBox;
  return ro.localToGlobal(ro.size.center(Offset.zero));
}

// --- acting -----------------------------------------------------------------

Future<void> _pause(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

Future<void> _tap(Element e, {bool secondary = false, bool double = false}) async {
  final p = _center(e);
  final b = WidgetsBinding.instance;
  for (var i = 0; i < (double ? 2 : 1); i++) {
    final id = _pointer++;
    final kind = PointerDeviceKind.mouse;
    final buttons = secondary ? kSecondaryMouseButton : kPrimaryMouseButton;
    b.handlePointerEvent(PointerAddedEvent(pointer: id, position: p, kind: kind));
    b.handlePointerEvent(PointerHoverEvent(pointer: id, position: p, kind: kind));
    b.handlePointerEvent(PointerDownEvent(pointer: id, position: p, kind: kind, buttons: buttons));
    await _pause(40);
    b.handlePointerEvent(PointerUpEvent(pointer: id, position: p, kind: kind));
    b.handlePointerEvent(PointerRemovedEvent(pointer: id, position: p, kind: kind));
    await _pause(double ? 60 : 350);
  }
  await _pause(300);
}

/// Types into the text field labelled [label] (HmTextField).
Future<void> _type(String label, String text) async {
  final labelEl = await _waitText(label.toUpperCase(), exact: true);
  final y = _center(labelEl).dy;
  EditableTextState? best;
  var bestD = double.infinity;
  for (final e in _all()) {
    if (e is StatefulElement && e.state is EditableTextState && _visibleBox(e)) {
      final c = _center(e);
      final d = c.dy - y;
      if (d > 0 && d < bestD && (c.dx - _center(labelEl).dx).abs() < 400) {
        bestD = d;
        best = e.state as EditableTextState;
      }
    }
  }
  if (best == null) throw StateError('no field "$label"');
  best.userUpdateTextEditingValue(TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)), SelectionChangedCause.keyboard);
  await _pause(200);
}

bool _visibleBox(Element e) {
  final ro = e.renderObject;
  return ro is RenderBox && ro.attached && ro.hasSize && ro.size.width > 0;
}

/// Types into the focused field and presses Enter (the grid's editor).
Future<void> _typeFocused(String text) async {
  final f = FocusManager.instance.primaryFocus?.context;
  EditableTextState? s;
  f?.visitAncestorElements((a) {
    if (a is StatefulElement && a.state is EditableTextState) s = a.state as EditableTextState;
    return s == null;
  });
  if (s == null) {
    for (final e in _all()) {
      if (e is StatefulElement && e.state is EditableTextState && (e.state as EditableTextState).widget.focusNode.hasFocus) s = e.state as EditableTextState;
    }
  }
  if (s == null) throw StateError('no focused field');
  s!.userUpdateTextEditingValue(TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)), SelectionChangedCause.keyboard);
  await _pause(100);
  s!.performAction(TextInputAction.done);
}

/// Types into the field showing [hint] as its placeholder.
Future<void> _typeHint(String hint, String text, {bool submit = false}) async {
  for (final e in _all()) {
    if (e is StatefulElement && e.state is EditableTextState && _visibleBox(e)) {
      var match = false;
      e.visitAncestorElements((a) {
        final w = a.widget;
        if (w is TextField && (w.decoration?.hintText ?? '').contains(hint)) match = true;
        return !match && w is! TextField;
      });
      if (match) {
        final s = e.state as EditableTextState;
        s.userUpdateTextEditingValue(TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)), SelectionChangedCause.keyboard);
        if (submit) s.performAction(TextInputAction.done);
        await _pause(200);
        return;
      }
    }
  }
  throw StateError('no field with hint "$hint"');
}

/// Replaces the console text and puts the cursor at [cursor].
Future<void> _setEditor(String text, {required int cursor}) async {
  for (final e in _all()) {
    if (e is StatefulElement && e.state is EditableTextState && _visibleBox(e)) {
      final s = e.state as EditableTextState;
      if (s.widget.maxLines == null && s.widget.expands) {
        s.userUpdateTextEditingValue(TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cursor)), SelectionChangedCause.keyboard);
        await _pause(200);
        return;
      }
    }
  }
  throw StateError('no console editor');
}

Future<void> _snap(String name) async {
  await _pause(150);
  await WidgetsBinding.instance.endOfFrame;
  final view = WidgetsBinding.instance.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final img = await layer.toImage(Offset.zero & view.size, pixelRatio: 1);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File('${_out.path}/${(++_shot).toString().padLeft(2, '0')}-$name.png');
  await f.writeAsBytes(png!.buffer.asUint8List());
  stdout.writeln('shot ${f.path}');
}
