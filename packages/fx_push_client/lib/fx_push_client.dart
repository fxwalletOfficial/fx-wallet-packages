/// Device subscription synchronization and notification event normalization.
///
/// The host application owns notification permission, provider SDK lifecycle,
/// secure-storage implementation, notification display, and navigation.
library fx_push_client;

export 'src/endpoint.dart';
export 'src/http_transport.dart';
export 'src/client.dart';
export 'src/message.dart';
export 'src/storage.dart';
