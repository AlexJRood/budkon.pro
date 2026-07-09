export 'document_exporter_platform_stub.dart'
    if (dart.library.html) 'document_exporter_platform_web.dart'
    if (dart.library.io) 'document_exporter_platform_io.dart';
