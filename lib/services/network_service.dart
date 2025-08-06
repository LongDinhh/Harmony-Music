import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../utils/error_handler.dart';
import 'constant.dart';

/// Abstract interface cho Network Service
abstract class INetworkService {
  Future<Response> sendRequest(
    String url, {
    String method = 'POST',
    Map<String, String>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  Future<Response> get(String url, {Map<String, String>? headers});
  Future<Response> post(String url,
      {Map<String, String>? headers, dynamic data});

  void updateHeaders(Map<String, String> newHeaders);
  void configureSecurity();
  void close();
}

/// Concrete implementation của Network Service
class NetworkService extends getx.GetxService implements INetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();

  NetworkService._();

  Dio? _dioInstance;
  final Map<String, String> _defaultHeaders = {
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': domain,
    'X-Goog-AuthUser': '0',
  };

  Dio get _dio {
    if (_dioInstance == null) {
      _dioInstance = Dio();
      _configureDioOptions();
    }
    return _dioInstance!;
  }

  @override
  void onInit() {
    super.onInit();
    configureSecurity();
  }

  void _configureDioOptions() {
    _dio.options = BaseOptions(
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept-Encoding': 'gzip, deflate',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        ..._defaultHeaders,
      },
    );
  }

  @override
  void configureSecurity() {
    // Ensure Dio is initialized and configured
    _configureDioOptions();
  }

  @override
  void updateHeaders(Map<String, String> newHeaders) {
    _defaultHeaders.addAll(newHeaders);
    _dio.options.headers.addAll(newHeaders);
  }

  @override
  Future<Response> sendRequest(
    String url, {
    String method = 'POST',
    Map<String, String>? headers,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _retryRequest(() async {
      final options = Options(
        method: method,
        headers: {..._defaultHeaders, ...?headers},
      );

      final response = await _dio.request(
        url,
        options: options,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }

      return response;
    });
  }

  @override
  Future<Response> get(String url, {Map<String, String>? headers}) async {
    return await sendRequest(
      url,
      method: 'GET',
      headers: headers,
    );
  }

  @override
  Future<Response> post(String url,
      {Map<String, String>? headers, dynamic data}) async {
    return await sendRequest(
      url,
      method: 'POST',
      headers: headers,
      data: data,
    );
  }

  /// Retry logic với exponential backoff
  Future<Response> _retryRequest(Future<Response> Function() requestFn) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await requestFn();
      } on DioException catch (e) {
        if (attempt == 2) {
          AppErrorHandler.handleError(e, null,
              context: 'Network request failed after 3 attempts');
          throw NetworkError(message: 'Request failed after 3 attempts');
        }

        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(milliseconds: 1000 * (1 << attempt)));
      } catch (e) {
        if (attempt == 2) {
          AppErrorHandler.handleError(e, null,
              context: 'Unexpected error in network request');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 1000 * (1 << attempt)));
      }
    }
    throw NetworkError(message: 'Network request failed');
  }

  /// Thêm interceptor cho request/response handling
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Xóa tất cả interceptors
  void clearInterceptors() {
    _dio.interceptors.clear();
  }

  @override
  void close() {
    _dioInstance?.close();
    _dioInstance = null;
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}

/// Custom Network Error class
class NetworkError extends Error {
  final String message;

  NetworkError({this.message = "Network Error occurred"});

  @override
  String toString() => 'NetworkError: $message';
}
