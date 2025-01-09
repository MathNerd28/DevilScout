import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';
import 'core/team_requests.dart';
import 'core/teams.dart';
import 'core/users.dart';
import 'frc/districts.dart';
import 'frc/events.dart';
import 'frc/seasons.dart';
import 'frc/teams.dart';
import 'scouting/questions.dart';

class Database {
  final AuthRepository auth;

  final UsersRepository users;
  final TeamsRepository teams;
  final TeamRequestsRepository teamRequests;

  final FrcSeasonsRepository frcSeasons;
  final FrcTeamsRepository frcTeams;
  final FrcDistrictsRepository frcDistricts;
  final FrcEventsRepository frcEvents;

  final QuestionsRepository questions;

  Database({
    required this.auth,
    required this.users,
    required this.teams,
    required this.teamRequests,
    required this.frcSeasons,
    required this.frcTeams,
    required this.frcDistricts,
    required this.frcEvents,
    required this.questions,
  });

  Database.supabase(SupabaseClient supabase)
      : this(
          auth: AuthRepository.supabase(supabase),
          users: UsersRepository.supabase(supabase),
          teams: TeamsRepository.supabase(supabase),
          teamRequests: TeamRequestsRepository.supabase(supabase),
          frcSeasons: FrcSeasonsRepository.supabase(supabase),
          frcTeams: FrcTeamsRepository.supabase(supabase),
          frcDistricts: FrcDistrictsRepository.supabase(supabase),
          frcEvents: FrcEventsRepository.supabase(supabase),
          questions: QuestionsRepository.supabase(supabase),
        );

  factory Database.of(BuildContext context) =>
      Provider.of<Database>(context, listen: false);

  static Future<void> initSupabase() async {
    const supabaseUrl = 'https://jlhplhsuiwwcmxrtbdhp.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsaHBsaHN1aXd3Y214cnRiZGhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU4MjA3ODQsImV4cCI6MjA0MTM5Njc4NH0.QKbKHdYoSGC71hrOaHYyJNIJWvwE4ehpNOWVJUYng0M';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

class Cache<K, V> {
  @protected
  final Map<K, CacheEntry<V>> cache = {};
  @protected
  final Future<V?> Function(K) origin;
  @protected
  final Duration expiration;

  Cache({
    required this.expiration,
    required this.origin,
  });

  Future<V?> get({
    required K key,
    required bool forceOrigin,
  }) async {
    final entry = cache[key];
    if (!forceOrigin && (entry?.isValid(expiration) ?? false)) {
      return entry!.data;
    }

    final data = await origin(key);
    if (data != null) {
      cache[key] = CacheEntry(data);
      return data;
    } else {
      cache.remove(key);
      return null;
    }
  }

  void clear() => cache.clear();
}

class CacheAll<K, V> extends Cache<K, V> {
  @protected
  final Future<Map<K, V>> Function() originAll;
  @protected
  CacheEntry<Null>? allValues;

  CacheAll({
    required super.expiration,
    required super.origin,
    required this.originAll,
  });

  Future<Map<K, V>> getAll({
    required bool forceOrigin,
  }) async {
    if (!forceOrigin &&
        (allValues?.isValid(expiration) ?? false) &&
        cache.values.where((e) => !e.isValid(expiration)).isEmpty) {
      return UnmodifiableMapView(cache.map(
        (key, value) => MapEntry(key, value.data),
      ));
    }

    final data = await originAll();
    cache
      ..clear()
      ..addAll(data.map(
        (key, value) => MapEntry(key, CacheEntry(value)),
      ));
    return UnmodifiableMapView(data);
  }
}

class CacheEntry<V> {
  final V data;
  final DateTime timestamp;

  CacheEntry(this.data) : timestamp = DateTime.now();

  bool isValid(Duration expiration) =>
      DateTime.now().isBefore(timestamp.add(expiration));
}

extension JsonParseObject on PostgrestMap {
  T parse<T>(T Function(Map<String, dynamic>) fromJson) => fromJson(this);
}

extension JsonParseList on PostgrestList {
  List<T>? parseToList<T>(T Function(Map<String, dynamic>) fromJson) =>
      isEmpty ? null : map(fromJson).toList();

  Map<K, V> parseToMap<K, V>(
          V Function(Map<String, dynamic>) fromJson, K Function(V) key) =>
      Map.fromEntries(
        map(fromJson).map(
          (value) => MapEntry(key(value), value),
        ),
      );
}
