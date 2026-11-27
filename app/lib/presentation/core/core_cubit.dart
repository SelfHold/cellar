import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/endpoint.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;

enum Conn { connecting, ready, failed }

class CoreState extends Equatable {
  const CoreState({this.conn = Conn.connecting, this.state, this.error, this.session = 0});

  final Conn conn;
  final pb.State? state;
  final String? error;

  /// Bumps on every (re)connect: events may have been missed, so whoever
  /// caches core data reloads it.
  final int session;

  pb.SyncState get sync => state?.sync ?? pb.SyncState();

  CoreState copyWith({Conn? conn, pb.State? state, String? error, int? session, bool clearError = false}) =>
      CoreState(conn: conn ?? this.conn, state: state ?? this.state, error: clearError ? null : error ?? this.error, session: session ?? this.session);

  @override
  List<Object?> get props => [conn, state, error, session];
}

/// The connection to the core and its one Events stream; [events] survives
/// reconnects.
class CoreCubit extends Cubit<CoreState> {
  CoreCubit(this._launcher) : super(const CoreState());

  final CoreLauncher _launcher;
  CoreClient? _client;
  StreamSubscription<pb.Event>? _watch;
  Timer? _retry;
  int _failures = 0;
  final _events = StreamController<pb.Event>.broadcast();

  Stream<pb.Event> get events => _events.stream;

  pb.CellarClient get api {
    final c = _client;
    if (c == null) throw StateError('not connected');
    return c.api;
  }

  Future<void> connect() async {
    _retry?.cancel();
    emit(state.copyWith(conn: Conn.connecting));
    try {
      await _watch?.cancel();
      await _client?.close();
      _client = await CoreClient.connect(_launcher);
      final st = await api.getState(pb.Empty());
      _failures = 0;
      _listen();
      emit(state.copyWith(conn: Conn.ready, state: st, session: state.session + 1, clearError: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(conn: Conn.failed, error: errorText(e)));
      _reconnectLater();
    }
  }

  void _listen() {
    _watch = api
        .events(pb.Empty())
        .listen(
          (ev) {
            if (ev.kind == pb.Event_Kind.SYNC || ev.kind == pb.Event_Kind.SERVERS) unawaited(refreshState());
            _events.add(ev);
          },
          onError: (_) => _lost(),
          onDone: _lost,
          cancelOnError: true,
        );
  }

  void _lost() {
    if (isClosed) return;
    emit(state.copyWith(conn: Conn.failed, error: tr('No connection to the core', 'Нет связи с ядром')));
    _reconnectLater();
  }

  void _reconnectLater() {
    _retry?.cancel();
    final delay = Duration(seconds: min(30, 1 << min(_failures, 5)));
    _failures++;
    _retry = Timer(delay, () {
      if (!isClosed && state.conn == Conn.failed) connect();
    });
  }

  Future<void> refreshState() async {
    try {
      final st = await api.getState(pb.Empty());
      if (!isClosed) emit(state.copyWith(state: st));
    } catch (_) {}
  }

  void adoptSync(pb.SyncState s) => emit(state.copyWith(state: (state.state ?? pb.State()).deepCopy()..sync = s));

  @override
  Future<void> close() async {
    _retry?.cancel();
    await _watch?.cancel();
    await _events.close();
    await _client?.close();
    return super.close();
  }
}
