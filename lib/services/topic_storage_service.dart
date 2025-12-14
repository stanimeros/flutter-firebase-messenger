import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/topic_model.dart';

class TopicStorageService {
  static const _topicsKey = 'saved_topics';

  Future<List<TopicModel>> getTopics(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    final topicsJson = prefs.getStringList(_topicsKey) ?? [];
    final allTopics = topicsJson
        .map((json) => TopicModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
    return allTopics.where((topic) => topic.appId == appId).toList();
  }

  Future<void> saveTopic(TopicModel topic) async {
    final prefs = await SharedPreferences.getInstance();
    final topics = await getAllTopics();
    final existingIndex = topics.indexWhere((t) => t.id == topic.id);
    if (existingIndex >= 0) {
      topics[existingIndex] = topic;
    } else {
      topics.add(topic);
    }
    final topicsJson = topics.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_topicsKey, topicsJson);
  }

  Future<void> deleteTopic(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final topics = await getAllTopics();
    topics.removeWhere((t) => t.id == topicId);
    final topicsJson = topics.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_topicsKey, topicsJson);
  }

  Future<List<TopicModel>> getAllTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final topicsJson = prefs.getStringList(_topicsKey) ?? [];
    return topicsJson
        .map((json) => TopicModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }
}
