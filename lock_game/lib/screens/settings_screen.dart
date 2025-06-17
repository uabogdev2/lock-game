import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
// import './home_screen.dart'; // Not strictly needed if using popUntil isFirst

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      // Pop until the first route in the stack (usually the initial screen like HomeScreen or a login wrapper)
      // This assumes that your app's root widget handles auth state changes to redirect appropriately.
      if (context.mounted) { // Ensure widget is still in the tree
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Handle error, e.g., show a SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de déconnexion: ${e.toString()}')),
        );
      }
    }
  }

  void _contactSupport(BuildContext context) {
    // In a real app, this could open a URL, mail client, or a dedicated support form.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support: contact@examplelockgame.com (Placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: <Widget>[
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              String displayEmail = "Non connecté";
              IconData userIcon = Icons.person_outline;

              if (user != null) {
                if (user.uid.isNotEmpty && (user.email == null || user.email!.isEmpty) && (user.displayName == null || user.displayName!.isEmpty)) {
                  // Heuristic for anonymous user from Firebase (actual User object might have isAnonymous flag)
                  // For our UserModel, if email/displayName are missing after login, could be anonymous.
                  // The authService.user stream provides a UserModel(uid: firebaseUser.uid)
                  // This logic might need refinement based on how UserModel is populated by AuthService for anon users.
                  displayEmail = "Connecté en tant qu'anonyme";
                  userIcon = Icons.no_accounts; // Or a specific icon for anonymous
                } else {
                  displayEmail = user.email ?? user.displayName ?? user.uid; // Display email, name, or UID
                  userIcon = Icons.person;
                }
              }

              return ListTile(
                leading: Icon(userIcon),
                title: Text(displayEmail),
                subtitle: user != null ? const Text("Statut du compte") : null,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            title: const Text('Déconnexion'),
            onTap: () => _signOut(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Musique'),
            subtitle: const Text('Bientôt disponible'),
            enabled: false,
            onTap: () {
              // Placeholder for music settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Effets sonores'),
            subtitle: const Text('Bientôt disponible'),
            enabled: false,
            onTap: () {
              // Placeholder for sound effects settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Thème de l\'application'),
            subtitle: const Text('Bientôt disponible'),
            enabled: false,
            onTap: () {
              // Placeholder for theme settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Support / Contacter'),
            onTap: () => _contactSupport(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Lock Game',
                applicationVersion: '1.0.0', // TODO: Get from pubspec or env
                applicationLegalese: '© 2024 Lock Game Team',
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Text('Un jeu de réflexion et de logique. Trouvez la solution !')
                  )
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
