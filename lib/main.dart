import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'game/lotty_memory_game.dart';
import 'game/stage_config.dart';
import 'components/ui/start_dialog.dart';
import 'components/ui/game_over_dialog.dart';
import 'components/ui/stage_clear_dialog.dart';
import 'components/ui/lives_count_widget.dart';
import 'components/ui/hint_count_widget.dart';
import 'components/ui/stage_info_widget.dart';
import 'components/ui/timer_widget.dart';
import 'services/ranking_service.dart';
import 'screens/leaderboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

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
        onShowLeaderboard: () async {
          // 리더보드 화면으로 이동 (await으로 돌아올 때까지 대기)
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LeaderboardScreen(
                onStartNewGame: null, // 시작 다이얼로그가 이미 있으므로 null
              ),
            ),
          );
          // 리더보드에서 돌아오면 아무것도 하지 않음 (시작 다이얼로그가 이미 열려있음)
        },
      ),
    );
  }

  void _showGameOverDialog() {
    final currentStage = game.maxStageReached;
    final elapsedTime = game.elapsedTime;
    final calculatedScore = RankingService.instance.calculateScore(
      currentStage,
      elapsedTime,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        currentStage: currentStage,
        elapsedTime: elapsedTime,
        onShowLeaderboard: () {
          // 리더보드 화면으로 이동 (점수 데이터 전달)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LeaderboardScreen(
                onStartNewGame: () {
                  // 시작 다이얼로그 표시
                  _showStartDialog();
                },
                newScore: calculatedScore,
                newStage: currentStage,
                newElapsedTime: elapsedTime,
              ),
            ),
          );
        },
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

          // Close button at top left
          Positioned(
            top: 24,
            left: 20,
            child: GestureDetector(
              onTap: () {
                // 게임을 완전히 재시작 (새 게임 인스턴스 생성)
                setState(() {
                  game = LottyMemoryGame();
                  game.onShowGameOverDialog = _showGameOverDialog;
                  game.onShowStageClearDialog = _showStageClearDialog;
                });
                // 시작 다이얼로그 표시
                _showStartDialog();
              },
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha:0.3),
                child: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha:0.7),
                  size: 32,
                  weight: 900,
                ),
              ),
            ),
          ),
          // Stage number and Stage name display at top left
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
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
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: canUseHint ? () => game.useHint() : null,
                    child: Center(
                      child: Opacity(
                        opacity: canUseHint ? 1 : 0,
                        child: Container(
                          width: 130,
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
