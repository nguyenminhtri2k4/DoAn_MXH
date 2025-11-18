import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _endcallPlayer = AudioPlayer();

  SoundService._internal();

  /// Phát chuông khi có cuộc gọi đến
  Future<void> playIncomingCall() async {
    try {
      await _ringtonePlayer.stop();
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop); // Lặp chuông
      await _ringtonePlayer.play(
        AssetSource('sounds/commingcall.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      print('Error playing incoming call sound: $e');
    }
  }

  /// Dừng nhạc chuông (đổi lại đúng tên stopRingtone)
  Future<void> stopRingtone() async {
    try {
      await _ringtonePlayer.stop();
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }

  /// Phát âm thanh khi kết thúc cuộc gọi
  Future<void> playEndCall() async {
    try {
      await _endcallPlayer.stop();
      await _endcallPlayer.setReleaseMode(ReleaseMode.stop);
      await _endcallPlayer.play(
        AssetSource('sounds/endcall.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      print('Error playing end call sound: $e');
    }
  }

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await _ringtonePlayer.dispose();
    await _endcallPlayer.dispose();
  }
}
