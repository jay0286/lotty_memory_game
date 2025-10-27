import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/asset_manager.dart';
import '../managers/difficulty_manager.dart';

/// Configuration for a single stage
class StageConfig {
  final int id;
  final String name;
  final int pairs;
  final List<CardCategory> categories;
  final int lives;
  final int hints;
  final double previewDuration;

  StageConfig({
    required this.id,
    required this.name,
    required this.pairs,
    required this.categories,
    required this.lives,
    required this.hints,
    required this.previewDuration,
  });

  factory StageConfig.fromJson(Map<String, dynamic> json) {
    return StageConfig(
      id: json['id'] as int,
      name: json['name'] as String,
      pairs: json['pairs'] as int,
      categories: (json['categories'] as List)
          .map((cat) => CardCategory.values.firstWhere(
                (e) => e.name == cat,
              ))
          .toList(),
      lives: json['lives'] as int,
      hints: json['hints'] as int,
      previewDuration: (json['previewDuration'] as num).toDouble(),
    );
  }

  int get totalCards => pairs * 2;
}

/// Manages all game stages
class StageManager {
  static StageManager? _instance;
  static StageManager get instance => _instance ??= StageManager._();
  StageManager._();

  List<StageConfig> _stages = [];
  int _currentStageIndex = 0;

  /// Load stages from JSON file
  Future<void> loadStages() async {
    final jsonString = await rootBundle.loadString('assets/stages.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    _stages = (jsonData['stages'] as List)
        .map((stage) => StageConfig.fromJson(stage as Map<String, dynamic>))
        .toList();
  }

  /// Get current stage configuration
  StageConfig get currentStage => _stages[_currentStageIndex];

  /// Check if there's a next stage
  bool get hasNextStage => _currentStageIndex < _stages.length - 1;

  /// Move to next stage
  void nextStage() {
    if (hasNextStage) {
      _currentStageIndex++;
    }
  }

  /// Reset to first stage (or difficulty-based starting stage)
  void reset() {
    final startStage = DifficultyManager().startStage;
    // startStage는 1-based이므로 index는 startStage - 1
    _currentStageIndex = startStage - 1;
  }

  /// Set to specific stage (1-based stage number)
  void setStage(int stageNumber) {
    if (stageNumber >= 1 && stageNumber <= _stages.length) {
      _currentStageIndex = stageNumber - 1;
    }
  }

  /// Get current stage number (1-based)
  int get currentStageNumber => _currentStageIndex + 1;

  /// Get total number of stages
  int get totalStages => _stages.length;
}
