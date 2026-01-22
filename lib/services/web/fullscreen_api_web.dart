import 'dart:html' as html;

bool fullscreenSupportedImpl() => html.document.documentElement != null;

bool isFullscreenImpl() => html.document.fullscreenElement != null;

Future<void> enterFullscreenImpl() async {
  await html.document.documentElement?.requestFullscreen();
}

Future<void> exitFullscreenImpl() async {
  if (html.document.fullscreenElement != null) {
    html.document.exitFullscreen();
  }
}

Stream<void> onFullscreenChangeImpl() {
  return html.document.onFullscreenChange.map((_) => null);
}
