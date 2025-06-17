import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../models/level_model.dart';
import './game_screen.dart';

class LevelSelectorScreen extends StatelessWidget {
  const LevelSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // GameProvider's constructor already calls loadAllLevels.
    // We can call it here again if we want to ensure it's loaded if the provider was already alive
    // but levels were not loaded for some reason, or if we want a "refresh" capability.
    // For this initial build, we assume GameProvider handles its initial loading.
    // Provider.of<GameProvider>(context, listen: false).loadAllLevels(); // Example of manual trigger

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez un niveau'),
      ),
      body: Consumer2<GameProvider, AuthProvider>(
        builder: (context, gameProvider, authProvider, child) {
          if (gameProvider.isLoading || (authProvider.isLoading && authProvider.currentUser == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameProvider.allLevels.isEmpty && !gameProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun niveau trouvé.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => gameProvider.loadAllLevels(), // Manual reload
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Sort levels by their 'level' property just in case they aren't already
          final sortedLevels = List<Level>.from(gameProvider.allLevels);
          sortedLevels.sort((a, b) => a.level.compareTo(b.level));

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: sortedLevels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // Adjust for desired number of columns
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemBuilder: (context, index) {
              final level = sortedLevels[index];
              final bool isUnlocked = authProvider.currentUser?.unlockedLevels.contains(level.level) ?? false;
              // Consider a level "completed" if the next level is unlocked (and it's not the first level)
              // This is a basic heuristic. A dedicated 'completedLevels' list in UserModel would be better.
              final bool isCompleted = (level.level > 1 && (authProvider.currentUser?.unlockedLevels.contains(level.level + 1) ?? false)) ||
                                       (level.level == 1 && (authProvider.currentUser?.unlockedLevels.length ?? 0) > 1 && authProvider.currentUser!.unlockedLevels.contains(2));


              Color itemColor = Colors.grey.shade700; // Locked by default
              IconData? iconData;

              if (isUnlocked) {
                itemColor = Colors.green.shade600; // Unlocked
                if (isCompleted) {
                  itemColor = Colors.blue.shade600; // Completed (e.g. next one is unlocked)
                  iconData = Icons.check_circle_outline;
                } else {
                  // Unlocked but not necessarily completed (e.g. current playable level)
                   iconData = Icons.play_circle_outline;
                }
              } else {
                iconData = Icons.lock_outline;
              }

              return GestureDetector(
                onTap: () {
                  if (isUnlocked) {
                    gameProvider.selectLevelById(level.level);
                    if (gameProvider.currentLevel != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(level: gameProvider.currentLevel!),
                        ),
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erreur lors de la sélection du niveau.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Niveau ${level.level} verrouillé !')),
                    );
                  }
                },
                child: Card(
                  elevation: 3.0,
                  color: itemColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (iconData != null)
                        Icon(iconData, size: 30.0, color: Colors.white),
                      const SizedBox(height: 8.0),
                      Text(
                        '${level.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
