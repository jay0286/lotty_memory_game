import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/lotty_memory_game.dart';
import 'game/stage_config.dart';
import 'components/ui/start_dialog.dart';
import 'components/ui/game_over_dialog.dart';
import 'components/ui/stage_clear_dialog.dart';
import 'components/ui/lives_count_widget.dart';
import 'components/ui/hint_count_widget.dart';
import 'components/ui/stage_info_widget.dart';
import 'components/ui/timer_widget.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotty Memory Game',
      debugShowCheckedModeBanner: false,
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
    // Set callbacks for showing dialogs
    game.onShowGameOverDialog = _showGameOverDialog;
    game.onShowStageClearDialog = _showStageClearDialog;
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
          // Start the first stage when dialog closes
          game.startFirstStage();
        },
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        currentStage: game.maxStageReached,
        elapsedTime: game.elapsedTime,
        onRetry: () {
          // Restart the game
          game.restartGame();
        },
      ),
    );
  }

  void _showStageClearDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StageClearDialog(
        currentStage: StageManager.instance.currentStageNumber,
        elapsedTime: game.elapsedTime,
        onNext: () {
          // Go to next stage
          game.goToNextStage();
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

          // Stage number and Stage name display at top left
          Positioned(
            top: 10,
            left: 20,
            child: ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: game.stageInfoNotifier,
              builder: (context, stageInfo, child) {
                return StageInfoWidget(
                  stageNumber: stageInfo['number'] as int,
                  stageName: stageInfo['name'] as String,
                );
              },
            ),
          ),
          // Timer, Hints and Lives display at top right
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                HintCountWidget(hintNotifier: game.hintCountNotifier),
                const SizedBox(width: 10),
                LivesCountWidget(livesNotifier: game.livesCountNotifier),
              ],
            ),
          ),

          // Timer, Hints and Lives display at top right
          Positioned(
            top: 96,
                left: 0,
                right: 0,
            child: Center(
              child: TimerWidget(elapsedTimeNotifier: game.elapsedTimeNotifier),
            ),
          ),
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
                bottom: 56,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: canUseHint ? () => game.useHint() : null,
                    child: Center(
                      child: Opacity(
                        opacity: canUseHint ? 1 : 0,
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 9,
                                offset: const Offset(9, 9),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/hint_wide.png',
                            fit: BoxFit.contain,
                          ),
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
