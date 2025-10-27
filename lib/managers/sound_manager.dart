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
  }

  /// 사운드 활성화 (사용자 상호작용 후)
  /// iOS에서는 모든 AudioPlayer를 사용자 제스처 시점에 활성화해야 함
  Future<void> enableSound() async {
    _initializeIfNeeded();
    _log('🔊 사운드 활성화 시도, 현재 상태: $_soundEnabled');

    if (_soundEnabled) {
      _log('🔊 사운드 이미 활성화됨');
      return;
    }

    try {
      // iOS에서는 모든 플레이어를 활성화해야 함
      // 매우 짧은 무음 사운드로 각 플레이어 활성화
      _log('🔊 AudioPlayer 풀 활성화 시도 (${_audioPlayerPool.length}개)...');

      final testSource = _getAssetSource('block_drop.wav');

      // 모든 플레이어를 순차적으로 활성화
      for (int i = 0; i < _audioPlayerPool.length; i++) {
        try {
          final player = _audioPlayerPool[i];
          await player.setVolume(0.0); // 무음으로 설정
          await player.play(testSource);
          await player.stop(); // 즉시 정지
          _log('🔊 플레이어 [$i] 활성화 완료');
        } catch (e) {
          _log('🔊 플레이어 [$i] 활성화 실패: $e');
        }
      }

      _soundEnabled = true;
      _log('🔊 사운드 매니저 활성화 완료! (${_audioPlayerPool.length}개 플레이어)');
    } catch (e) {
      _log('🔊 사운드 매니저 활성화 실패: $e');
      // 웹 환경에서는 사운드가 작동하지 않을 수 있으므로 강제로 활성화
      _soundEnabled = true;
      _log('🔊 웹 환경 대응: 사운드 활성화 강제 설정');
    }
  }

  /// 풀에서 다음 사용 가능한 AudioPlayer 가져오기
  AudioPlayer _getNextPlayer() {
    final player = _audioPlayerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
    return player;
  }

  /// 사운드 재생 (풀에서 다음 플레이어 사용)
  void playSound(String soundFile, {double volume = 1.0}) async {
    _initializeIfNeeded();

    // iOS에서 활성화되지 않았으면 로그만 남기고 무시
    if (!_soundEnabled) {
      _log('🔊 사운드가 활성화되지 않음. enableSound()를 먼저 호출하세요.');
      return;
    }

    try {
      final source = _getAssetSource(soundFile);

      // 풀에서 다음 플레이어 가져오기
      final player = _getNextPlayer();

      // 볼륨 설정 (0.0 ~ 1.0)
      await player.setVolume(volume.clamp(0.0, 1.0));

      // 재생 (await 없이 fire-and-forget으로 빠르게 재생)
      player.play(source);
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
    // AudioPlayer 풀 정리
    for (final player in _audioPlayerPool) {
      player.dispose();
    }
    _audioPlayerPool.clear();

    _bgmPlayer.dispose();
  }
}
