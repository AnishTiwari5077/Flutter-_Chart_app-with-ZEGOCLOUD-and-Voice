import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_chart/services/voice_recorder_services.dart';

class VoiceRecorderButton extends StatefulWidget {
  final Function(String audioPath, Duration duration) onRecordingComplete;

  const VoiceRecorderButton({super.key, required this.onRecordingComplete});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final VoiceRecorderService _recorderService = VoiceRecorderService();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _recorderService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _recorderService.startRecording();
    if (!success) return;

    setState(() => _isRecording = true);
    _recordingDuration = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorderService.stopRecording();
    setState(() => _isRecording = false);

    if (path != null) {
      widget.onRecordingComplete(path, _recordingDuration);
    }

    _recordingDuration = Duration.zero;
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorderService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isRecording) {
      return GestureDetector(
        onLongPressStart: (_) => _startRecording(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 260), // ✅ bounded width
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancel
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Red dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            _format(_recordingDuration),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),

          const SizedBox(width: 10),

          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '◀ Slide to cancel',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error.withValues(alpha: .7),
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: .85),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
