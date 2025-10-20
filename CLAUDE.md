# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lotty Memory Game** is a Flutter Flame-based memory card matching game featuring floating pig characters in tubes on a swimming pool background. Players flip cards to find matching pairs while managing limited lives.

### Key Features
- Floating card physics with natural sin/cos wave motion
- Card collision detection and bounce effects
- Card flip animations with 3D rotation effect
- Shuffling phase and 2-second preview mode before gameplay
- Score tracking (100 points per match)
- Lives system (5 lives, lose one per mismatch)
- Game over and win conditions
- Restart functionality with 'R' key

## Technology Stack

- **Framework**: Flutter 3.x
- **Game Engine**: Flame ^1.32.0
- **XML Parsing**: xml ^6.6.1
- **Asset Format**: TexturePacker XML sprite sheets
- **UI Pattern**: Flutter Overlay with ValueNotifiers over Flame canvas

### Directory Structure
```
lib/
├── main.dart                 # App entry point with Flutter Overlay UI
├── game/
│   ├── lotty_memory_game.dart   # Main game logic and state
│   └── game_state.dart          # GameStateManager for game flow
├── components/
│   ├── pig_card.dart            # Card component with physics
│   └── ui/
│       ├── score_display.dart   # Flame score display (deprecated)
│       ├── lives_display.dart   # Flame lives display (deprecated)
│       └── game_over_overlay.dart  # Game over screen
└── utils/
    ├── asset_manager.dart       # Sprite sheet manager singleton
    └── xml_parser.dart          # TexturePacker XML parser
```

### Game States
```dart
enum GameState {
  shuffling,  // Initial shuffle animation (1 second)
  preview,    // Show all cards face up (2 seconds)
  playing,    // Active gameplay
  gameOver,   // Lost all lives
  gameWon,    // Matched all pairs
}
```

### Key Components

#### PigCard
- Implements floating motion using randomized sin/cos waves
- Circular collision detection with bounce physics
- 3D flip animation using cosine scale transformation
- States: faceDown, faceUp, matched

#### GameStateManager
- Tracks score, lives, and found pairs
- Manages game state transitions
- Provides callbacks for UI updates

#### AssetManager (Singleton)
- Loads TexturePacker XML sprite sheets
- Manages number card sprites and tube pig sprites
- Provides sprite retrieval methods

### UI Architecture

**Important**: The game uses Flutter Overlay widgets rather than Flame components for UI elements due to reactivity issues with Flame's text rendering.

```dart
// In main.dart
Stack(
  children: [
    GameWidget(game: game),  // Flame game canvas
    ValueListenableBuilder<int>(
      valueListenable: game.scoreNotifier,
      builder: (context, score, child) {
        return Positioned(
          top: 20, left: 20,
          child: Text('Score: $score'),
        );
      },
    ),
    // Lives and game over overlays...
  ],
)
```

### Game Mechanics

1. **Shuffling Phase** (1 second): Cards shuffle with random values
2. **Preview Phase** (2 seconds): All cards flip face up to show positions
3. **Playing Phase**:
   - Player clicks cards to flip them
   - Two cards selected trigger match check after 1 second
   - Match: +100 score, cards stay face up
   - No match: -1 life, cards flip back
4. **Win Condition**: All 4 pairs matched
5. **Lose Condition**: 0 lives remaining

### Physics Implementation

Cards use simple vector-based collision detection without a full physics engine:

```dart
// Floating motion
final floatX = sin(floatTime * frequencyX + offsetX) * amplitude;
final floatY = cos(floatTime * frequencyY + offsetY) * amplitude;

// Collision detection
final distance = position.distanceTo(other.position);
if (distance < (radius + other.radius)) {
  // Resolve collision with bounce
}

// Boundary handling
if (position.x < 0 || position.x > gameSize.x) {
  velocity.x *= -1;  // Reflect velocity
}
```

## Assets

### Sprite Sheets
- `spritesheet_match_numbers.xml/png`: Number cards (1-4)
- `spritesheet_match_dice.xml/png`: Dice cards (1-4 dots)
- `spritesheet_match_tubes.xml/png`: Pig tubes (8 variations)

### Images
- `background_pool.png`: Swimming pool background

### Fonts
- TJJoyofsinging (Regular, Bold, Extrabold, Italic)

## Known Issues & Solutions

### UI Not Updating
**Problem**: Flame TextComponent and PositionComponent don't reliably update rendered text.

**Solution**: Use Flutter Overlay with ValueNotifiers instead of Flame UI components.

### Card Tap Timing
**Problem**: Cards flipping before game logic can process selection state.

**Solution**: Remove `flip()` from `onTapDown`, let game logic explicitly call `flipToFaceUp()`.

### Asset Path Doubling
**Problem**: `loadSprite('images/file.png')` creates "images/images/" path.

**Solution**: Use `loadSprite('file.png')` since assets are already in images/ directory.

## Development Workflow

1. Make code changes
2. Test with `flutter run`
3. Commit changes with descriptive messages
4. Push to GitHub using `gh` CLI commands
5. Create PRs with `gh pr create` for feature branches

## Repository Information

- **GitHub**: https://github.com/jay0286/lotty_memory_game
- **Authenticated Account**: jay0286
- **Created**: 2025-10-20

## Next Steps for Enhancement

- Add difficulty levels (more cards, different time limits)
- Implement high score persistence
- Add sound effects and background music
- Create level progression system
- Add particle effects for matches
- Implement achievement system
