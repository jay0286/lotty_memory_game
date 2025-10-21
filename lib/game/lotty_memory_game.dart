import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/asset_manager.dart';
import '../components/pig_card.dart';
import '../components/shadow_layer.dart';
import '../components/ui/lives_display.dart';
import '../components/ui/hint_display.dart';
import '../components/ui/game_over_overlay.dart';
import '../config/game_config.dart';
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

  final Random _random = Random();

  // Persistent values across stages
  int _currentLives = 0;
  int _currentHints = 0;

  // ValueNotifier for Flutter UI (deprecated - using GameStateManager now)
  final ValueNotifier<int> hintCountNotifier = ValueNotifier<int>(0);

  // Hint reveal state
  bool _isHintRevealing = false;
  double _hintRevealTimer = 0.0;

  // Penalty shuffle state
  bool _isShuffling = false;
  double _shuffleTimer = 0.0;
  final List<Vector2> _targetPositions = [];

  double _shufflingTimer = 0.0;
  final double _shufflingDuration = GameConfig.shufflingDuration;
  double _previewTimer = 0.0;
  double _previewDuration = 2.0; // Will be set from stage config

  // UI components
  late LivesDisplay _livesDisplay;
  late HintDisplay _hintDisplay;
  GameOverOverlay? _gameOverOverlay;

  // Shadow layer
  late ShadowLayer _shadowLayer;

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

    // Initialize shadow layer (low priority, renders first)
    _shadowLayer = ShadowLayer(cards: _cards);
    add(_shadowLayer);

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
      // Handle boundary collisions for all cards (only if collision enabled)
      for (final card in _cards) {
        if (card.isCollisionEnabled) {
          card.handleBoundary(size);
        }
      }

      // Handle card-to-card collisions (only if both cards have collision enabled)
      for (int i = 0; i < _cards.length; i++) {
        for (int j = i + 1; j < _cards.length; j++) {
          if (_cards[i].isCollisionEnabled &&
              _cards[j].isCollisionEnabled &&
              _cards[i].collidesWith(_cards[j])) {
            _cards[i].resolveCollision(_cards[j]);
          }
        }
      }
    }

    // Match checking should only happen during playing
    if (gameState.state == GameState.playing && _isProcessingMatch) {
      _matchCheckTimer += dt;
      if (_matchCheckTimer >= GameConfig.matchCheckDelay) {
        _checkMatch();
        _matchCheckTimer = 0.0;
        _isProcessingMatch = false;
      }
    }

    // Update hint reveal timer
    if (_isHintRevealing) {
      _hintRevealTimer += dt;
      if (_hintRevealTimer >= GameConfig.hintRevealDuration) {
        _endHintReveal();
      }
    }

    // Update penalty shuffle animation
    if (_isShuffling) {
      _shuffleTimer += dt;
      final progress = (_shuffleTimer / GameConfig.penaltyShuffleDuration).clamp(0.0, 1.0);

      // Update card positions with easing
      for (int i = 0; i < _cards.length; i++) {
        if (i < _targetPositions.length) {
          final startPos = _cards[i].position;
          final targetPos = _targetPositions[i];

          // Ease in-out cubic
          final t = progress < 0.5
              ? 4 * progress * progress * progress
              : 1 - pow(-2 * progress + 2, 3) / 2;

          _cards[i].position = Vector2(
            startPos.x + (targetPos.x - startPos.x) * t,
            startPos.y + (targetPos.y - startPos.y) * t,
          );
        }
      }

      if (_shuffleTimer >= GameConfig.penaltyShuffleDuration) {
        _endPenaltyShuffle();
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
    final columns = GameConfig.cardLayoutColumns;
    final cardSize = size.x * GameConfig.cardSizeFraction;
    final cardSpacing = size.x * GameConfig.cardSpacingFraction;
    final startX = (size.x - (columns - 1) * cardSpacing) / 2;
    final rowSpacing = cardSize * GameConfig.cardRowSpacingMultiplier;
    final startY = size.y * GameConfig.cardLayoutStartY;

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
      card.priority = 10; // Higher priority than shadow layer
      _cards.add(card);
      add(card);
    }

    // Initialize game state with stage settings
    gameState = GameStateManager(
      totalPairs: stage.pairs,
      onScoreChanged: () {
        // Score display removed
      },
      onLivesChanged: () {
        _livesDisplay.updateLives(gameState.lives);
      },
      onHintsChanged: () {
        _hintDisplay.updateHintCount(gameState.hints);
        hintCountNotifier.value = gameState.hints;
      },
      onGameOver: () {
        _showGameOverScreen(false);
      },
      onGameWon: () {
        _showGameOverScreen(true);
      },
    );

    // Set max values from stage config
    gameState.maxLives = stage.lives;
    gameState.maxHints = stage.hints;

    // Apply minimum guarantee logic: use previous value if higher, otherwise use stage minimum
    // If _currentLives is 0, it's the first stage, so use stage.lives
    if (_currentLives == 0) {
      gameState.lives = stage.lives;
      gameState.hints = stage.hints;
    } else {
      gameState.lives = _currentLives > stage.lives ? _currentLives : stage.lives;
      gameState.hints = _currentHints > stage.hints ? _currentHints : stage.hints;
    }

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
    // Create hint display (top left)
    _hintDisplay = HintDisplay(
      position: Vector2(20, 20),
    );
    await add(_hintDisplay);

    // Create lives display (top right)
    _livesDisplay = LivesDisplay(
      position: Vector2(size.x - 20, 20),
      maxLives: 6,
    );
    await add(_livesDisplay);
  }


  /// Handle card tap
  void _onCardTapped(PigCard card) {
    if (!gameState.isGameActive || _isProcessingMatch || _isHintRevealing || _isShuffling) return;
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
      // Check if either card has a powerup
      _collectPowerup(_firstSelectedCard!);
      _collectPowerup(_secondSelectedCard!);

      // Match found! Play success animation (cards will be removed by animation)
      _firstSelectedCard!.setMatched();
      _secondSelectedCard!.setMatched();
      gameState.registerMatch();
    } else {
      // Check if either card has a powerup (penalty shuffle trigger)
      final hasPowerup = _firstSelectedCard!.hasPowerup || _secondSelectedCard!.hasPowerup;

      // No match - play fail animation then flip back
      final firstCard = _firstSelectedCard;
      final secondCard = _secondSelectedCard;

      if (hasPowerup) {
        // Remove powerups from both cards
        _firstSelectedCard!.powerupType = PowerupType.none;
        _secondSelectedCard!.powerupType = PowerupType.none;

        print('[Powerup] Powerup lost! Triggering penalty shuffle...');

        // Play fail animation then trigger penalty shuffle
        _firstSelectedCard!.playMatchFailAnimation(onComplete: () {
          firstCard?.flipToFaceDown();
        });
        _secondSelectedCard!.playMatchFailAnimation(onComplete: () {
          secondCard?.flipToFaceDown();
          // Start penalty shuffle after animations complete
          _startPenaltyShuffle();
        });
      } else {
        // Normal fail - just shake and flip back
        _firstSelectedCard!.playMatchFailAnimation(onComplete: () {
          firstCard?.flipToFaceDown();
        });
        _secondSelectedCard!.playMatchFailAnimation(onComplete: () {
          secondCard?.flipToFaceDown();
        });
      }

      gameState.loseLife();

      // Spawn powerup on a random card after failed match
      _spawnPowerupOnRandomCard();
    }

    // Reset selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;
  }

  /// Spawn a powerup on a random face-down card
  void _spawnPowerupOnRandomCard() {
    // Get all face-down cards without powerups
    final eligibleCards = _cards
        .where((card) =>
            card.state == CardState.faceDown &&
            card.powerupType == PowerupType.none)
        .toList();

    if (eligibleCards.isEmpty) return;

    // Roll for powerup spawn
    final roll = _random.nextDouble();
    PowerupType powerupType = PowerupType.none;

    if (roll < GameConfig.hintPowerupChance) {
      // 5% chance for hint
      powerupType = PowerupType.hint;
      print('[Powerup] Hint spawned! (roll: $roll)');
    } else if (roll < GameConfig.hintPowerupChance + GameConfig.heartPowerupChance) {
      // 10% chance for heart (total 15% with hint)
      powerupType = PowerupType.heart;
      print('[Powerup] Heart spawned! (roll: $roll)');
    }

    // Assign powerup to random eligible card
    if (powerupType != PowerupType.none) {
      final randomCard = eligibleCards[_random.nextInt(eligibleCards.length)];
      randomCard.powerupType = powerupType;
      print('[Powerup] Assigned ${powerupType.name} to card with value ${randomCard.cardValue}');
    }
  }

  /// Collect powerup from a matched card
  void _collectPowerup(PigCard card) {
    if (!card.hasPowerup) return;

    switch (card.powerupType) {
      case PowerupType.hint:
        gameState.hints++;
        print('[Powerup] Hint collected! Total hints: ${gameState.hints}');
        break;
      case PowerupType.heart:
        // Restore 1 life (up to max)
        if (gameState.lives < gameState.maxLives) {
          gameState.lives++;
          print('[Powerup] Heart collected! Lives restored to: ${gameState.lives}');
        }
        break;
      case PowerupType.none:
        break;
    }

    // Clear powerup from card
    card.powerupType = PowerupType.none;
  }

  /// Use a hint to reveal all cards for a short duration
  void useHint() {
    if (gameState.hints <= 0) {
      print('[Powerup] No hints available!');
      return;
    }
    if (_isHintRevealing) {
      print('[Powerup] Hint already active!');
      return;
    }
    if (_isShuffling) {
      print('[Powerup] Cannot use hint during shuffle!');
      return;
    }
    if (!gameState.isGameActive) {
      print('[Powerup] Cannot use hint when game is not active!');
      return;
    }

    gameState.hints--;
    _isHintRevealing = true;
    _hintRevealTimer = 0.0;

    print('[Powerup] Hint used! Remaining hints: ${gameState.hints}');

    // Flip all face-down cards to face up
    for (final card in _cards) {
      if (card.state == CardState.faceDown) {
        card.flipToFaceUp();
      }
    }
  }

  /// End hint reveal and flip cards back
  void _endHintReveal() {
    _isHintRevealing = false;
    _hintRevealTimer = 0.0;

    print('[Powerup] Hint reveal ended');

    // Flip all non-matched cards back to face down
    for (final card in _cards) {
      if (card.state == CardState.faceUp) {
        card.flipToFaceDown();
      }
    }
  }

  /// Start penalty shuffle animation (triggered when powerup card match fails)
  void _startPenaltyShuffle() {
    _isShuffling = true;
    _shuffleTimer = 0.0;
    _targetPositions.clear();

    print('[Penalty] Starting shuffle animation...');

    // Save current positions
    final currentPositions = _cards.map((card) => card.position.clone()).toList();

    // Create shuffled list of positions
    final shuffledPositions = List<Vector2>.from(currentPositions);
    shuffledPositions.shuffle(_random);

    // Store target positions for animation
    _targetPositions.addAll(shuffledPositions);
  }

  /// End penalty shuffle animation
  void _endPenaltyShuffle() {
    _isShuffling = false;
    _shuffleTimer = 0.0;

    print('[Penalty] Shuffle animation complete');

    // Ensure cards are at exact target positions
    for (int i = 0; i < _cards.length && i < _targetPositions.length; i++) {
      _cards[i].position = _targetPositions[i].clone();
    }

    _targetPositions.clear();
  }

  /// Show game over screen
  void _showGameOverScreen(bool isWin) {
    String message;
    if (isWin) {
      if (StageManager.instance.hasNextStage) {
        final nextStage = StageManager.instance.currentStageNumber + 1;
        message = 'Tap for Stage $nextStage';
      } else {
        message = 'All Stages Complete!\nTap to Restart';
      }
    } else {
      message = 'Tap to Retry';
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
      // If game over, reset to first stage and clear persistent values
      StageManager.instance.reset();
      _currentLives = 0;
      _currentHints = 0;
      _loadNextStage();
    } else {
      // Otherwise just restart current stage
      _loadNextStage();
    }
  }

  /// Load next stage (or restart current stage)
  void _loadNextStage() {
    // Save current lives and hints before clearing game state
    _currentLives = gameState.lives;
    _currentHints = gameState.hints;

    // Remove all cards (only if they still have a parent)
    for (final card in _cards) {
      if (card.parent != null) {
        remove(card);
      }
    }
    _cards.clear();

    // Reset selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;
    _isProcessingMatch = false;
    _matchCheckTimer = 0.0;
    _shufflingTimer = 0.0;
    _previewTimer = 0.0;

    // Reset hint reveal state
    _isHintRevealing = false;
    _hintRevealTimer = 0.0;

    // Reset shuffle state
    _isShuffling = false;
    _shuffleTimer = 0.0;
    _targetPositions.clear();

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
      } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
        // Use hint on 'H' key
        if (gameState.state == GameState.playing) {
          useHint();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
