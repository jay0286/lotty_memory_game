import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/asset_manager.dart';
import '../components/pig_card.dart';
import '../components/ui/score_display.dart';
import '../components/ui/lives_display.dart';
import '../components/ui/game_over_overlay.dart';
import 'game_state.dart';

class LottyMemoryGame extends FlameGame with KeyboardEvents {
  late AssetManager assetManager;
  late GameStateManager gameState;

  final List<PigCard> _cards = [];
  PigCard? _firstSelectedCard;
  PigCard? _secondSelectedCard;
  bool _isProcessingMatch = false;
  double _matchCheckTimer = 0.0;

  double _shufflingTimer = 0.0;
  final double _shufflingDuration = 1.0;
  double _previewTimer = 0.0;
  final double _previewDuration = 2.0;

  // UI components
  late ScoreDisplay _scoreDisplay;
  late LivesDisplay _livesDisplay;
  GameOverOverlay? _gameOverOverlay;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue background

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize asset manager
    assetManager = AssetManager.instance;
    await assetManager.loadAssets();

    // Load and add background
    await _loadBackground();

    // Initialize UI first
    await _initializeUI();

    final numberSprites = assetManager.getNumberCardSprites();
    print('Loaded ${numberSprites.length} number card sprites');

    final diceSprites = assetManager.getDiceCardSprites();
    print('Loaded ${diceSprites.length} dice card sprites');

    final tubePigSprites = assetManager.getTubePigSprites();
    print('Loaded ${tubePigSprites.length} tube pig sprites');

