import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/services/api_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/placeholder_screen.dart';
import 'features/kasir/screens/kasir_screen.dart';
import 'features/kasir/screens/checkout_screen.dart';

void main() {
  ApiService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const SplashRouter(),
        '/kasir': (_) => const KasirScreen(),
        '/admin': (_) => const AdminPlaceholderScreen(),
        '/checkout': (_) => const CheckoutScreen(),
      },
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final auth = context.read<AuthProvider>();
    final hasSession = await auth.checkSession();
    if (!mounted) return;
    if (hasSession) {
      Navigator.pushReplacementNamed(
        context,
        auth.role == 'admin' ? '/admin' : '/kasir',
      );
    }
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}