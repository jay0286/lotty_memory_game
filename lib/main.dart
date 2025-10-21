import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/lotty_memory_game.dart';
import 'components/ui/start_dialog.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotty Memory Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LottyMemoryGame game;
  bool _hasShownStartDialog = false;

  @override
  void initState() {
    super.initState();
    game = LottyMemoryGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show start dialog only once when the widget is first built
    if (!_hasShownStartDialog) {
      _hasShownStartDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartDialog();
      });
    }
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StartDialog(
        onStart: () {
          // Dialog closes automatically, game starts
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),
          // Hint button at bottom center (always show, but disable when hints = 0)
          ValueListenableBuilder<int>(
            valueListenable: game.hintCountNotifier,
            builder: (context, hintCount, child) {
              final bool hasHints = hintCount > 0;
              // Check if gameState is initialized before accessing it
              bool isGameActive = false;
              try {
                isGameActive = game.gameState.isGameActive;
              } catch (e) {
                // gameState not initialized yet
                isGameActive = false;
              }
              final bool canUseHint = hasHints && isGameActive;

              return Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: canUseHint ? () => game.useHint() : null,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: canUseHint
                            ? Colors.amber.withValues(alpha: 0.9)
                            : Colors.grey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          hasHints ? '💡' : '🔒',
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