    // Create test cards with matching pairs
    if (numberSprites.isNotEmpty &&
        diceSprites.isNotEmpty &&
        tubePigSprites.isNotEmpty) {

      // Create 4 pairs (8 cards total) for matching game
      final cardValues = [1, 1, 2, 2, 3, 3, 4, 4]..shuffle();

      // Update game state with correct pair count
      gameState = GameStateManager(
        totalPairs: 4,
      onScoreChanged: () {
        print('Score: ${gameState.score}');
        _scoreDisplay.updateScore(gameState.score);
      },
      onLivesChanged: () {
        print('L2ives: ${gameState.lives}');
        _livesDisplay.updateLives(gameState.lives);
      },
      onGameOver: () {
        print('Game Over!');
        _showGameOverScreen(false);
      },
      onGameWon: () {
        print('You Won!');
        _showGameOverScreen(true);
      },
      );
      // Decide which sprite set to use for this game
      final random = Random();

      for (int i = 0; i < 8; i++) {
      final useDiceSprites = random.nextBool();
      final frontSprites =
          useDiceSprites ? diceSprites : numberSprites;
        print('Using ${useDiceSprites ? "dice" : "number"} sprites for this game.');
        final card = PigCard(
          backSprite: tubePigSprites[i % tubePigSprites.length],
          frontSprite:
              frontSprites[(cardValues[i] - 1) % frontSprites.length],
          cardValue: cardValues[i],
          position: Vector2(
            200 + (i % 4) * 150,
            200 + (i ~/ 4) * 180,
          ),
          size: Vector2(120, 120),
          onTap: _onCardTapped,
        );
        _cards.add(card);
        add(card);
      }

      print('Created ${_cards.length} cards with ${gameState.totalPairs} pairs');

      // Start preview after caxrds are created
      _startPreview();
    }

  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState.state == GameState.shuffling) {
      _shufflingTimer += dt;
      if (_shufflingTimer >= _shufflingDuration) {
        gameState.startPreview();
        _startPreview();
      }
    } else if (gameState.state == GameState.preview) {
      _previewTimer += dt;
      if (_previewTimer >= _previewDuration) {
        _endPreview();
      }
    }

    // Card movement and collision should happen during shuffling, preview, and playing
    if (gameState.state == GameState.shuffling ||
        gameState.state == GameState.preview ||
        gameState.state == GameState.playing) {
      // Handle boundary collisions for all cards
      for (final card in _cards) {
        card.handleBoundary(size);
      }

      // Handle card-to-card collisions
      for (int i = 0; i < _cards.length; i++) {
        for (int j = i + 1; j < _cards.length; j++) {
          if (_cards[i].collidesWith(_cards[j])) {
            _cards[i].resolveCollision(_cards[j]);
          }
        }
      }
    }

    // Match checking should only happen during playing
    if (gameState.state == GameState.playing && _isProcessingMatch) {
      _matchCheckTimer += dt;
      if (_matchCheckTimer >= 1.0) {
        _checkMatch();
        _matchCheckTimer = 0.0;
        _isProcessingMatch = false;
      }
    }
  }

  Future<void> _loadBackground() async {
    final backgroundSprite = await loadSprite('background_pool.png');

    final spriteSize = backgroundSprite.originalSize;
    final screenSize = size;

    final scaleX = screenSize.x / spriteSize.x;
    final scaleY = screenSize.y / spriteSize.y;
    final scale = max(scaleX, scaleY);

    final newSize = spriteSize * scale;
    final newPosition = (screenSize - newSize) / 2;

    final background = SpriteComponent(
      sprite: backgroundSprite,
      size: newSize,
      position: newPosition,
      priority: -1, // Draw behind everything
    );

    add(background);
  }

  /// Start the card preview
  void _startPreview() {
    _previewTimer = 0.0;
    for (final card in _cards) {
      card.flipToFaceUp();
    }
  }

  /// End the card preview and start the game
  void _endPreview() {
    gameState.startGame();
    for (final card in _cards) {
      card.flipToFaceDown();
    }
  }

  /// Initialize UI components
  Future<void> _initializeUI() async {
    print('Initializing UI components...');

    // Create score display (top left)
    _scoreDisplay = ScoreDisplay(
      position: Vector2(20, 20),
    ); // Draw on top
    add(_scoreDisplay);
    print('Score display added at (20, 20)');

    // Create lives display (top right)
    _livesDisplay = LivesDisplay(
      position: Vector2(size.x - 20, 20),
      maxLives: 5,
    ); // Draw on top
    add(_livesDisplay);
    print('Lives display added at (${size.x - 20}, 20)');
  }


  /// Handle card tap
  void _onCardTapped(PigCard card) {
    if (!gameState.isGameActive || _isProcessingMatch) return;
    if (card.state != CardState.faceDown) return;

    // Flip the card to face up
    card.flipToFaceUp();

    // Handle card selection
    if (_firstSelectedCard == null) {
      // First card selected
      _firstSelectedCard = card;
    } else if (_secondSelectedCard == null && card != _firstSelectedCard) {
      // Second card selected
      _secondSelectedCard = card;
      _isProcessingMatch = true;
    }
  }

  /// Check if two selected cards match
  void _checkMatch() {
    if (_firstSelectedCard == null || _secondSelectedCard == null) return;

    if (_firstSelectedCard!.cardValue == _secondSelectedCard!.cardValue) {
      // Match found!
      _firstSelectedCard!.setMatched();
      _secondSelectedCard!.setMatched();
      gameState.registerMatch();
      print('Match! Score: ${gameState.score}');
    } else {
      // No match - flip cards back
      _firstSelectedCard!.flipToFaceDown();
      _secondSelectedCard!.flipToFaceDown();
      gameState.loseLife();
      print('No match. Lives: ${gameState.lives}');
    }

    // Reset selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;
  }

  /// Show game over screen
  void _showGameOverScreen(bool isWin) {
    _gameOverOverlay = GameOverOverlay(
      isWin: isWin,
      finalScore: gameState.score,
      gameSize: size,
      onRestart: _restartGame,
    )..priority = 200; // Draw on top of everything
    add(_gameOverOverlay!);
  }

  /// Restart the game
  void _restartGame() {
    // Remove game over overlay
    if (_gameOverOverlay != null) {
      remove(_gameOverOverlay!);
      _gameOverOverlay = null;
    }

    // Reset game state
    gameState.reset();

    // Reset all cards
    for (final card in _cards) {
      card.reset();
    }

    // Reset selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;
    _isProcessingMatch = false;
    _matchCheckTimer = 0.0;
    _shufflingTimer = 0.0;
    _previewTimer = 0.0;
  }

  /// Handle keyboard input
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        // Restart on 'R' key
        if (gameState.state != GameState.playing) {
          _restartGame();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
