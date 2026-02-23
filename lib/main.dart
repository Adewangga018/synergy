import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synergy/services/notification_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale untuk DateFormat Indonesia
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dswirqyxefvscpdobknb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lycXl4ZWZ2c2NwZG9ia25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwNTM1NjIsImV4cCI6MjA4NjYyOTU2Mn0.s3Fl9aAYXds0tKTwiSGo0mgBu4cdx8V-iwPX8gdk7PA',
  );

  // Initialize Notification Service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synergy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF013880),
          primary: const Color(0xFF013880),
          secondary: const Color(0xFF0078C1),
          background: const Color(0xFFFFFFFF),
          surface: const Color(0xFFF4F4F4),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        cardColor: const Color(0xFFF4F4F4),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
          bodySmall: TextStyle(color: Color(0xFF333333)),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Widget untuk mengecek status autentikasi
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isValidating = true;
  bool _isSessionValid = false;

  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  /// Validate session and force logout if JWT is invalid
  Future<void> _validateSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        print('❌ No session found');
        setState(() {
          _isValidating = false;
          _isSessionValid = false;
        });
        return;
      }

      print('🔍 Validating session...');
      print('📋 Current access token (first 30 chars): ${session.accessToken.substring(0, 30)}...');
      
      // Try to refresh session to validate JWT
      final response = await Supabase.instance.client.auth.refreshSession();
      
      if (response.session == null) {
        print('❌ Session refresh failed - invalid JWT');
        // Force logout and clear storage
        await _forceLogoutAndClearStorage();
        setState(() {
          _isValidating = false;
          _isSessionValid = false;
        });
      } else {
        print('✅ Session refreshed');
        print('📋 New access token (first 30 chars): ${response.session!.accessToken.substring(0, 30)}...');
        
        setState(() {
          _isValidating = false;
          _isSessionValid = true;
        });
      }
    } catch (e) {
      print('❌ Session validation error: $e');
      // Force logout on any error
      await _forceLogoutAndClearStorage();
      
      setState(() {
        _isValidating = false;
        _isSessionValid = false;
      });
    }
  }

  /// Force logout and clear all browser storage
  Future<void> _forceLogoutAndClearStorage() async {
    try {
      print('🧹 Clearing storage and logging out...');
      await Supabase.instance.client.auth.signOut();
    } catch (logoutError) {
      print('⚠️ Error during logout: $logoutError');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memvalidasi sesi login...'),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Jika masih loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika ada session (user sudah login)
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null && _isSessionValid) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
