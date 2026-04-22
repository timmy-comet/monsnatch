import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

class RoomFailure    extends Failure { const RoomFailure(super.message); }
class UserFailure    extends Failure { const UserFailure(super.message); }
class NetworkFailure extends Failure { const NetworkFailure(super.message); }
class AuthFailure    extends Failure { const AuthFailure(super.message); }