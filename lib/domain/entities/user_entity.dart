import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String username;

  const UserEntity({required this.uid, required this.username});

  @override
  List<Object> get props => [uid, username];
}
