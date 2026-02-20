import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../services/local_storage_service.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';
import 'providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check if app was launched from widget
    final Uri? launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launchUri != null) {
      print('App launched from widget with URI: $launchUri');
      // You can handle specific navigation based on the URI here
    }

    if (!mounted) return;

    if (LocalStorageService.isLoggedIn) {
      final savedUser = LocalStorageService.savedUser;
      if (savedUser != null) {
        ref.read(authProvider).restoreUser(savedUser);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
