import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';

import '../utils/web_audio_unlocker.dart';

/// 게임 사운드 효과를 관리하는 매니저 클래스
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // AudioPool 풀 (동시 재생을 위해)
  final Map<String, AudioPool> _audioPools = {};
  static const int _defaultPoolSize = 5; // 기본 풀 크기
  static const int _webPoolSize = 2; // 웹 AudioContext 제한 고려
  late final int _configuredPoolSize;
  bool _webAudioUnlocked = false;

  bool _soundEnabled = false;
  bool _bgmEnabled = true;
  bool _isInitialized = false;

  // 사운드 설정
  static const double bgmDefaultVolume = 0.01; // BGM 기본 볼륨 (30%)
  static const String bgmFileName = 'Joyful_Hearts.mp3'; // 기본 BGM 파일

  // 미리 로드할 사운드 파일 목록
  static const List<String> _soundFiles = [
    'pongdang.mp3',
    'block_drop.mp3',
    'block_splash.mp3',
    'progress_increase.mp3',
    'stage_clear.mp3',
    'game_over.mp3',
  ];

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
  void initialize() async {
    if (_isInitialized) {
      return;
    }

    _configuredPoolSize = kIsWeb ? _webPoolSize : _defaultPoolSize;

    // Flame Audio 설정
    FlameAudio.updatePrefix('assets/sounds/');
    // await FlameAudio.bgm.initialize();

    _isInitialized = true;
    _log('🔊 사운드 매니저 초기화: AudioPool 최대 플레이어 = $_configuredPoolSize');

    // 모든 사운드 효과를 로컬에 캐시하고 풀을 준비합니다.
    unawaited(_preloadSounds());
  }

  /// 사운드 효과 파일을 로컬에 캐시하고 풀을 준비합니다.
  Future<void> _preloadSounds() async {
    try {
      _log('🔊 사운드 파일 프리로딩 시작...');
      await FlameAudio.audioCache.loadAll(_soundFiles);
      await FlameAudio.audioCache.load(bgmFileName);

      for (final sound in _soundFiles) {
        final pool = await FlameAudio.createPool(
          sound,
          minPlayers: 1,
          maxPlayers: _configuredPoolSize,
        );
        _audioPools[sound] = pool;
      }
      _log('🔊 ${_soundFiles.length}개의 사운드 파일 프리로딩 및 풀 준비 완료!');
    } catch (e) {
      _log('🔊 사운드 파일 프리로딩 실패: $e');
    }
  }

  /// 사운드 활성화 (사용자 상호작용 후)
  Future<void> enableSound() async {
    _initializeIfNeeded();
    _log('🔊 사운드 활성화 시도, 현재 상태: $_soundEnabled');

    if (_soundEnabled) {
      _log('🔊 사운드 이미 활성화됨');
      return;
    }

    await _ensureWebAudioUnlocked();

    // 프리로딩을 통해 사운드 지연이 해결되었으므로, 별도의 '웜업' 없이 상태만 변경합니다.
    _soundEnabled = true;
    _log('🔊 사운드 활성화 완료!');
  }

  /// 사운드 재생 (AudioPool 사용)
  void playSound(String soundFile, {double volume = 1.0}) async {
    _initializeIfNeeded();

    if (!_soundEnabled) {
      _log('🔊 사운드가 활성화되지 않음. enableSound()를 먼저 호출하세요.');
      return;
    }

    try {
      final pool = _audioPools[soundFile];
      final clampedVolume = volume.clamp(0.0, 1.0);
      if (pool != null) {
        unawaited(pool.start(volume: clampedVolume));
      } else {
        unawaited(FlameAudio.play(soundFile, volume: clampedVolume));
      }
    } catch (e) {
      _log('🔊 사운드 재생 실패: $e');
    }
  }

  /// 카드 선택 사운드 (첫 번째 튜브 선택 시)
  void playCardSelect() {
    playSound('block_drop.mp3');
  }

  /// 매칭 성공 사운드
  void playMatchSuccess() {
    playSound('pongdang.mp3', volume: 0.6);
  }

  /// 매칭 실패 사운드
  void playMatchFail() {
    playSound('bubble_pop.mp3', volume: 0.6);
  }

  /// 스테이지 클리어 사운드
  void playStageClear() {
    playSound('stage_clear.mp3', volume: 0.6);
  }

  /// 게임 오버 사운드
  void playGameOver() {
    playSound('game_over.mp3', volume: 0.5);
  }

  /// BGM 재생 (게임 시작 시)
  void playBGM({double? volume}) async {
    _initializeIfNeeded();
    if (!_bgmEnabled) return;

    try {
      await FlameAudio.audioCache.load(bgmFileName);
      await FlameAudio.bgm.play(
        bgmFileName,
        volume: (volume ?? bgmDefaultVolume).clamp(0.0, 1.0),
      );
      _log('🎵 BGM 재생 시작: $bgmFileName');
    } catch (e) {
      _log('🎵 BGM 재생 실패: $e');
    }
  }

  /// BGM 정지
  void stopBGM() async {
    if (!_isInitialized) return;
    try {
      await FlameAudio.bgm.stop();
      _log('🎵 BGM 정지');
    } catch (e) {
      _log('🎵 BGM 정지 실패: $e');
    }
  }

  /// BGM 일시정지
  void pauseBGM() async {
    if (!_isInitialized) return;
    try {
      await FlameAudio.bgm.pause();
      _log('🎵 BGM 일시정지');
    } catch (e) {
      _log('🎵 BGM 일시정지 실패: $e');
    }
  }

  /// BGM 재개
  void resumeBGM() async {
    if (!_isInitialized) return;
    try {
      await FlameAudio.bgm.resume();
      _log('🎵 BGM 재개');
    } catch (e) {
      _log('🎵 BGM 재개 실패: $e');
    }
  }

  /// BGM 볼륨 설정
  void setBGMVolume(double volume) async {
    if (!_isInitialized) return;
    try {
      await FlameAudio.bgm.audioPlayer
          .setVolume(volume.clamp(0.0, 1.0));
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

  /// 테스트 사운드 (디버깅용)
  void playTestSound() {
    playSound('block_drop.mp3');
  }

  /// 사운드 매니저 정리
  Future<void> dispose() async {
    await Future.wait(_audioPools.values.map((pool) => pool.dispose()));
    _audioPools.clear();
    await FlameAudio.bgm.dispose();
  }

  Future<void> _ensureWebAudioUnlocked() async {
    if (!kIsWeb || _webAudioUnlocked) return;
    try {
      await unlockWebAudioContext();
      _webAudioUnlocked = true;
      _log('🔊 WebAudio 컨텍스트 언락 완료');
    } catch (e) {
      _log('🔊 WebAudio 컨텍스트 언락 실패: $e');
    }
  }
}
