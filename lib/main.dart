import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dswirqyxefvscpdobknb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lycXl4ZWZ2c2NwZG9ia25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwNTM1NjIsImV4cCI6MjA4NjYyOTU2Mn0.s3Fl9aAYXds0tKTwiSGo0mgBu4cdx8V-iwPX8gdk7PA',
  );

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
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
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
        
        if (session != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
