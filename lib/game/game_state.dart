/// Game state enum
import 'package:flutter/foundation.dart';

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
  int _foundPairs = 0;
  int _score = 0;
  int _lives = 5;
  GameState _state = GameState.shuffling;

  // Callbacks
  final VoidCallback? onScoreChanged;
  final VoidCallback? onLivesChanged;
  final VoidCallback? onGameOver;
  final VoidCallback? onGameWon;

  GameStateManager({
    required this.totalPairs,
    this.onScoreChanged,
    this.onLivesChanged,
    this.onGameOver,
    this.onGameWon,
  });

  GameState get state => _state;
  int get score => _score;
  int get lives => _lives;
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
    addScore(100); // 100 points per match

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
    _lives = 5;
    _state = GameState.shuffling;

    onScoreChanged?.call();
    onLivesChanged?.call();
  }
}
