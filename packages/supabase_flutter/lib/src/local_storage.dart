import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabasePersistSessionKey = 'SUPABASE_PERSIST_SESSION_KEY';

/// LocalStorage is used to persist the user session in the device.
///
/// See also:
///
///   * [SupabaseAuth], the instance used to manage authentication
///   * [EmptyLocalStorage], used to disable session persistence
///   * [HiveLocalStorage], that implements Hive as storage method
abstract class LocalStorage {
  const LocalStorage({
    required this.initialize,
    required this.hasAccessToken,
    required this.accessToken,
    required this.persistSession,
    required this.removePersistedSession,
  });

  /// Initialize the storage to persist session.
  final Future<void> Function() initialize;

  /// Check if there is a persisted session.
  final Future<bool> Function() hasAccessToken;

  /// Get the access token from the current persisted session.
  final Future<String?> Function() accessToken;

  /// Remove the current persisted session.
  final Future<void> Function() removePersistedSession;

  /// Persist a session in the device.
  final Future<void> Function(String) persistSession;
}

/// A [LocalStorage] implementation that does nothing. Use this to
/// disable persistence.
class EmptyLocalStorage extends LocalStorage {
  /// Creates a [LocalStorage] instance that disables persistence
  const EmptyLocalStorage()
      : super(
          initialize: _initialize,
          hasAccessToken: _hasAccessToken,
          accessToken: _accessToken,
          removePersistedSession: _removePersistedSession,
          persistSession: _persistSession,
        );

  static Future<void> _initialize() async {}
  static Future<bool> _hasAccessToken() => Future.value(false);
  static Future<String?> _accessToken() => Future.value();
  static Future<void> _removePersistedSession() async {}
  static Future<void> _persistSession(_) async {}
}

/// A [LocalStorage] implementation that implements Hive as the
/// storage method.
class HiveLocalStorage extends LocalStorage {
  /// Creates a LocalStorage instance that implements the Hive Database
  const HiveLocalStorage()
      : super(
          initialize: _initialize,
          hasAccessToken: _hasAccessToken,
          accessToken: _accessToken,
          removePersistedSession: _removePersistedSession,
          persistSession: _persistSession,
        );

  /// The encryption key used by Hive. If null, the box is not encrypted
  ///
  /// This value should not be redefined in runtime, otherwise the user may
  /// not be fetched correctly
  ///
  /// See also:
  ///
  ///   * <https://docs.hivedb.dev/#/advanced/encrypted_box?id=encrypted-box>
  static String? encryptionKey;

  static const String _boxName = "supabase_authentication";

  static Box<String> get box =>
      Hive.box(name: _boxName, encryptionKey: encryptionKey);

  static Future<void> _initialize() async {
    box.isOpen;
  }

  static Future<bool> _hasAccessToken() {
    return Future.value(
      box.containsKey(
        supabasePersistSessionKey,
      ),
    );
  }

  static Future<String?> _accessToken() {
    return Future.value(box.get(supabasePersistSessionKey));
  }

  static Future<void> _removePersistedSession() {
    box.delete(supabasePersistSessionKey);
    return Future.value();
  }

  static Future<void> _persistSession(String persistSessionString) async {
    // Flush after X amount of writes
    box.put(supabasePersistSessionKey, persistSessionString);
    return Future.value();
  }
}

/// local storage to store pkce flow code verifier.
class HiveGotrueAsyncStorage implements GotrueAsyncStorage {
  static const String _boxName = "gotrue";

  Box<String> get box => Hive.box(name: _boxName);

  @override
  Future<String?> getItem({required String key}) {
    return Future.value(box.get(key));
  }

  @override
  Future<void> removeItem({required String key}) {
    box.delete(key);
    return Future.value();
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    box.put(key, value);
    return Future.value();
  }
}
