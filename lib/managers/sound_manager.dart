import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// 게임 사운드 효과를 관리하는 매니저 클래스
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  SoLoud? _soloud;
  final Map<String, AudioSource> _loadedSounds = {};
  AudioSource? _bgmSource;
  SoundHandle? _bgmHandle;

  bool _soundEnabled = false;
  bool _bgmEnabled = true;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  // 사운드 설정
  static const double bgmDefaultVolume = 0.01; // BGM 기본 볼륨 (1%)
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

  Future<void> _initializeIfNeeded() {
    if (_isInitialized) {
      return Future.value();
    }
    return initialize();
  }

  /// 사운드 매니저 초기화
  Future<void> initialize() {
    if (_isInitialized) {
      return Future.value();
    }
    return _initializationFuture ??= _performInitialization();
  }

  Future<void> _performInitialization() async {
    try {
      _soloud = SoLoud.instance;
      await _soloud!.init();
      _log('🔊 SoLoud 초기화 완료');

      // 프리로드 완료 후에 초기화 완료로 표시
      await _preloadAudioAssets();
      _isInitialized = true;
      _log('🔊 사운드 매니저 초기화 완료');
    } catch (e) {
      _log('🔊 SoLoud 초기화 실패: $e');
      _isInitialized = false;
      _soloud = null;
    }
  }

  Future<void> _preloadAudioAssets() async {
    // Preload sound effects
    for (final soundFile in _soundFiles) {
      try {
        final source = await _soloud!.loadAsset('assets/sounds/$soundFile');
        _loadedSounds[soundFile] = source;
      } catch (e) {
        _log('🔊 사운드 프리로드 실패 ($soundFile): $e');
      }
    }
    _log('🔊 사운드 파일 프리로딩 완료 (${_loadedSounds.length}개)');

    // Preload BGM
    try {
      _bgmSource = await _soloud!.loadAsset('assets/sounds/$bgmFileName');
      _log('🎵 BGM 캐싱 완료: $bgmFileName');
    } catch (e) {
      _log('🎵 BGM 캐싱 실패: $e');
    }
  }

  /// 사운드 활성화 (사용자 상호작용 후)
  Future<void> enableSound() async {
    await _initializeIfNeeded();
    _log('🔊 사운드 활성화 시도, 현재 상태: $_soundEnabled');

    if (_soundEnabled) {
      _log('🔊 사운드 이미 활성화됨');
      return;
    }

    _soundEnabled = true;
    _log('🔊 사운드 매니저 활성화 완료!');
  }

  /// 동기적 사운드 활성화 (iOS 크롬 대응 - 사용자 제스처 내에서 호출)
  void enableSoundSync() {
    if (_soundEnabled) {
      _log('🔊 사운드 이미 활성화됨');
      return;
    }

    // 초기화가 안 되어 있으면 나중에 다시 시도
    if (!_isInitialized) {
      _log('🔊 사운드 매니저 초기화 중... 나중에 다시 시도');
      initialize().then((_) {
        if (!_soundEnabled) {
          _soundEnabled = true;
          _log('🔊 사운드 매니저 활성화 완료 (동기)!');
        }
      });
      return;
    }

    _soundEnabled = true;
    _log('🔊 사운드 매니저 활성화 완료 (동기)!');
  }

  /// 사운드 재생
  Future<void> playSound(String soundFile, {double volume = 1.0}) async {
    // 초기화 대기
    await _initializeIfNeeded();

    // 초기화 실패 시 재생 건너뛰기
    if (!_isInitialized || _soloud == null) {
      _log('🔊 사운드 매니저가 초기화되지 않아 재생을 건너뜀 ($soundFile)');
      return;
    }

    if (!_soundEnabled) {
      await enableSound();
      if (!_soundEnabled) {
        _log('🔊 사운드가 아직 활성화되지 않아 재생을 건너뜀 ($soundFile)');
        return;
      }
    }

    try {
      final clampedVolume = volume.clamp(0.0, 1.0).toDouble();
      AudioSource? source = _loadedSounds[soundFile];

      if (source == null) {
        // 프리로드되지 않은 경우 즉시 로드
        source = await _soloud!.loadAsset('assets/sounds/$soundFile');
        _loadedSounds[soundFile] = source;
      }

      await _soloud!.play(source, volume: clampedVolume);
    } catch (e) {
      _log('🔊 사운드 재생 실패 ($soundFile): $e');
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

  /// BGM 재생 (게임 시작 시 - 캐싱된 BGM 재생)
  Future<void> playBGM({double? volume}) async {
    await _initializeIfNeeded();
    if (!_bgmEnabled || _soloud == null) return;

    try {
      // 기존 BGM 정지
      if (_bgmHandle != null) {
        await _soloud!.stop(_bgmHandle!);
        _bgmHandle = null;
      }

      // BGM 소스가 캐싱되어 있는지 확인
      if (_bgmSource == null) {
        _log('🎵 BGM 소스가 캐싱되지 않음, 재생 건너뜀');
        return;
      }

      final bgmVolume = (volume ?? bgmDefaultVolume).clamp(0.0, 1.0);

      _bgmHandle = await _soloud!.play(
        _bgmSource!,
        volume: bgmVolume,
        looping: true,
      );
      _log('🎵 BGM 재생 시작 (캐싱된 소스): $bgmFileName');
    } catch (e) {
      // BGM 재생 실패 시 조용히 무시
      _log('🎵 BGM 재생 실패: $e');
    }
  }

  /// BGM 정지
  Future<void> stopBGM() async {
    if (!_isInitialized || _soloud == null) return;
    try {
      if (_bgmHandle != null) {
        await _soloud!.stop(_bgmHandle!);
        _bgmHandle = null;
      }
      _log('🎵 BGM 정지');
    } catch (e) {
      // BGM 정지 실패 시 조용히 무시
      _log('🎵 BGM 정지 실패: $e');
    }
  }

  /// BGM 일시정지
  Future<void> pauseBGM() async {
    if (!_isInitialized || _soloud == null || _bgmHandle == null) return;
    try {
      _soloud!.pauseSwitch(_bgmHandle!);
      _log('🎵 BGM 일시정지');
    } catch (e) {
      // BGM 일시정지 실패 시 조용히 무시
      _log('🎵 BGM 일시정지 실패: $e');
    }
  }

  /// BGM 재개
  Future<void> resumeBGM() async {
    if (!_isInitialized || _soloud == null || _bgmHandle == null) return;
    try {
      _soloud!.pauseSwitch(_bgmHandle!);
      _log('🎵 BGM 재개');
    } catch (e) {
      // BGM 재개 실패 시 조용히 무시
      _log('🎵 BGM 재개 실패: $e');
    }
  }

  /// BGM 볼륨 설정
  Future<void> setBGMVolume(double volume) async {
    if (!_isInitialized || _soloud == null || _bgmHandle == null) return;
    try {
      _soloud!.setVolume(_bgmHandle!, volume.clamp(0.0, 1.0));
    } catch (e) {
      // BGM 볼륨 설정 실패 시 조용히 무시
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
    if (!_isInitialized || _soloud == null) return;
    try {
      // BGM 정지
      if (_bgmHandle != null) {
        await _soloud!.stop(_bgmHandle!);
        _bgmHandle = null;
      }

      // 로드된 모든 사운드 해제
      for (final source in _loadedSounds.values) {
        _soloud!.disposeSource(source);
      }
      _loadedSounds.clear();

      // BGM 소스 해제
      if (_bgmSource != null) {
        _soloud!.disposeSource(_bgmSource!);
        _bgmSource = null;
      }

      // SoLoud 정리
      _soloud!.deinit();
    } catch (e) {
      _log('🔊 사운드 매니저 정리 실패: $e');
    } finally {
      _initializationFuture = null;
      _isInitialized = false;
      _soundEnabled = false;
      _soloud = null;
    }
  }
}
