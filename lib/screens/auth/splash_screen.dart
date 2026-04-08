// Save as: lib/screens/auth/splash_screen.dart

import 'package:flutter/material.dart';
import '../../theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color:        C.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Agentda',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.textPri)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: C.textMuted),
            ),
          ]),
        ),
      );
}