import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/pairing_choice_screen.dart';
import 'services/user_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyPulseApp());
}

class MyPulseApp extends StatelessWidget {
  const MyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPulse',
      debugShowCheckedModeBanner: false,
      theme: buildMyPulseTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Routes to pairing or home depending on whether the signed-in user already
/// belongs to a couple. Real account creation/sign-in (email, phone, Google…)
/// is a separate concern not specified yet — this assumes FirebaseAuth
/// already has a current user by the time this widget builds.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Connexion requise')));
    }
    return StreamBuilder<UserProfile>(
      stream: UserService().watchProfile(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: MyPulseColors.accent)));
        }
        final profile = snapshot.data!;
        if (profile.coupleId == null) {
          return const PairingChoiceScreen();
        }
        return StreamBuilder<String>(
          stream: UserService().watchPartnerName(profile.coupleId!, uid),
          builder: (context, partnerSnapshot) {
            return HomeScreen(coupleId: profile.coupleId!, partnerName: partnerSnapshot.data ?? '…');
          },
        );
      },
    );
  }
}
