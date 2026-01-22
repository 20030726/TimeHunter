import 'fullscreen_api_stub.dart'
    if (dart.library.html) 'fullscreen_api_web.dart';

bool get fullscreenSupported => fullscreenSupportedImpl();

bool get isFullscreen => isFullscreenImpl();

Future<void> enterFullscreen() => enterFullscreenImpl();

Future<void> exitFullscreen() => exitFullscreenImpl();

Stream<void> get onFullscreenChange => onFullscreenChangeImpl();
