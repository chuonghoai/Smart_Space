import 'package:dio/dio.dart';
import '../localization/locale_provider.dart';

class LanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = localeProvider.locale.languageCode;
    super.onRequest(options, handler);
  }
}
