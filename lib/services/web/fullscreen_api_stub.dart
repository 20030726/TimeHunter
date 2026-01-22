bool fullscreenSupportedImpl() => false;

bool isFullscreenImpl() => false;

Future<void> enterFullscreenImpl() async {}

Future<void> exitFullscreenImpl() async {}

Stream<void> onFullscreenChangeImpl() => const Stream.empty();
