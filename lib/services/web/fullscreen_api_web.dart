// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
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
  return html.document.onFullscreenChange.map((_) {});
}
