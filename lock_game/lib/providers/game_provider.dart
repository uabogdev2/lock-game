import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../services/level_service.dart';
import './auth_provider.dart'; // To update points

class GameProvider extends ChangeNotifier {
  final LevelService _levelService;
  final AuthProvider _authProvider; // To update user points

  List<Level> _allLevels = [];
  List<Level> get allLevels => _allLevels;

  Level? _currentLevel;
  Level? get currentLevel => _currentLevel;

  int _currentLevelIndex = -1;
  int get currentLevelIndex => _currentLevelIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // To track game state e.g. answer correct, hint used etc.
  bool _isAnswerCorrect = false;
  bool get isAnswerCorrect => _isAnswerCorrect;

  GameProvider({required LevelService levelService, required AuthProvider authProvider})
      : _levelService = levelService, _authProvider = authProvider {
    loadAllLevels();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> loadAllLevels() async {
    _setLoading(true);
    _clearError();
    try {
      _allLevels = await _levelService.loadLevels();
      if (_allLevels.isNotEmpty) {
        // Select the first level by default, or the first unlocked level for the user
        // This part might need user data, for now, just select level 0 if available
        // Or, ensure currentLevelIndex is handled by checking against unlocked levels from AuthProvider
        _selectLevelByIndex(0); // Default to first level
      } else {
        _setError("No levels loaded. Check levels.json or LevelService.");
      }
    } catch (e) {
      print('Error loading all levels: $e');
      _setError('Failed to load levels: $e');
      _allLevels = []; // Ensure it's empty on error
    } finally {
      _setLoading(false);
      // notifyListeners() already called by _setLoading
    }
  }

  void selectLevelById(int levelId) {
    _clearError();
    final index = _allLevels.indexWhere((level) => level.level == levelId);
    if (index != -1) {
      // Check if level is unlocked by user (via AuthProvider)
      if (_authProvider.currentUser != null &&
          _authProvider.currentUser!.unlockedLevels.contains(levelId)) {
        _selectLevelByIndex(index);
      } else {
        _setError("Level $levelId is locked.");
         print("Attempted to select locked level: $levelId. User unlocked: ${_authProvider.currentUser?.unlockedLevels}");
        // Optionally, set currentLevel to null or keep previous
        // _currentLevel = null;
        // _currentLevelIndex = -1;
        notifyListeners(); // Notify UI about the error or state change
      }
    } else {
      _setError("Level with ID $levelId not found.");
      print("Level with ID $levelId not found.");
    }
  }

  void _selectLevelByIndex(int index) {
    if (index >= 0 && index < _allLevels.length) {
      _currentLevelIndex = index;
      _currentLevel = _allLevels[index];
      _isAnswerCorrect = false; // Reset answer state for new level
      print('Level selected: ${_currentLevel?.level} - ${_currentLevel?.category}');
    } else {
      _currentLevelIndex = -1;
      _currentLevel = null;
      print('Invalid level index: $index');
      _setError("Invalid level index selected.");
    }
    notifyListeners();
  }

  // Select next available unlocked level
  void selectNextLevel() {
    _clearError();
    if (_currentLevel == null || _authProvider.currentUser == null) {
      if (_allLevels.isNotEmpty) _selectLevelByIndex(0); // Default to first if no current level
      return;
    }

    // Find the next level ID that is unlocked
    int nextLevelId = _currentLevel!.level + 1;
    while (true) {
        final nextLevelInAll = _allLevels.firstWhere((l) => l.level == nextLevelId, orElse: () => Level(level: -1, category: '', instructions: [], solution: '')); // Dummy level for not found
        if (nextLevelInAll.level == -1) { // No more levels in the game
            _setError("You've completed all available levels!");
            // Optionally, navigate to a "game completed" screen or state
            break;
        }
        if (_authProvider.currentUser!.unlockedLevels.contains(nextLevelId)) {
            selectLevelById(nextLevelId);
            break;
        }
        nextLevelId++; // Check the next one
    }
    notifyListeners();
  }


  Future<bool> submitAnswer(String answer) async {
    _clearError();
    if (_currentLevel == null) {
      _setError("No current level selected to submit an answer.");
      return false;
    }

    // Normalize answers for comparison (e.g., uppercase, trim whitespace)
    final normalizedSolution = _currentLevel!.solution.toUpperCase().trim();
    final normalizedAnswer = answer.toUpperCase().trim();

    if (normalizedSolution == normalizedAnswer) {
      _isAnswerCorrect = true;
      print('Answer correct for level ${_currentLevel!.level}');

      // Grant points (e.g., 10 points per level)
      await _authProvider.addPoints(10);

      // Unlock next level if not already the last level
      int currentLevelId = _currentLevel!.level;
      int nextLevelId = currentLevelId + 1;

      // Check if there is a next level in the allLevels list
      final isThereNextLevel = _allLevels.any((level) => level.level == nextLevelId);
      if (isThereNextLevel) {
          await _authProvider.unlockNewLevel(nextLevelId);
          print('Unlocked next level: $nextLevelId');
      } else {
          print('This was the last level!');
          // Handle game completion if necessary
      }

      notifyListeners();
      return true;
    } else {
      _isAnswerCorrect = false;
      print('Answer incorrect for level ${_currentLevel!.level}');
      // Optionally, deduct points for wrong answer (if game design requires)
      // await _authProvider.spendPoints(1); // Example: deduct 1 point
      _setError("Incorrect answer. Try again!");
      notifyListeners();
      return false;
    }
  }

  // Example cost for a hint
  static const int HINT_COST = 2;

  Future<String?> requestHint() async {
    _clearError();
    if (_currentLevel == null) {
      _setError("No current level selected to request a hint.");
      return null;
    }
    if (_authProvider.currentUser == null || _authProvider.currentUser!.points < HINT_COST) {
      _setError("Not enough points to request a hint (cost: $HINT_COST).");
      return null;
    }

    // Simple hint logic: reveal first letter of the solution
    // More complex hint logic can be added here (e.g., part of instructions, a character, etc.)
    if (_currentLevel!.solution.isNotEmpty) {
      await _authProvider.spendPoints(HINT_COST);
      final hint = "The solution starts with: '${_currentLevel!.solution[0]}'.";
      print('Hint provided for level ${_currentLevel!.level}: $hint');
      notifyListeners(); // For point change
      return hint;
    } else {
      _setError("No hint available for this level.");
      return null;
    }
  }
}
