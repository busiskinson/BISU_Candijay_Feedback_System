import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';
import 'screens/customer/customer_dashboard.dart';
import 'utils/app_keys.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/feedback_management_screen.dart';
import 'screens/admin/offices_management_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/users_management_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/qa/qa_reports_screen.dart';
import 'screens/qa/qa_dashboard.dart';
import 'screens/director/approved_reports_screen.dart';
import 'screens/director/director_dashboard.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CustomerSatisfactionSystem());
}

class CustomerSatisfactionSystem extends StatelessWidget {
  const CustomerSatisfactionSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Customer Satisfaction System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: kIsWeb ? const WelcomeScreen() : const CustomerDashboard(),
      routes: {
        '/adminDashboard': (context) => const AdminDashboard(),
        '/adminFeedback': (context) => const FeedbackManagementScreen(),
        '/adminOffices': (context) => const OfficesManagementScreen(),
        '/adminReports': (context) => const ReportsScreen(),
        '/adminUsers': (context) => const UsersManagementScreen(),
        '/qaDashboard': (context) => const QaDashboard(),
        '/qaReports': (context) => const QaReportsScreen(),
        '/directorDashboard': (context) => const DirectorDashboard(),
        '/directorReports': (context) => const ApprovedReportsScreen(),

      },
    );
  }
}

// Kept for reference — this is the screen you used earlier to confirm
// Firebase Authentication + Firestore writes were working.
// It's no longer the home screen, but the code stays here so we can
// reuse the registerUser()/loginUser() logic when we build the real
// Sign Up and Login screens.
class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String message = '';

  Future<void> registerUser() async {
    try {
      UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        message = 'Account and user profile created successfully!';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        message = e.message ?? 'Registration failed.';
      });
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  Future<void> loginUser() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() {
        message = 'Login successful!';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        message = e.message ?? 'Login failed.';
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: registerUser,
                child: const Text('Create Account'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: loginUser,
                child: const Text('Login'),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}