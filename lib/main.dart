import 'package:flutter/material.dart';
import 'package:omni/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import './pages/profile.dart';
import './pages/assistant.dart';
import './widgets/auth_gate.dart';
import './widgets/custom_app_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'omni',
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: const ColorScheme(
          primary: Color(0xFF097d4c),
          onPrimary: Color(0xFFf1ead1),
          secondary: Color(0xFF2f8a97),
          onSecondary: Color(0xFFf1ead1),
          error: Color(0xFFd14938),
          onError: Color(0xFFf1ead1),
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFf1ead1),
            textStyle: const TextStyle(
              fontFamily: 'Arial',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/assistant': (context) => Assistant(),
        '/login': (context) => const Login(),
        '/register': (context) => const Registration(),
        '/profile': (context) => AuthGate(page: Profile()),
      },
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 350,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.secondary,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalized learning app for every ability',
                            style: TextStyle(
                              fontFamily: 'Hobo',
                              color: theme.colorScheme.onPrimary,
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'We support learners and educators in developing transition pathways that deliver the most value to persons with disabilities.',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: theme.colorScheme.onPrimary,
                                  foregroundColor: theme.colorScheme.secondary,
                                ),
                                child: const Text(
                                  'Get Started',
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/assistant');
                                },
                                style: TextButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.onPrimary,
                                    width: 2,
                                  ),
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                child: const Text(
                                  'Learn More',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      color: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.all(30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/cover_image.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white, // Set the background color to white
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 16.0),
                  //   child: Text(
                  //     'Education without barriers',
                  //     style: TextStyle(
                  //         fontSize: 30,
                  //         fontFamily: 'Hobo',
                  //         fontWeight: FontWeight.bold,
                  //         color: Colors.black),
                  //   ),
                  // ),
                  SizedBox(
                    height: 300, // Specify a fixed height for the Row
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/red_sticker.png',
                                height: 200,
                                width: 200,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Interactive tools to help learners achieve developmental milestones',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/green_sticker.png',
                                height: 200,
                                width: 200,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Comprehensive resources to facilitate a wide variety of transition skill activities',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/yellow_sticker.png',
                                height: 200,
                                width: 200,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Collaborative assessment and progress tracking platform to enable better outcomes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
