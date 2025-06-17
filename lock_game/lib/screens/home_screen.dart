import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import './level_selector.dart';
import './settings_screen.dart';
import './tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lock Game'),
        actions: [
          // Example: Add a settings IconButton if not using a button in the body
          // IconButton(
          //   icon: Icon(Icons.settings),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const SettingsScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
            children: <Widget>[
              const AppLogo(),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isLoading && authProvider.currentUser == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (authProvider.currentUser != null) {
                    return Text(
                      'Points: ${authProvider.currentUser!.points}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    );
                  } else {
                    // Not logged in or user data not loaded yet but not actively loading auth
                    // (e.g. initial state before auth stream fires, or after sign out)
                    return Text(
                      'Welcome!', // More generic welcome
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    );
                  }
                },
              ),
              const SizedBox(height: 20), // Spacer
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Commencer'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LevelSelectorScreen()),
                  );
                },
              ),
              const SizedBox(height: 15), // Spacer
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Comment jouer'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TutorialScreen()),
                  );
                },
              ),
              const SizedBox(height: 15), // Spacer
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Paramètres'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 30), // Spacer at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
