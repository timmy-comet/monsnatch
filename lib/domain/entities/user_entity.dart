import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;  
  final String username;
  final bool isGuest;

  const UserEntity({
    required this.uid,
    required this.username,
    this.isGuest = true, // default = guest
  });

  @override
  List<Object> get props => [uid, username, isGuest];
}