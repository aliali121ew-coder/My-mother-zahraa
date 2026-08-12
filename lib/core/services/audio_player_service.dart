import 'package:audioplayers/audioplayers.dart';

/// مشغّل الصوتيات الحقيقي الموحد لموكب أمنا الزهراء (MP3 Real Streams)
class RealAudioPlayerService {
  RealAudioPlayerService._();
  static final RealAudioPlayerService instance = RealAudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  /// تشغيل أو تبديل مقطع صوتي مسموع حقيقي عبر رابط MP3
  Future<void> playOrToggle(String audioUrl, {required Function(bool isPlaying) onStateChanged}) async {
    try {
      if (_currentlyPlayingUrl == audioUrl && _isPlaying) {
        await _player.pause();
        _isPlaying = false;
        onStateChanged(false);
      } else {
        await _player.stop();
        _currentlyPlayingUrl = audioUrl;
        await _player.play(UrlSource(audioUrl));
        _isPlaying = true;
        onStateChanged(true);
      }
    } catch (e) {
      _isPlaying = false;
      onStateChanged(false);
    }
  }

  /// إيقاف التشغيل
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentlyPlayingUrl = null;
    } catch (_) {}
  }
}
