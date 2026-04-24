import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.uid, required super.username});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid:      json['uid']      as String,
    username: json['username'] as String,
  );
}

// Holds the full register response including the idToken.
class RegisterResponse {
  final String uid;
  final String username;
  final String idToken;

  const RegisterResponse({
    required this.uid,
    required this.username,
    required this.idToken,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        uid:      json['uid']      as String,
        username: json['username'] as String,
        idToken:  json['idToken']  as String,
      );
}
