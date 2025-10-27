import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 게임 사운드 효과를 관리하는 매니저 클래스
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // AudioPlayer 풀 (동시 재생을 위해)
  final List<AudioPlayer> _audioPlayerPool = [];
  static const int _poolSize = 5; // 동시에 5개까지 재생 가능
  int _currentPlayerIndex = 0;

  // 사운드 효과 캐싱을 위한 AudioCache 인스턴스
  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');
  // 캐시된 사운드의 로컬 경로를 저장하기 위한 맵
  final Map<String, String> _cachedSoundPaths = {};

  late AudioPlayer _bgmPlayer; // BGM 전용 플레이어
  bool _soundEnabled = false;
  bool _bgmEnabled = true;
  bool _isInitialized = false;

  // 사운드 설정
  static const double bgmDefaultVolume = 0.3; // BGM 기본 볼륨 (30%)
  static const String bgmFileName = 'Joyful_Hearts.mp3'; // 기본 BGM 파일

  // 미리 로드할 사운드 파일 목록
  static const List<String> _soundFiles = [
    'pingddang.wav',
    'block_splash.wav',
    'progress_increase.wav',
    'stage_clear.wav',
    'game_over.wav',
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

    // AudioPlayer 풀 초기화
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      // 각 플레이어의 오디오 컨텍스트 설정 (iOS/Android)
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      _audioPlayerPool.add(player);
    }

    // BGM 플레이어 초기화
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    _isInitialized = true;
    _log('🔊 사운드 매니저 초기화: AudioPlayer 풀 크기 = $_poolSize');

    // 모든 사운드 효과를 로컬에 캐시하고 경로를 저장합니다.
    unawaited(_preloadSounds());
  }

  /// 사운드 효과 파일을 로컬에 캐시하고 그 경로를 맵에 저장합니다.
  Future<void> _preloadSounds() async {
    try {
      _log('🔊 사운드 파일 프리로딩 시작...');
      final loadedFiles = await _audioCache.loadAll(_soundFiles);
      for (int i = 0; i < _soundFiles.length; i++) {
        _cachedSoundPaths[_soundFiles[i]] = loadedFiles[i].path;
      }
      _log('🔊 ${_soundFiles.length}개의 사운드 파일 프리로딩 완료!');
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

    // 프리로딩을 통해 사운드 지연이 해결되었으므로, 별도의 '웜업' 없이 상태만 변경합니다.
    // iOS에서는 첫 사용자 인터랙션이 발생하면 오디오 컨텍스트가 활성화됩니다.
    _soundEnabled = true;
    _log('🔊 사운드 활성화 완료!');
  }

  /// 풀에서 다음 사용 가능한 AudioPlayer 가져오기
  AudioPlayer _getNextPlayer() {
    final player = _audioPlayerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
    return player;
  }

  /// 사운드 재생 (캐시된 로컬 파일 사용)
  void playSound(String soundFile, {double volume = 1.0}) async {
    _initializeIfNeeded();

    if (!_soundEnabled) {
      _log('🔊 사운드가 활성화되지 않음. enableSound()를 먼저 호출하세요.');
      return;
    }

    try {
      // 웹 환경(iOS Chrome/Safari 포함)에서는 로컬 파일 경로가 의미가 없으므로 항상 AssetSource 사용
      if (kIsWeb) {
        final player = _getNextPlayer();
        // iOS 웹 안정성: 이전 재생 정리 및 볼륨 설정 완료 후 재생
        await player.stop();
        await player.setVolume(volume.clamp(0.0, 1.0));
        await player.play(AssetSource('sounds/$soundFile'));
        return;
      }

      final path = _cachedSoundPaths[soundFile];
      if (path == null) {
        _log('🔊 경고: 캐시된 사운드를 찾을 수 없음: $soundFile. AssetSource로 재생 시도.');
        // 캐시 실패 시 대비책으로 AssetSource 사용
        final player = _getNextPlayer();
        await player.stop();
        await player.setVolume(volume.clamp(0.0, 1.0));
        await player.play(AssetSource('sounds/$soundFile'));
        return;
      }

      final player = _getNextPlayer();
      await player.stop();
      await player.setVolume(volume.clamp(0.0, 1.0));
      // DeviceFileSource를 사용하여 로컬에 캐시된 파일을 직접 재생합니다.
      await player.play(DeviceFileSource(path));
    } catch (e) {
      _log('🔊 사운드 재생 실패: $e');
    }
  }

  /// 카드 선택 사운드 (첫 번째 튜브 선택 시)
  void playCardSelect() {
    playSound('progress_increase.wav');
  }

  /// 매칭 성공 사운드
  void playMatchSuccess() {
    playSound('pongdang.wav',volume: 0.6);
  }

  /// 매칭 실패 사운드
  void playMatchFail() {
    playSound('block_splash.wav', volume: 0.6);
  }

  /// 스테이지 클리어 사운드
  void playStageClear() {
    playSound('stage_clear.wav', volume: 0.6);
  }

  /// 게임 오버 사운드
  void playGameOver() {
    playSound('game_over.wav', volume: 0.5);
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
      // BGM은 스트리밍되므로 AssetSource를 직접 사용합니다.
      await _bgmPlayer.play(AssetSource('sounds/$bgmFileName'));
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

  /// 테스트 사운드 (디버깅용)
  void playTestSound() {
    playSound('block_drop.wav');
  }

  /// 사운드 매니저 정리
  void dispose() {
    _audioCache.clearAll(); // 캐시 정리
    // AudioPlayer 풀 정리
    for (final player in _audioPlayerPool) {
      player.dispose();
    }
    _audioPlayerPool.clear();

    _bgmPlayer.dispose();
  }
}
