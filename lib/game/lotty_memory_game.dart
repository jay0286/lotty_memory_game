import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/asset_manager.dart';
import '../components/pig_card.dart';
import '../components/shadow_layer.dart';
import '../config/game_config.dart';
import '../managers/sound_manager.dart';
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

  // Queue for next pair selections during match processing
  final List<PigCard> _queuedCards = [];

  final Random _random = Random();

  // Persistent values across stages
  int _currentLives = 0;
  int _currentHints = 0;

  // ValueNotifiers for Flutter UI
  final ValueNotifier<int> hintCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> livesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>> stageInfoNotifier = ValueNotifier<Map<String, dynamic>>({
    'number': 1,
    'name': '',
  });
  final ValueNotifier<Duration> elapsedTimeNotifier = ValueNotifier<Duration>(Duration.zero);

  // Game timer
  final Stopwatch _gameStopwatch = Stopwatch();
  int _maxStageReached = 0;
  double _timerUpdateAccumulator = 0.0;

  // Game ready state
  bool _isGameReady = false;

  // Callbacks for showing dialogs
  void Function()? onShowGameOverDialog;
  void Function()? onShowStageClearDialog;

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

    // Initialize sound manager
    SoundManager().initialize();

    // Load and add background
    await _loadBackground();

    // Initialize shadow layer (low priority, renders first)
    _shadowLayer = ShadowLayer(cards: _cards);
    add(_shadowLayer);

    // Initialize UI first
    await _initializeUI();

    // Don't initialize cards yet - wait for start dialog
    _isGameReady = true;

  }

  /// Start the game (called from StartDialog)
  void startFirstStage() {
    if (_isGameReady && _cards.isEmpty) {
      _gameStopwatch.start();
      _initializeCards();
      // Start BGM
      SoundManager().playBGM();
    }
  }

  /// Pause the timer
  void pauseTimer() {
    _gameStopwatch.stop();
  }

  /// Resume the timer
  void resumeTimer() {
    _gameStopwatch.start();
  }

  /// Get elapsed time
  Duration get elapsedTime => _gameStopwatch.elapsed;

  /// Get max stage reached
  int get maxStageReached => _maxStageReached;

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game hasn't started yet
    if (_cards.isEmpty) return;

    // Update elapsed time notifier (throttled to ~0.1 seconds to avoid build errors)
    if (_gameStopwatch.isRunning) {
      _timerUpdateAccumulator += dt;
      if (_timerUpdateAccumulator >= 0.1) {
        elapsedTimeNotifier.value = _gameStopwatch.elapsed;
        _timerUpdateAccumulator = 0.0;
      }
    }

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
        // Note: _isProcessingMatch is managed inside _checkMatch() now
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

    // Update max stage reached
    final currentStageNum = StageManager.instance.currentStageNumber;
    if (currentStageNum > _maxStageReached) {
      _maxStageReached = currentStageNum;
    }

    // Update stage info notifier
    stageInfoNotifier.value = {
      'number': currentStageNum,
      'name': stage.name,
    };

    // Set preview duration from stage config
    _previewDuration = stage.previewDuration;

    // Generate card values (matching group IDs)
    final cardValues = <int>[];
    for (int i = 1; i <= stage.pairs; i++) {
      cardValues.add(i);
      cardValues.add(i);
    }
    cardValues.shuffle();

    // Assign category groups and categories to each pair while avoiding sprite reuse
    // Step 1: Prepare available categories and sprite variant pools per group
    final categoryGroups = <CardCategoryGroup, List<CardCategory>>{};
    final categorySpritesCache = <CardCategory, List<Sprite>>{};
    final categorySpriteCounts = <CardCategory, int>{};

    for (final category in stage.categories.toSet()) {
      final sprites = assetManager.getSpritesForCategory(category);
      if (sprites.isEmpty) continue;
      categoryGroups.putIfAbsent(category.group, () => []).add(category);
      categorySpritesCache[category] = sprites;
      categorySpriteCounts[category] = sprites.length;
    }

    if (categoryGroups.isEmpty) {
      return;
    }

    final groupVariantPools = <CardCategoryGroup, List<int>>{};

    void replenishGroupPool(CardCategoryGroup group) {
      final categories = categoryGroups[group];
      if (categories == null || categories.isEmpty) {
        groupVariantPools[group] = [];
        return;
      }

      final counts = categories.map((category) => categorySpriteCounts[category] ?? 0).toList();
      if (counts.isEmpty) {
        groupVariantPools[group] = [];
        return;
      }

      final variantCount = counts.reduce(min);
      if (variantCount <= 0) {
        groupVariantPools[group] = [];
        return;
      }

      final variants = List<int>.generate(variantCount, (index) => index);
      variants.shuffle(random);
      groupVariantPools[group] = variants;
    }

    for (final group in categoryGroups.keys) {
      replenishGroupPool(group);
    }

    List<CardCategoryGroup> availableGroups() {
      return groupVariantPools.entries.where((entry) => entry.value.isNotEmpty).map((entry) => entry.key).toList();
    }

    final pairGroupAssignments = <int, CardCategoryGroup>{};
    final pairVariantAssignments = <int, int>{};
    final cardCategoryAssignments = <int, CardCategory>{}; // card index -> category

    for (int pairId = 1; pairId <= stage.pairs; pairId++) {
      var groups = availableGroups();
      if (groups.isEmpty) {
        for (final group in categoryGroups.keys) {
          if (groupVariantPools[group]?.isEmpty ?? true) {
            replenishGroupPool(group);
          }
        }
        groups = availableGroups();
        if (groups.isEmpty) {
          break;
        }
      }

      final selectedGroup = groups[random.nextInt(groups.length)];
      final variants = groupVariantPools[selectedGroup]!;
      final variantIndex = variants.removeLast();

      pairGroupAssignments[pairId] = selectedGroup;
      pairVariantAssignments[pairId] = variantIndex;
    }

    // Step 2: Assign categories to each individual card using the selected group
    for (int i = 0; i < stage.totalCards; i++) {
      final pairId = cardValues[i];
      final group = pairGroupAssignments[pairId];
      if (group == null) {
        continue;
      }

      final categoriesInGroup = categoryGroups[group];
      if (categoriesInGroup == null || categoriesInGroup.isEmpty) {
        continue;
      }

      final category = categoriesInGroup[random.nextInt(categoriesInGroup.length)];
      cardCategoryAssignments[i] = category;
    }

    // Get tube pig sprites
    final tubePigSprites = assetManager.getTubePigSprites();
    if (tubePigSprites.isEmpty) {
      return;
    }

    // Calculate card layout with responsive sizing based on screen orientation
    final columns = GameConfig.cardLayoutColumns;

    // Determine card size based on screen aspect ratio
    // For wide screens (landscape), use screen height as reference
    // For tall screens (portrait), use screen width as reference
    final aspectRatio = size.x / size.y;
    final double cardSize;
    final double cardSpacing;

    if (aspectRatio > 1.2) {
      // Landscape: base on height to prevent cards from being too large
      cardSize = size.y * GameConfig.cardSizeFraction;
      cardSpacing = size.y * GameConfig.cardSpacingFraction;
    } else {
      // Portrait: base on width (original behavior)
      cardSize = size.x * GameConfig.cardSizeFraction;
      cardSpacing = size.x * GameConfig.cardSpacingFraction;
    }

    final startX = (size.x - (columns - 1) * cardSpacing) / 2;
    final rowSpacing = cardSize * GameConfig.cardRowSpacingMultiplier;
    final startY = size.y * GameConfig.cardLayoutStartY;

    // Create cards
    for (int i = 0; i < stage.totalCards; i++) {
      final pairId = cardValues[i];
      final category = cardCategoryAssignments[i];
      if (category == null) {
        continue;
      }

      final frontSprites = categorySpritesCache[category] ?? assetManager.getSpritesForCategory(category);
      if (frontSprites.isEmpty) {
        continue;
      }

      final variantIndex = pairVariantAssignments[pairId] ?? 0;
      final spriteIndex = variantIndex < frontSprites.length ? variantIndex : variantIndex % frontSprites.length;
      final frontSprite = frontSprites[spriteIndex];

      final card = PigCard(
        backSprite: tubePigSprites[i % tubePigSprites.length],
        frontSprite: frontSprite,
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
      onLivesChanged: () {
        livesCountNotifier.value = gameState.lives;
      },
      onHintsChanged: () {
        hintCountNotifier.value = gameState.hints;
      },
      onStateChanged: () {
        // Trigger UI update when game state changes (for hint button activation)
        final currentHints = gameState.hints;
        hintCountNotifier.value = -1; // Temporary different value
        hintCountNotifier.value = currentHints; // Back to actual value
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
      // Set cards face up instantly without animation so they can be clicked immediately
      card.setFaceUpInstant();
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
    // UI components moved to Flutter OSD (see main.dart)
    // Lives and hints are now displayed using ValueListenableBuilder
  }


  /// Handle card tap
  void _onCardTapped(PigCard card) {
    // Allow card tap during shuffling, preview or hint reveal to skip to game start
    if (gameState.state == GameState.shuffling ||
        gameState.state == GameState.preview ||
        _isHintRevealing) {
      // Skip preview/hint and start game immediately
      _skipToGameStart(card);
      return;
    }

    if (!gameState.isGameActive || _isShuffling) return;
    if (card.state != CardState.faceDown) return;

    // Don't allow selecting cards that are already selected in current or queued pairs
    if (card == _firstSelectedCard || card == _secondSelectedCard || _queuedCards.contains(card)) {
      return;
    }

    // Play card select sound
    SoundManager().playCardSelect();

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
    } else if (_isProcessingMatch) {
      // Additional cards go into queue
      _queuedCards.add(card);
    }
  }

  /// Skip preview/hint reveal and start game with selected card
  void _skipToGameStart(PigCard selectedCard) {
    // End hint reveal if active
    if (_isHintRevealing) {
      _isHintRevealing = false;
      _hintRevealTimer = 0.0;
    }

    // End shuffling/preview if active and transition to playing
    if (gameState.state == GameState.shuffling) {
      _shufflingTimer = _shufflingDuration; // Force shuffling to end
      // Transition shuffling -> preview -> playing
      gameState.startPreview();
      _previewTimer = _previewDuration; // Also end preview immediately
    }

    if (gameState.state == GameState.preview) {
      _previewTimer = _previewDuration; // Force preview to end
    }

    // Start the game if not already active
    if (!gameState.isGameActive) {
      gameState.startGame();
    }

    // Play card select sound
    SoundManager().playCardSelect();

    // Flip all cards face down except the selected one
    for (final card in _cards) {
      if (card != selectedCard && card.state == CardState.faceUp) {
        card.flipToFaceDown();
      }
    }

    // Keep the selected card face up and set it as first selection
    // If it's already face up (from preview/hint), keep it that way
    if (selectedCard.state == CardState.faceDown) {
      selectedCard.flipToFaceUp();
    }
    _firstSelectedCard = selectedCard;
  }

  /// Check if two selected cards match
  void _checkMatch() {
    if (_firstSelectedCard == null || _secondSelectedCard == null) return;

    if (_firstSelectedCard!.cardValue == _secondSelectedCard!.cardValue) {
      // Play match success sound
      SoundManager().playMatchSuccess();

      // Check if either card has a powerup
      _collectPowerup(_firstSelectedCard!);
      _collectPowerup(_secondSelectedCard!);

      // Match found! Play success animation (cards will be removed by animation)
      _firstSelectedCard!.setMatched();
      _secondSelectedCard!.setMatched();
      gameState.registerMatch();
    } else {
      // Play match fail sound
      SoundManager().playMatchFail();
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

    // Reset current selection
    _firstSelectedCard = null;
    _secondSelectedCard = null;

    // Process queued cards if any
    if (_queuedCards.isNotEmpty) {
      // Take first card from queue
      _firstSelectedCard = _queuedCards.removeAt(0);

      if (_queuedCards.isNotEmpty) {
        // Take second card from queue
        _secondSelectedCard = _queuedCards.removeAt(0);
        // Keep processing match for the queued pair
        // Set timer to almost complete for faster check (configurable delay for visual feedback)
        _isProcessingMatch = true;
        _matchCheckTimer = GameConfig.matchCheckDelay - GameConfig.queuedPairCheckOffset;
      } else {
        // Only first card was queued, wait for second
        _isProcessingMatch = false;
      }
    } else {
      _isProcessingMatch = false;
    }
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

    // Flip all face-down cards to face up instantly (no animation) so they can be clicked immediately
    for (final card in _cards) {
      if (card.state == CardState.faceDown) {
        card.setFaceUpInstant();
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

  /// Show game over screen or stage clear screen
  void _showGameOverScreen(bool isWin) {
    // Pause timer when dialog shows
    pauseTimer();

    if (isWin) {
      // Play stage clear sound
      SoundManager().playStageClear();
      // Show stage clear dialog
      onShowStageClearDialog?.call();
    } else {
      // Play game over sound
      SoundManager().playGameOver();
      // Show game over dialog
      onShowGameOverDialog?.call();
    }
  }

  /// Restart the game (after game over)
  void restartGame() {
    // Reset timer
    _gameStopwatch.reset();
    _maxStageReached = 0;
    elapsedTimeNotifier.value = Duration.zero;

    // Reset to first stage and clear persistent values
    StageManager.instance.reset();
    _currentLives = 0;
    _currentHints = 0;

    // Resume timer
    resumeTimer();
    _loadNextStage();
  }

  /// Go to next stage (after stage clear)
  void goToNextStage() {
    // Resume timer for next stage
    resumeTimer();

    // Advance to next stage
    if (StageManager.instance.hasNextStage) {
      StageManager.instance.nextStage();
      _loadNextStage();
    } else {
      // All stages complete, restart from beginning
      restartGame();
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

    // Reset queued cards
    _queuedCards.clear();

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
          restartGame();
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
