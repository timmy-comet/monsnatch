import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/get_user.dart';
import '../../../domain/usecases/save_user.dart';

class UserBloc extends Cubit<UserEntity?> {
  final GetUser getUser;
  final SaveUser saveUser;

  UserBloc({
    required this.getUser,
    required this.saveUser,
  }) : super(null);

  Future<void> loadUser() async {
    final user = await getUser();
    emit(user);
  }

  Future<void> createGuest(String username) async {
    final user = await saveUser(username);
    emit(user);
  }
}