import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.uid, required super.username});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid:      json['uid']      as String,
    username: json['username'] as String,
  );
}

// Holds the full register response including the token bundle.
class RegisterResponse {
  final String uid;
  final String username;
  final String idToken;
  final String refreshToken;
  final String expiresIn;

  const RegisterResponse({
    required this.uid,
    required this.username,
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        uid:          json['uid']          as String,
        username:     json['username']     as String,
        idToken:      json['idToken']      as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn:    json['expiresIn']    as String,
      );
}

class TokenBundle {
  final String idToken;
  final String refreshToken;
  final String expiresIn;

  const TokenBundle({
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenBundle.fromJson(Map<String, dynamic> json) => TokenBundle(
    idToken:      json['idToken']      as String,
    refreshToken: json['refreshToken'] as String,
    expiresIn:    json['expiresIn']    as String,
  );
}
