import 'topic_model.dart';

class ConditionModel {
  final String id;
  final String name;
  final String operator; // 'AND' or 'OR'
  final List<String> topicIds; // IDs of topics in this condition
  final List<String> conditionIds; // IDs of nested conditions
  final DateTime createdAt;

  ConditionModel({
    required this.id,
    required this.name,
    required this.operator,
    List<String>? topicIds,
    List<String>? conditionIds,
    required this.createdAt,
  })  : topicIds = topicIds ?? [],
        conditionIds = conditionIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'operator': operator,
      'topicIds': topicIds,
      'conditionIds': conditionIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      operator: json['operator'] as String,
      topicIds: (json['topicIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      conditionIds: (json['conditionIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ConditionModel copyWith({
    String? id,
    String? name,
    String? operator,
    List<String>? topicIds,
    List<String>? conditionIds,
    DateTime? createdAt,
  }) {
    return ConditionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      operator: operator ?? this.operator,
      topicIds: topicIds ?? this.topicIds,
      conditionIds: conditionIds ?? this.conditionIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Build FCM condition string
  String buildConditionString(List<TopicModel> allTopics, List<ConditionModel> allConditions) {
    final parts = <String>[];
    
    // Add topics
    for (final topicId in topicIds) {
      final topic = allTopics.firstWhere((t) => t.id == topicId, orElse: () => TopicModel(id: '', name: '', createdAt: DateTime.now()));
      if (topic.id.isNotEmpty) {
        parts.add("'${topic.name}' in topics");
      }
    }
    
    // Add nested conditions
    for (final conditionId in conditionIds) {
      final condition = allConditions.firstWhere((c) => c.id == conditionId, orElse: () => ConditionModel(id: '', name: '', operator: 'AND', createdAt: DateTime.now()));
      if (condition.id.isNotEmpty) {
        final nestedCondition = condition.buildConditionString(allTopics, allConditions);
        if (nestedCondition.isNotEmpty) {
          parts.add('($nestedCondition)');
        }
      }
    }
    
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    
    final op = operator == 'AND' ? '&&' : '||';
    return parts.join(' $op ');
  }
}

