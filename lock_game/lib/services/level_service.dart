import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/level_model.dart';

class LevelService {
  Future<List<Level>> loadLevels() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/levels.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      if (jsonList.isEmpty) {
        print('No levels found in levels.json or the file is empty.');
        return [];
      }

      return jsonList.map((jsonItem) {
        try {
          return Level.fromJson(jsonItem as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing a level item: $jsonItem. Error: $e');
          // Skip this level or handle more gracefully
          return null;
        }
      }).where((level) => level != null).cast<Level>().toList(); // Filter out nulls from parsing errors

    } catch (e) {
      print('Error loading or parsing levels.json: $e');
      // Depending on the app's needs, you might want to return an empty list,
      // throw the error, or return a default set of levels.
      return [];
    }
  }
}
