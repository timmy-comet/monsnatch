import 'package:flutter/material.dart';
import '../widgets/bubbly_background.dart';
import 'lobby_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BubblyBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'MOMON\nSNATCH',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 52, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 4,
                  shadows: [Shadow(color: Color(0xFFAA00FF), blurRadius: 30)],
                ),
              ),
              const SizedBox(height: 60),
              ScaleTransition(
                scale: _scale,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: const Color(0xFF1A0050),
                    minimumSize: const Size(220, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 10,
                    shadowColor: const Color(0xFFFFD600).withOpacity(0.6),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LobbyPage(lobbyId: 'lobby_001')),
                  ),
                  child: const Text('START GAME',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}