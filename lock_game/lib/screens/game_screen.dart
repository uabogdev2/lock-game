import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // For hint generation

import '../models/level_model.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';

class GameScreen extends StatefulWidget {
  final Level initialLevel;

  const GameScreen({super.key, required this.initialLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Level currentLevel;
  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  String _currentSolutionInput = ""; // To store the concatenated input for submission
  bool _showIncorrectMessage = false;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.initialLevel;
    _initializeInputFields();
  }

  void _initializeInputFields() {
    // Clean up old controllers and focus nodes if any
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    _controllers = List.generate(
      currentLevel.solution.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      currentLevel.solution.length,
      (index) => FocusNode(),
    );

    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        // This listener is primarily for debug or complex logic,
        // onChanged in TextField is more direct for focus change.
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onInputChanged(String value, int index) {
    setState(() {
      _showIncorrectMessage = false; // Hide error message on new input
    });
    if (value.isNotEmpty) {
      _currentSolutionInput = _buildCurrentSolution();
      if (index < _controllers.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        // Last field, unfocus or try to submit? For now, just unfocus.
        _focusNodes[index].unfocus();
      }
    } else { // Handle backspace
        _currentSolutionInput = _buildCurrentSolution();
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }
  }

  String _buildCurrentSolution() {
    return _controllers.map((controller) => controller.text.toUpperCase()).join();
  }

  Future<void> _submit() async {
    final gameProvider = context.read<GameProvider>();
    final constructedAnswer = _buildCurrentSolution();

    if (constructedAnswer.length != currentLevel.solution.length) {
        setState(() {
            _showIncorrectMessage = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez remplir tous les champs de la solution.')),
        );
        return;
    }

    bool isCorrect = await gameProvider.submitAnswer(constructedAnswer);

    if (mounted) { // Check if widget is still in the tree
      if (isCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bravo ! Niveau suivant débloqué !'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop and let LevelSelectorScreen handle showing the next available level or updating UI
        Navigator.pop(context);
      } else {
        setState(() {
          _showIncorrectMessage = true;
        });
         // Clear fields on incorrect answer for better UX
        for (var controller in _controllers) {
          controller.clear();
        }
        if (_focusNodes.isNotEmpty) {
            FocusScope.of(context).requestFocus(_focusNodes[0]);
        }
      }
    }
  }

  Future<void> _requestHint() async {
    final gameProvider = context.read<GameProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentUser == null) return; // Should not happen if on this screen

    if (authProvider.currentUser!.points < GameProvider.HINT_COST) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pas assez de points pour un indice (${GameProvider.HINT_COST} points requis).')),
      );
      return;
    }

    // Simple hint: reveal a random character or first few
    // GameProvider's requestHint method already handles point deduction
    String? hint = await gameProvider.requestHint();

    if (mounted && hint != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Indice'),
          content: Text(hint),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (mounted && hint == null) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun indice disponible ou erreur lors de la demande.')),
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    // If the level somehow changes externally (e.g. provider state is reset), re-init fields
    // This is less likely if GameScreen is popped on level completion.
    if (widget.initialLevel.level != currentLevel.level) {
        currentLevel = widget.initialLevel;
        _initializeInputFields();
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Niveau ${currentLevel.level} - ${currentLevel.category}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Instructions
            ...currentLevel.instructions.map((instr) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    instr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                )),
            const SizedBox(height: 30),

            // Input Fields for Solution
            Wrap( // Use Wrap for better spacing if many characters
              alignment: WrapAlignment.center,
              spacing: 8.0, // Horizontal spacing
              runSpacing: 8.0, // Vertical spacing for multiple lines if solution is very long
              children: List.generate(currentLevel.solution.length, (index) {
                return SizedBox(
                  width: 45, // Increased width for better touch target and visibility
                  height: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "", // Hide the counter
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) => _onInputChanged(value, index),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Incorrect Message
            if (_showIncorrectMessage)
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Text(
                  context.watch<GameProvider>().errorMessage ?? 'Réponse incorrecte. Essayez encore !',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 20),
            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Valider'),
            ),
            const SizedBox(height: 20),

            // Hint Button
            TextButton(
              onPressed: _requestHint,
              child: Text('Indice (-${GameProvider.HINT_COST} points)'),
            ),
          ],
        ),
      ),
    );
  }
}
