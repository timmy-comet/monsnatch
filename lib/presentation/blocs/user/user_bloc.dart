import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/get_user.dart';
import '../../../domain/usecases/save_user.dart';
import '../../../data/datasources/auth_local_datasource.dart';

// ── States ───────────────────────────────────────────────
sealed class UserState extends Equatable {
  const UserState();
  @override List<Object?> get props => [];
}
class UserInitial  extends UserState { const UserInitial(); }
class UserLoading  extends UserState { const UserLoading(); }
class UserLoaded   extends UserState {
  final UserEntity user;
  const UserLoaded(this.user);
  @override List<Object> get props => [user];
}
class UserNotFound extends UserState { const UserNotFound(); }
class UserError    extends UserState {
  final String message;
  const UserError(this.message);
  @override List<Object> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────
class UserBloc extends Cubit<UserState> {
  final GetUser            getUser;
  final SaveUser           saveUser;
  final AuthLocalDataSource authLocal;

  UserBloc({
    required this.getUser,
    required this.saveUser,
    required this.authLocal,
  }) : super(const UserInitial());

  Future<void> loadUser() async {
    emit(const UserLoading());
    final user = await getUser();
    if (user != null) {
      emit(UserLoaded(user));
    } else {
      emit(const UserNotFound());
    }
  }

  Future<void> createGuest(String username) async {
    emit(const UserLoading());
    try {
      final user = await saveUser(username);
      emit(UserLoaded(user));
    } on UserFailure catch (f) {
      emit(UserError(f.message));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> clearUser() async {
    await authLocal.clearAuth();
    emit(const UserNotFound());
  }
}