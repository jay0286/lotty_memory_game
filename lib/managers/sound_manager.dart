import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 게임 사운드 효과를 관리하는 매니저 클래스
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  late AudioPlayer _audioPlayer;
  late AudioPlayer _bgmPlayer; // BGM 전용 플레이어
  bool _soundEnabled = false;
  bool _bgmEnabled = true;
  bool _isInitialized = false;
  final Map<String, AssetSource> _cachedSources = {};

  // 사운드 설정
  static const double bgmDefaultVolume = 0.3; // BGM 기본 볼륨 (30%)
  static const String bgmFileName = 'Joyful_Hearts.mp3'; // 기본 BGM 파일

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _initializeIfNeeded() {
    if (!_isInitialized) {
      initialize();
    }
  }

  /// 사운드 매니저 초기화
  void initialize() {
    if (_isInitialized) {
      return;
    }

    _audioPlayer = AudioPlayer();
    _bgmPlayer = AudioPlayer();
    _isInitialized = true;
  }

  /// 사운드 활성화 (사용자 상호작용 후)
  Future<void> enableSound() async {
    _initializeIfNeeded();
    _log('🔊 사운드 활성화 시도, 현재 상태: $_soundEnabled');

    if (_soundEnabled) {
      _log('🔊 사운드 이미 활성화됨');
      return;
    }

    try {
      // 사운드 테스트
      _log('🔊 테스트 사운드 재생 시도...');
      await _audioPlayer.play(_getAssetSource('block_drop.wav'));
      _soundEnabled = true;
      _log('🔊 사운드 매니저 활성화 완료!');
    } catch (e) {
      _log('🔊 사운드 매니저 활성화 실패: $e');
      // 웹 환경에서는 사운드가 작동하지 않을 수 있으므로 강제로 활성화
      _soundEnabled = true;
      _log('🔊 웹 환경 대응: 사운드 활성화 강제 설정');
    }
  }

  /// 사운드 재생
  void playSound(String soundFile, {double volume = 1.0}) async {
    _initializeIfNeeded();

    // 강제로 사운드 활성화 시도
    if (!_soundEnabled) {
      await enableSound();
    }

    try {
      final source = _getAssetSource(soundFile);

      // 볼륨 설정 (0.0 ~ 1.0)
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _audioPlayer.play(source);
    } catch (e) {
      _log('🔊 사운드 재생 실패: $e');
    }
  }

  /// 카드 선택 사운드 (첫 번째 튜브 선택 시)
  void playCardSelect() {
    playSound('block_drop.wav', volume: 0.7);
  }

  /// 매칭 성공 사운드
  void playMatchSuccess() {
    playSound('progress_increase.wav', volume: 0.8);
  }

  /// 매칭 실패 사운드
  void playMatchFail() {
    playSound('block_splash.wav', volume: 0.6);
  }

  /// 스테이지 클리어 사운드
  void playStageClear() {
    playSound('stage_clear.wav', volume: 0.8);
  }

  /// 게임 오버 사운드
  void playGameOver() {
    playSound('game_over.wav', volume: 0.8);
  }

  /// BGM 재생 (게임 시작 시)
  void playBGM({double? volume}) async {
    _initializeIfNeeded();
    if (!_bgmEnabled) return;

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // 반복 재생
      await _bgmPlayer.setVolume(
        (volume ?? bgmDefaultVolume).clamp(0.0, 1.0),
      );
      await _bgmPlayer.play(_getAssetSource(bgmFileName));
      _log('🎵 BGM 재생 시작: $bgmFileName');
    } catch (e) {
      _log('🎵 BGM 재생 실패: $e');
    }
  }

  /// BGM 정지
  void stopBGM() async {
    if (!_isInitialized) return;
    try {
      await _bgmPlayer.stop();
      _log('🎵 BGM 정지');
    } catch (e) {
      _log('🎵 BGM 정지 실패: $e');
    }
  }

  /// BGM 일시정지
  void pauseBGM() async {
    if (!_isInitialized) return;
    try {
      await _bgmPlayer.pause();
      _log('🎵 BGM 일시정지');
    } catch (e) {
      _log('🎵 BGM 일시정지 실패: $e');
    }
  }

  /// BGM 재개
  void resumeBGM() async {
    if (!_isInitialized) return;
    try {
      await _bgmPlayer.resume();
      _log('🎵 BGM 재개');
    } catch (e) {
      _log('🎵 BGM 재개 실패: $e');
    }
  }

  /// BGM 볼륨 설정
  void setBGMVolume(double volume) async {
    if (!_isInitialized) return;
    try {
      await _bgmPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _log('🎵 BGM 볼륨 설정 실패: $e');
    }
  }

  /// BGM 활성화/비활성화
  void setBGMEnabled(bool enabled) {
    _bgmEnabled = enabled;
    if (!enabled) {
      stopBGM();
    }
  }

  AssetSource _getAssetSource(String fileName) {
    return _cachedSources.putIfAbsent(
      fileName,
      () => AssetSource('sounds/$fileName'),
    );
  }

  /// 테스트 사운드 (디버깅용)
  void playTestSound() {
    playSound('block_drop.wav');
  }

  /// 사운드 매니저 정리
  void dispose() {
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
