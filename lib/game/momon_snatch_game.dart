import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../presentation/blocs/game/game_bloc.dart';
import 'world/game_world.dart';

class MonSnatchGame extends FlameGame<GameWorld> with DragCallbacks {
  final GameBloc bloc;

  MonSnatchGame({required this.bloc})
      : super(world: GameWorld(), camera: CameraComponent());

  @override
  Color backgroundColor() => const Color(0xFFF5F5F5);
}