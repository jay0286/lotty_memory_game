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
import 'stage_config.dart';

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
  double _previewDuration = 2.0; // Will be set from stage config

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

    // Load stages
    await StageManager.instance.loadStages();

    // Load and add background
    await _loadBackground();

    // Initialize UI first
    await _initializeUI();

    // Initialize cards based on current stage
    await _initializeCards();

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

  /// Initialize cards based on current stage configuration
  Future<void> _initializeCards() async {
    final stage = StageManager.instance.currentStage;
    final random = Random();

    // Set preview duration from stage config
    _previewDuration = stage.previewDuration;

    // Generate card values (matching group IDs)
    final cardValues = <int>[];
    for (int i = 1; i <= stage.pairs; i++) {
      cardValues.add(i);
      cardValues.add(i);
    }
    cardValues.shuffle();

    // Assign category groups and categories to each pair
    // Step 1: Group available categories by their group type
    final categoryGroups = <CardCategoryGroup, List<CardCategory>>{};
    for (final category in stage.categories) {
      categoryGroups.putIfAbsent(category.group, () => []).add(category);
    }

    // Step 2: For each pair, assign a group and then random categories from that group
    final pairGroupAssignments = <int, CardCategoryGroup>{};
    final cardCategoryAssignments = <int, CardCategory>{}; // card index -> category

    for (int pairId = 1; pairId <= stage.pairs; pairId++) {
      // Pick a random group from available groups
      final availableGroups = categoryGroups.keys.toList();
      final selectedGroup = availableGroups[random.nextInt(availableGroups.length)];
      pairGroupAssignments[pairId] = selectedGroup;
    }

    // Step 3: Assign categories to each individual card
    for (int i = 0; i < stage.totalCards; i++) {
      final pairId = cardValues[i];
      final group = pairGroupAssignments[pairId]!;
      final categoriesInGroup = categoryGroups[group]!;

      // Each card in the pair can have a different category from the same group
      final category = categoriesInGroup[random.nextInt(categoriesInGroup.length)];
      cardCategoryAssignments[i] = category;
    }

    // Get tube pig sprites
    final tubePigSprites = assetManager.getTubePigSprites();
    if (tubePigSprites.isEmpty) {
      return;
    }

    // Calculate card layout with responsive sizing
    final columns = 4;
    final cardSize = size.x / 4.5; // Card size is 1/5 of screen width (allowing space for gaps)
    final cardSpacing = size.x / 5; // Spacing between card centers
    final startX = (size.x - (columns - 1) * cardSpacing) / 2;
    final rowSpacing = cardSize * 1.5; // Vertical spacing
    final startY = size.y * 0.25; // Start at 25% from top

    // Create cards
    for (int i = 0; i < stage.totalCards; i++) {
      final pairId = cardValues[i];
      final category = cardCategoryAssignments[i]!;
      final frontSprites = assetManager.getSpritesForCategory(category);

      if (frontSprites.isEmpty) {
        continue;
      }

      final card = PigCard(
        backSprite: tubePigSprites[i % tubePigSprites.length],
        frontSprite: frontSprites[(pairId - 1) % frontSprites.length],
        cardValue: pairId,
        position: Vector2(
          startX + (i % columns) * cardSpacing,
          startY + (i ~/ columns) * rowSpacing,
        ),
        size: Vector2(cardSize, cardSize),
        onTap: _onCardTapped,
      );
      _cards.add(card);
      add(card);
    }

    // Initialize game state with stage settings
    gameState = GameStateManager(
      totalPairs: stage.pairs,
      onScoreChanged: () {
        _scoreDisplay.updateScore(gameState.score);
      },
      onLivesChanged: () {
        _livesDisplay.updateLives(gameState.lives);
      },
      onGameOver: () {
        _showGameOverScreen(false);
      },
      onGameWon: () {
        _showGameOverScreen(true);
      },
    );

    // Set lives from stage config
    gameState.maxLives = stage.lives;
    gameState.lives = stage.lives;
    _livesDisplay.updateLives(stage.lives);

    // Start preview after cards are created
    _startPreview();
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
    // Create score display (top left)
    _scoreDisplay = ScoreDisplay(
      position: Vector2(20, 20),
    );
    add(_scoreDisplay);

    // Create lives display (top right)
    _livesDisplay = LivesDisplay(
      position: Vector2(size.x - 20, 20),
      maxLives: 5,
    );
    add(_livesDisplay);
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
    } else {
      // No match - flip cards back
      _firstSelectedCard!.flipToFaceDown();
      _secondSelectedCard!.flipToFaceDown();
      gameState.loseLife();
    }

    // Reset selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;
  }

  /// Show game over screen
  void _showGameOverScreen(bool isWin) {
    String message;
    if (isWin) {
      if (StageManager.instance.hasNextStage) {
        final nextStage = StageManager.instance.currentStageNumber + 1;
        message = 'Press R for Stage $nextStage';
      } else {
        message = 'All Stages Complete!\nPress R to Restart';
      }
    } else {
      message = 'Press R to Retry';
    }

    _gameOverOverlay = GameOverOverlay(
      isWin: isWin,
      finalScore: gameState.score,
      gameSize: size,
      onRestart: _restartGame,
      customMessage: message,
    )..priority = 200; // Draw on top of everything
    add(_gameOverOverlay!);
  }

  /// Restart the game (or move to next stage)
  void _restartGame() {
    // Remove game over overlay
    if (_gameOverOverlay != null) {
      remove(_gameOverOverlay!);
      _gameOverOverlay = null;
    }

    // If won and there's a next stage, advance
    if (gameState.state == GameState.gameWon &&
        StageManager.instance.hasNextStage) {
      StageManager.instance.nextStage();
      _loadNextStage();
    } else if (gameState.state == GameState.gameOver) {
      // If game over, reset to first stage
      StageManager.instance.reset();
      _loadNextStage();
    } else {
      // Otherwise just restart current stage
      _loadNextStage();
    }
  }

  /// Load next stage (or restart current stage)
  void _loadNextStage() {
    // Remove all cards
    for (final card in _cards) {
      remove(card);
    }
    _cards.clear();

    // Reset selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;
    _isProcessingMatch = false;
    _matchCheckTimer = 0.0;
    _shufflingTimer = 0.0;
    _previewTimer = 0.0;

    // Reinitialize cards with new stage config
    _initializeCards();
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
