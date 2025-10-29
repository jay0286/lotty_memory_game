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
import 'managers/difficulty_manager.dart';
import 'managers/sound_manager.dart';
import 'services/ranking_service.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/difficulty_select_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const DifficultySelectScreen(),
        '/game': (context) => const GameScreen(),
      },
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
  bool _isGameLoaded = false;

  @override
  void initState() {
    super.initState();
    // 난이도 선택 후 StageManager를 해당 난이도의 시작 스테이지로 설정
    StageManager.instance.reset();

    game = LottyMemoryGame();
    // Set callbacks for showing dialogs
    game.onShowGameOverDialog = _showGameOverDialog;
    game.onShowStageClearDialog = _showStageClearDialog;

    // 게임 로드 완료 대기
    _waitForGameLoad();
  }

  /// 게임 리소스 로드 완료 대기
  void _waitForGameLoad() async {
    // 게임이 로드될 때까지 대기 (최대 10초)
    int attempts = 0;
    const maxAttempts = 100; // 10초 (100ms * 100)

    while (!game.isGameReady && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (mounted && game.isGameReady) {
      setState(() {
        _isGameLoaded = true;
      });

      // 로드 완료 후 시작 다이얼로그 표시
      if (!_hasShownStartDialog) {
        _hasShownStartDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showStartDialog();
          }
        });
      }
    }
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StartDialog(
        onStart: () async {
          // iOS/Android에서 사용자 터치 직후 오디오 활성화 (중요!)
          await SoundManager().enableSound();
          game.startFirstStage();
        },
        onShowLeaderboard: () async {
          // 시작 다이얼로그를 닫음
          Navigator.of(context).pop();

          // 리더보드 화면으로 이동
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeaderboardScreen(
                onStartNewGame: null,
              ),
            ),
          );

          // 리더보드에서 돌아오면 난이도 선택 화면으로 이동
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
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
        onShowLeaderboard: () async {
          // 게임 오버 다이얼로그를 닫음
          Navigator.of(context).pop();

          // 리더보드 화면으로 이동 (점수 데이터 전달)
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LeaderboardScreen(
                onStartNewGame: null,
                newScore: calculatedScore,
                newStage: currentStage,
                newElapsedTime: elapsedTime,
              ),
            ),
          );

          // 리더보드에서 돌아온 후 난이도 선택 화면으로 이동
          if (context.mounted) {
            // DifficultyManager 리셋
            DifficultyManager().reset();
            // StageManager를 먼저 리셋 (싱글톤이므로 명시적 리셋 필요)
            StageManager.instance.reset();

            // 난이도 선택 화면으로 이동
            Navigator.of(context).pushReplacementNamed('/');
          }
        },
        onRetry: () {
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

          // 로딩 오버레이
          if (!_isGameLoaded)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '게임 로딩 중...',
                      style: TextStyle(
                        fontFamily: 'TJJoyofsinging',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Close button at top left (로딩 완료 후에만 표시)
          if (_isGameLoaded)
            Positioned(
              top: 24,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  // DifficultyManager와 StageManager를 리셋하고 난이도 선택 화면으로 이동
                  DifficultyManager().reset();
                  StageManager.instance.reset();
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 32,
                    weight: 900,
                  ),
                ),
              ),
            ),
          // Stage number and Stage name display at top left (로딩 완료 후에만 표시)
          if (_isGameLoaded)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
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
            ),
          // Timer, Hints and Lives display at top right (로딩 완료 후에만 표시)
          if (_isGameLoaded)
            Positioned(
              top: 20,
              right: 20,
              child: IgnorePointer(
                child: Row(
                  children: [
                    HintCountWidget(hintNotifier: game.hintCountNotifier),
                    const SizedBox(width: 10),
                    LivesCountWidget(livesNotifier: game.livesCountNotifier),
                  ],
                ),
              ),
            ),

          // Timer display (로딩 완료 후에만 표시)
          if (_isGameLoaded)
            Positioned(
              top: 112,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  child: TimerWidget(elapsedTimeNotifier: game.elapsedTimeNotifier),
                ),
              ),
            ),
          // Hint button at bottom center (로딩 완료 후에만 표시)
          if (_isGameLoaded)
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
                bottom: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: IgnorePointer(
                    ignoring: !canUseHint,
                    child: GestureDetector(
                      onTap: canUseHint ? () => game.useHint() : null,
                      child: Center(
                        child: Opacity(
                          opacity: canUseHint ? 1 : 0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(64),
                              border: Border.all(
                                color: Color(0xffffcb00).withValues(alpha: 0.7),
                                width: 7,
                              ),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/hint_small.png'),
                                fit: BoxFit.cover,
                              ),
                              shape: BoxShape.rectangle,
                              boxShadow: [
                                  BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 9,
                                        offset: const Offset(9, 9),
                                      ),
                                    ],
                            ),
                            child:
                            SizedBox(
                              width: 42,
                              height: 42,
                            ),
                        ),
                      ),
                    ),
                  ),)
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
