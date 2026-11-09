import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

Failure mapDioFailure(Object error) {
  if (error is Failure) return error;
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final message = _messageFromResponse(data) ?? _networkMessage(error);
    switch (status) {
      case 401:
        return AuthFailure(message);
      case 403:
        return ForbiddenFailure(message);
      case 404:
        return NotFoundFailure(message);
      case 409:
        return ConflictFailure(message);
      case 422:
        return ValidationFailure(message);
      case 500:
        return ServerFailure(message);
      default:
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          return const NetworkFailure(
            'تعذر الاتصال بالخادم. تحقق من الشبكة وتشغيل Laravel.',
          );
        }
        return ServerFailure(message);
    }
  }
  return const ServerFailure('حدث خطأ غير متوقع. حاول مرة أخرى.');
}


// _ -> تعني ان الداله يمنع استدعائها خارج الملف
String? _messageFromResponse(dynamic data) {
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
      }
    }
  }
  return null;
}

String _networkMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'انتهت مهلة الاتصال بالخادم.';
    case DioExceptionType.connectionError:
      return 'تعذر الاتصال بالخادم.';
    default:
      return 'تعذر تنفيذ الطلب.';
  }
}
