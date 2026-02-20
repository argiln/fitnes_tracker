import 'package:flutter/material.dart';

class AppState {
  // --- Text Controllers ---
  static final nameController = TextEditingController();
  static final qtyController = TextEditingController();
  
  static final calGoalController = TextEditingController();
  static final proGoalController = TextEditingController();
  static final carbGoalController = TextEditingController();
  static final fatGoalController = TextEditingController();

  // --- Date Logic ---
  static DateTime selectedDate = DateTime.now();
  
  // Dynamic key for SharedPreferences
  static String get dateKey => 
      "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

  // Helper to clear the 'Add Food' boxes
  static void clearFoodInputs() {
    nameController.clear();
    qtyController.clear();
  }
}