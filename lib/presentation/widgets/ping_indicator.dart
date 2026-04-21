import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/connectivity/connectivity_bloc.dart';
import '../blocs/connectivity/connectivity_state.dart';
import '../../core/network/realtime_watcher.dart';

class PingIndicator extends StatelessWidget {
  const PingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (_, state) {
        final (color, label) = switch (state.quality) {
          ConnectionQuality.good    => (Colors.green, '●'),
          ConnectionQuality.fair    => (Colors.orange, '●'),
          ConnectionQuality.poor    => (Colors.red, '●'),
          ConnectionQuality.offline => (Colors.grey, '○'),
        };
        return Tooltip(
          message: state.quality.name.toUpperCase(),
          child: Text(label, style: TextStyle(color: color, fontSize: 16)),
        );
      },
    );
  }
}