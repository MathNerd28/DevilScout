import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database.dart';
import '../../model/scouting.dart';

class QuestionsRepository {
  final Cache<(int, ScoutingCategory), List<QuestionNode>> _questionsCache;
  final Cache<(int, ScoutingCategory), Map<String, String>> _detailsCache;

  QuestionsRepository.supabase(SupabaseClient supabase)
      : this(QuestionsService(supabase));

  QuestionsRepository(QuestionsService service)
      : _questionsCache = Cache(
          expiration: const Duration(minutes: 30),
          origin: (key) => service.getQuestions(
            season: key.$1,
            category: key.$2,
          ),
        ),
        _detailsCache = Cache(
          expiration: const Duration(minutes: 30),
          origin: (key) => service.getDetails(
            season: key.$1,
            category: key.$2,
          ),
        );

  Future<List<QuestionNode>?> getQuestions({
    required int season,
    required ScoutingCategory category,
    bool forceOrigin = false,
  }) =>
      _questionsCache.get(
        key: (season, category),
        forceOrigin: forceOrigin,
      );

  Future<Map<String, String>?> getDetails({
    required int season,
    required ScoutingCategory category,
    bool forceOrigin = false,
  }) =>
      _detailsCache.get(
        key: (season, category),
        forceOrigin: forceOrigin,
      );
}

class QuestionsService {
  final SupabaseClient supabase;

  QuestionsService(this.supabase);

  Future<List<QuestionNode>?> getQuestions({
    required int season,
    required ScoutingCategory category,
  }) async {
    final data = await supabase
        .from('questions')
        .select()
        .eq('season', season)
        .eq('category', category.value);
    final nodes = data.map(QuestionNode.fromJson);
    return nodes.isEmpty ? null : nodes.toList();
  }

  Future<Map<String, String>> getDetails({
    required int season,
    required ScoutingCategory category,
  }) async {
    final directory = '$season/${category.value}';

    final files =
        await supabase.storage.from('question-info').list(path: directory);
    final questionIds = files.map((file) => file.name);

    final data = await Future.wait(
      questionIds.map(
        (id) => supabase.storage
            .from('question-info')
            .download('$directory/$id')
            .then(utf8.decode),
      ),
    );

    return Map.fromIterables(questionIds, data);
  }
}