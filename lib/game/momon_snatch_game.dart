import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'world/game_world.dart';

class MonSnatchGame extends FlameGame<GameWorld>
    with DragCallbacks, HasCollisionDetection {

  MonSnatchGame()
      : super(world: GameWorld());

  @override
  Color backgroundColor() => const Color(0xFFF0F0F0);
}