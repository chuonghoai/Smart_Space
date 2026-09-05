export 'core/api/api_client.dart';
export 'core/api/api_response.dart';
export 'core/api/pagination.dart';
export 'core/auth/access_token_service.dart';
export 'core/auth/refresh_token_service.dart';
export 'core/auth/user_storage_service.dart';
export 'core/auth/models/user_model.dart';
export 'core/config/env_config.dart';
export 'core/connection/connection_manager.dart';
export 'core/connection/connection_state_provider.dart';
export 'core/constants/registration_status.dart';
export 'core/constants/role_constant.dart';
export 'core/exceptions/connection_exception.dart';
export 'core/interceptors/auth_interceptor.dart';
export 'core/interceptors/error_interceptor.dart';
export 'core/notification/firebase_service.dart';
export 'core/storage/secured_storage.dart';
export 'core/storage/shared_preferences.dart';
export 'core/theme/app_theme.dart';
export 'core/toast/toast_service.dart';
export 'util/device_info_util.dart';
export 'core/websocket/websocket_service.dart';
export 'core/widgets/confirm_dialog.dart';

export 'util/distance_updater_provider.dart';
export 'util/location_service.dart';
export 'util/media_upload.dart';

export 'l10n/generated/shared_localizations.dart';
export 'util/distance_formatter.dart';

/// Returns a greeting message to verify shared package integration.
String getSharedGreeting(String appName) {
  return 'Hello from mobile_shared to $appName!';
}
