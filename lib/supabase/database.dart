import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'base/auth.dart';
import 'base/current_user.dart';
import 'core/team_requests.dart';
import 'core/team_users.dart';
import 'core/teams.dart';
import 'frc/districts.dart';
import 'frc/events.dart';
import 'frc/matches.dart';
import 'frc/seasons.dart';
import 'frc/teams.dart';
import 'scouting/questions.dart';

class Database {
  final SupabaseClient? supabase;

  final AuthRepository auth;
  final CurrentUserRepository currentUser;

  final TeamsRepository teams;
  final TeamUsersRepository teamUsers;
  final TeamRequestsRepository teamRequests;

  final FrcSeasonsRepository frcSeasons;
  final FrcTeamsRepository frcTeams;
  final FrcDistrictsRepository frcDistricts;
  final FrcEventsRepository frcEvents;
  final FrcMatchesRepository frcMatches;

  final QuestionsRepository questions;

  Database({
    this.supabase,
    required this.auth,
    required this.currentUser,
    required this.teams,
    required this.teamUsers,
    required this.teamRequests,
    required this.frcSeasons,
    required this.frcTeams,
    required this.frcDistricts,
    required this.frcEvents,
    required this.frcMatches,
    required this.questions,
  });

  Database.supabase(SupabaseClient supabase)
      : this(
          supabase: supabase,
          auth: AuthRepository.supabase(supabase),
          currentUser: CurrentUserRepository.supabase(supabase),
          teams: TeamsRepository.supabase(supabase),
          teamUsers: TeamUsersRepository.supabase(supabase),
          teamRequests: TeamRequestsRepository.supabase(supabase),
          frcSeasons: FrcSeasonsRepository.supabase(supabase),
          frcTeams: FrcTeamsRepository.supabase(supabase),
          frcDistricts: FrcDistrictsRepository.supabase(supabase),
          frcEvents: FrcEventsRepository.supabase(supabase),
          frcMatches: FrcMatchesRepository.supabase(supabase),
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
    if (forceOrigin || (cache[key]?.isExpired(expiration) ?? true)) {
      final data = await origin(key);
      if (data != null) {
        cache[key] = CacheEntry(data);
      } else {
        cache.remove(key);
      }
    }

    return cache[key]?.data;
  }

  void clear() => cache.clear();
}

class CacheAll<K, V> extends Cache<K, V> {
  @protected
  final Future<Iterable<V>> Function() originAll;
  @protected
  final K Function(V) key;
  @protected
  CacheEntry<void>? allValues;

  CacheAll({
    required super.expiration,
    required super.origin,
    required this.originAll,
    required this.key,
  });

  Future<List<V>> getAll({
    required bool forceOrigin,
  }) async {
    if (forceOrigin ||
        (allValues?.isExpired(expiration) ?? true) ||
        cache.values.where((e) => !e.isExpired(expiration)).isNotEmpty) {
      final data = await originAll();
      cache
        ..clear()
        ..addEntries(
          data.map(
            (value) => MapEntry(key(value), CacheEntry(value)),
          ),
        );
      allValues = CacheEntry(null);
    }

    return UnmodifiableListView(
      cache.values.map(
        (entry) => entry.data,
      ),
    );
  }
}

class CacheEntry<V> {
  final V data;
  final DateTime timestamp;

  CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration expiration) =>
      DateTime.now().isAfter(timestamp.add(expiration));
}

typedef Uuid = String;
typedef JsonObject = Map<String, dynamic>;
typedef JsonList = List<Map<String, dynamic>>;

extension JsonParseObject on JsonObject {
  T parse<T>(T Function(JsonObject) fromJson) => fromJson(this);
}

extension JsonParseList on JsonList {
  List<T> parse<T>(T Function(JsonObject) fromJson) => map(fromJson).toList();
}
