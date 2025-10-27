/// 난이도 설정
enum Difficulty {
  easy,
  medium,
  hard;

  /// 난이도별 표시 이름
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return '쉬움';
      case Difficulty.medium:
        return '중간';
      case Difficulty.hard:
        return '어려움';
    }
  }

  /// 난이도별 설명
  String get description {
    switch (this) {
      case Difficulty.easy:
        return '1단계부터 시작';
      case Difficulty.medium:
        return '10단계부터 시작';
      case Difficulty.hard:
        return '20단계부터 시작';
    }
  }

  /// 난이도별 시작 스테이지 번호
  int get startStage {
    switch (this) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 10;
      case Difficulty.hard:
        return 20;
    }
  }
}

/// 난이도 관리 싱글톤 클래스
class DifficultyManager {
  static final DifficultyManager _instance = DifficultyManager._internal();
  factory DifficultyManager() => _instance;
  DifficultyManager._internal();

  /// 현재 선택된 난이도 (기본값: 쉬움)
  Difficulty _currentDifficulty = Difficulty.easy;

  /// 현재 난이도 가져오기
  Difficulty get currentDifficulty => _currentDifficulty;

  /// 시작 스테이지 번호 가져오기
  int get startStage => _currentDifficulty.startStage;

  /// 난이도 설정
  void setDifficulty(Difficulty difficulty) {
    _currentDifficulty = difficulty;
    print('[DifficultyManager] Difficulty set to: ${difficulty.displayName} (Stage ${difficulty.startStage})');
  }

  /// 난이도 리셋 (쉬움으로 초기화)
  void reset() {
    _currentDifficulty = Difficulty.easy;
    print('[DifficultyManager] Reset to: ${_currentDifficulty.displayName}');
  }
}
