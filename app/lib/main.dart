import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/pairing_choice_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
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

/// V1 identity: anonymous Firebase Auth + a first name, no password (see
/// services/auth_service.dart). This gate signs the device in on first
/// build, waits for a display name, then routes to pairing or home.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<String> _uidFuture = AuthService().ensureSignedIn();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _uidFuture,
      builder: (context, uidSnapshot) {
        if (!uidSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: MyPulseColors.accent)));
        }
        final uid = uidSnapshot.data!;
        return StreamBuilder<UserProfile>(
          stream: UserService().watchProfile(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: MyPulseColors.accent)));
            }
            final profile = snapshot.data!;
            if (profile.displayName.isEmpty) {
              return WelcomeScreen(uid: uid);
            }
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
      },
    );
  }
}
