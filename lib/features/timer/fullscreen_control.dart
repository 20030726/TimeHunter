import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/web/fullscreen_api.dart';

class FullscreenControl extends StatefulWidget {
  const FullscreenControl({super.key, this.compact = false});

  final bool compact;

  @override
  State<FullscreenControl> createState() => _FullscreenControlState();
}

class _FullscreenControlState extends State<FullscreenControl> {
  late bool _isFullscreen;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _isFullscreen = isFullscreen;
    _subscription = onFullscreenChange.listen((_) {
      if (!mounted) return;
      setState(() {
        _isFullscreen = isFullscreen;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isFullscreen) {
      await exitFullscreen();
    } else {
      await enterFullscreen();
    }
    if (!mounted) return;
    setState(() {
      _isFullscreen = isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!fullscreenSupported) return const SizedBox.shrink();

    final icon =
        _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen;

    if (widget.compact) {
      return TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Colors.black.withValues(alpha: 0.25),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: _toggle,
        child: Icon(icon, size: 16),
      );
    }

    return TextButton.icon(
      icon: Icon(icon),
      label: Text(_isFullscreen ? '退出全螢幕' : '全螢幕'),
      onPressed: _toggle,
    );
  }
}
