/// Game state enum
library;
import 'package:flutter/foundation.dart';
import '../config/game_config.dart';

enum GameState {
  shuffling,
  preview,
  playing,
  gameOver,
  gameWon,
}

/// Manages the game state and logic
class GameStateManager {
  int totalPairs;
  int maxLives = 5;
  int maxHints = 0;
  int _foundPairs = 0;
  int _score = 0;
  int _lives = 5;
  int _hints = 0;
  GameState _state = GameState.shuffling;

  // Callbacks
  final VoidCallback? onScoreChanged;
  final VoidCallback? onLivesChanged;
  final VoidCallback? onHintsChanged;
  final VoidCallback? onGameOver;
  final VoidCallback? onGameWon;

  GameStateManager({
    required this.totalPairs,
    this.onScoreChanged,
    this.onLivesChanged,
    this.onHintsChanged,
    this.onGameOver,
    this.onGameWon,
  });

  GameState get state => _state;
  int get score => _score;
  int get lives => _lives;
  set lives(int value) {
    _lives = value;
    onLivesChanged?.call();
  }
  int get hints => _hints;
  set hints(int value) {
    _hints = value;
    onHintsChanged?.call();
  }
  int get foundPairs => _foundPairs;

  /// Add score for a successful match
  void addScore(int points) {
    _score += points;
    onScoreChanged?.call();
  }

  /// Lose a life for a failed match
  void loseLife() {
    if (_lives > 0) {
      _lives--;
      onLivesChanged?.call();

      if (_lives <= 0) {
        _state = GameState.gameOver;
        onGameOver?.call();
      }
    }
  }

  /// Register a successful match
  void registerMatch() {
    if (!isGameActive) return;

    _foundPairs++;
    addScore(GameConfig.scorePerMatch);

    if (_foundPairs >= totalPairs) {
      _state = GameState.gameWon;
      onGameWon?.call();
    }
  }

  /// Check if game is active
  bool get isGameActive => _state == GameState.playing;

  void startPreview() {
    if (_state == GameState.shuffling) {
      _state = GameState.preview;
    }
  }

  void startGame() {
    if (_state == GameState.preview) {
      _state = GameState.playing;
    }
  }

  /// Reset game state
  void reset() {
    _foundPairs = 0;
    _score = 0;
    _lives = maxLives;
    _hints = maxHints;
    _state = GameState.shuffling;

    onScoreChanged?.call();
    onLivesChanged?.call();
    onHintsChanged?.call();
  }
}
