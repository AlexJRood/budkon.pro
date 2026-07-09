import 'dart:ui_web' as ui;
import 'dart:html' as html;

void registerViewFactory(String viewTypeId, dynamic factoryFn) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewTypeId, factoryFn);
}

void registerPdfViewer(String viewId, String url) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
void registerVideoViewer(String viewId, String url) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final video = html.VideoElement()
      ..src = url
      ..controls = true
      ..autoplay = false
      ..style.width = '100%'
      ..style.maxHeight = '60vh'
      ..style.borderRadius = '10px';
    return video;
  });
}