import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Please check your internet connection.', String? code})
      : super(message, code: code ?? 'NETWORK_ERROR');
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class BusinessFailure extends Failure {
  const BusinessFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Failed to load local data.', String? code})
      : super(message, code: code ?? 'CACHE_ERROR');
}
