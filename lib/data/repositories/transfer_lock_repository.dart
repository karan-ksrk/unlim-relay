import 'dart:async';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Who is sending right now.
enum TransferLockOwner {
  /// A transfer started from the app's UI.
  app,

  /// A scheduled run in the background engine.
  schedule;

  static TransferLockOwner? tryParse(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// A database lease so only one transfer runs at a time, across the app
/// and the background engine. Holders renew it while they work; a holder
/// that dies loses it when it expires.
abstract interface class TransferLockRepository {
  /// Takes the lease unless someone else holds an unexpired one.
  Future<bool> tryAcquire(TransferLockOwner owner, {required DateTime now});

  /// Extends the lease if [owner] still holds it.
  Future<void> renew(TransferLockOwner owner, {required DateTime now});

  Future<void> release(TransferLockOwner owner);

  /// The current holder, or `null` when free.
  Future<TransferLockOwner?> holder({required DateTime now});
}

class DriftTransferLockRepository implements TransferLockRepository {
  DriftTransferLockRepository(this._db);

  final AppDatabase _db;

  static const _name = 'transfer';

  /// Holders renew well within this; see [renewEvery].
  static const ttl = Duration(minutes: 2);
  static const renewEvery = Duration(seconds: 30);

  @override
  Future<bool> tryAcquire(
    TransferLockOwner owner, {
    required DateTime now,
  }) async {
    // One statement, so two connections can't both win.
    final changed = await _db.customUpdate(
      'INSERT INTO transfer_locks (name, owner, expires_at_millis) '
      'VALUES (?1, ?2, ?3) '
      'ON CONFLICT (name) DO UPDATE SET owner = excluded.owner, '
      'expires_at_millis = excluded.expires_at_millis '
      'WHERE transfer_locks.expires_at_millis <= ?4 '
      'OR transfer_locks.owner = excluded.owner',
      variables: [
        Variable.withString(_name),
        Variable.withString(owner.name),
        Variable.withInt(now.add(ttl).millisecondsSinceEpoch),
        Variable.withInt(now.millisecondsSinceEpoch),
      ],
      updates: {_db.transferLocks},
    );
    return changed > 0;
  }

  @override
  Future<void> renew(TransferLockOwner owner, {required DateTime now}) async {
    await (_db.update(
      _db.transferLocks,
    )..where((t) => t.name.equals(_name) & t.owner.equals(owner.name))).write(
      TransferLocksCompanion(
        expiresAtMillis: Value(now.add(ttl).millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> release(TransferLockOwner owner) async {
    await (_db.delete(
      _db.transferLocks,
    )..where((t) => t.name.equals(_name) & t.owner.equals(owner.name))).go();
  }

  @override
  Future<TransferLockOwner?> holder({required DateTime now}) async {
    final row = await (_db.select(
      _db.transferLocks,
    )..where((t) => t.name.equals(_name))).getSingleOrNull();
    if (row == null || row.expiresAtMillis <= now.millisecondsSinceEpoch) {
      return null;
    }
    return TransferLockOwner.tryParse(row.owner);
  }
}

/// Another transfer holds the lock.
class TransferBusyException implements Exception {
  const TransferBusyException(this.holder);

  final TransferLockOwner? holder;

  @override
  String toString() => 'TransferBusyException(${holder?.name})';
}

extension TransferLockHolding on TransferLockRepository {
  /// Runs [action] while holding the lock for [owner], renewing it until
  /// [action] finishes. Throws [TransferBusyException] if someone else holds
  /// it.
  Future<T> whileHolding<T>(
    TransferLockOwner owner,
    Future<T> Function() action, {
    DateTime Function() clock = DateTime.now,
  }) async {
    if (!await tryAcquire(owner, now: clock())) {
      throw TransferBusyException(await holder(now: clock()));
    }
    final renewal = Timer.periodic(
      DriftTransferLockRepository.renewEvery,
      (_) => unawaited(renew(owner, now: clock())),
    );
    try {
      return await action();
    } finally {
      renewal.cancel();
      await release(owner);
    }
  }
}
