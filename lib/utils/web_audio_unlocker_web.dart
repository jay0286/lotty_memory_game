// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:js_util' as js_util;

/// Unlocks the WebAudio context by resuming it and playing a short silent buffer.
Future<void> unlockWebAudioContext() async {
  final ctor = _audioContextConstructor();
  if (ctor == null) {
    return;
  }

  final context = js_util.callConstructor(ctor, []);

  final state = js_util.getProperty(context, 'state') as String?;
  if (state == 'suspended') {
    await js_util.promiseToFuture(js_util.callMethod(context, 'resume', []));
  }

  final sampleRate =
      (js_util.getProperty(context, 'sampleRate') as num?)?.toDouble() ??
      44100.0;
  final buffer = js_util.callMethod(context, 'createBuffer', [1, 1, sampleRate]);
  final source = js_util.callMethod(context, 'createBufferSource', []);
  js_util.setProperty(source, 'buffer', buffer);

  final destination = js_util.getProperty(context, 'destination');
  if (destination != null) {
    js_util.callMethod(source, 'connect', [destination]);
  }

  js_util.callMethod(source, 'start', [0]);
  // Give the browser a small moment to register the playback.
  await Future<void>.delayed(const Duration(milliseconds: 10));
  js_util.callMethod(source, 'stop', [0]);
  js_util.callMethod(source, 'disconnect', []);
}

Object? _audioContextConstructor() {
  final global = js_util.globalThis;
  final ctor = js_util.getProperty(global, 'AudioContext');
  if (ctor != null) {
    return ctor;
  }
  final webkitCtor = js_util.getProperty(global, 'webkitAudioContext');
  if (webkitCtor != null) {
    return webkitCtor;
  }
  return null;
}
