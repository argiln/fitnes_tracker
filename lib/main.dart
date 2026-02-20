import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'nutrition_service_api.dart';

void main() {
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const CalorieTrackerHome(),
    );
  }
}

class CalorieTrackerHome extends StatefulWidget {
  const CalorieTrackerHome({super.key});

  @override
  State<CalorieTrackerHome> createState() => _CalorieTrackerHomeState();
}

class _CalorieTrackerHomeState extends State<CalorieTrackerHome> {

  int calorieGoal = 2100;
  int proteinGoal = 150; 
  int carbsGoal = 300;   
  int fatGoal = 70;
  List<Map<String, dynamic>> foodLog = [];
  
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;


  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData(); 
  }

  // --- DATABASE: LOAD (Updated for Dates) ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      calorieGoal = prefs.getInt('calorie_goal') ?? 2500;
      proteinGoal = prefs.getInt('protein_goal') ?? 150;
      carbsGoal = prefs.getInt('carbs_goal') ?? 300;
      fatGoal = prefs.getInt('fat_goal') ?? 70;

      // Load specific day
      final List<String>? savedList = prefs.getStringList('food_log_$dateKey');
      
      if (savedList != null) {
        foodLog = savedList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
      } else {
        foodLog = []; 
      }
      
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    totalCalories = 0;
    totalProtein = 0;
    totalCarbs = 0;
    totalFat = 0;
    for (var item in foodLog) {
      totalCalories += item['calories'] ?? 0;
      totalProtein += item['protein'] ?? 0;
      totalCarbs += item['carbs'] ?? 0;
      totalFat += item['fat'] ?? 0;
    }
  }

  // --- DATABASE: SAVE (Updated for Dates) ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listToSave = foodLog.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('food_log_$dateKey', listToSave);
  }

  Future<void> _deleteItem(int index) async {
    setState(() {
      foodLog.removeAt(index);
      _calculateTotals();
    });
    await _saveData();
  }

    Future<void> _fetchNutrition() async {
    // Use AppState here
    if (AppState.nameController.text.isEmpty || AppState.qtyController.text.isEmpty) return;
    
    Navigator.pop(context); 
    setState(() => _isLoading = true);

    String rawQty = AppState.qtyController.text.trim();
    String finalQty = double.tryParse(rawQty) != null ? "${rawQty}g" : rawQty;
    String query = "$finalQty ${AppState.nameController.text}";

    try {
      final item = await NutritionServiceApi.fetchNutrition(query);

            if (item != null) {
            setState(() {
              foodLog.insert(0, {
                'name': item['name'], 
                'qty': finalQty,
                'calories': (item['calories'] as num).toDouble(),
                'protein': (item['protein_g'] as num).toDouble(),
                'carbs': (item['carbohydrates_total_g'] as num).toDouble(),
                'fat': (item['fat_total_g'] as num).toDouble()
              });
              _calculateTotals();
            });
            await _saveData();
            AppState.clearFoodInputs();
          } else {
            _showError("Food not found");
          }
        } catch (e) {
          _showError("Connection Error");
        } finally {
          setState(() => _isLoading = false);
        }
      }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showGoalsMenu() {
    AppState.calGoalController.text = calorieGoal.toString();
    AppState.proGoalController.text = proteinGoal.toString();
    AppState.carbGoalController.text = carbsGoal.toString();
    AppState.fatGoalController.text = fatGoal.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Goals"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: AppState.calGoalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories')),
            TextField(controller: AppState.proGoalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein')),
            TextField(controller: AppState.carbGoalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs')),
            TextField(controller: AppState.fatGoalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                calorieGoal = int.tryParse(AppState.calGoalController.text) ?? 2100;
                proteinGoal = int.tryParse(AppState.proGoalController.text) ?? 150;
                carbsGoal = int.tryParse(AppState.carbGoalController.text) ?? 300;
                fatGoal = int.tryParse(AppState.fatGoalController.text) ?? 70;
              });
              await prefs.setInt('calorie_goal', calorieGoal);
              await prefs.setInt('protein_goal', proteinGoal);
              await prefs.setInt('carbs_goal', carbsGoal);
              await prefs.setInt('fat_goal', fatGoal);

              Navigator.pop(context); //para ma close ang pop-up menu
            },
            child: const Text("Save"), 
          )
        ],
      ),
    );
  }

  void _showAddFoodPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Qty (e.g. 100)')),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Food Name')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchNutrition, child: const Text("TRACK IT")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int remaining = calorieGoal - totalCalories.toInt();
    double progress = totalCalories / calorieGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.teal),
          onPressed: _showGoalsMenu,
        ),
        // --- NEW CLICKABLE DATE TITLE ---
        title: GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2023),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
              _loadData(); 
            }
          },
          child: Column(
            children: [
              Text(
                "${selectedDate.month}/${selectedDate.day}/${selectedDate.year}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
              ),
              const Text("Tap to change date", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        centerTitle: true,
        // --- ARROWS TO FLIP DATES ---
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.teal),
            onPressed: () {
              setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.teal),
            onPressed: selectedDate.day == DateTime.now().day && selectedDate.month == DateTime.now().month ? null : () {
              setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
              _loadData();
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton.extended(
          onPressed: _showAddFoodPanel,
          backgroundColor: Colors.teal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Food", style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          // Progress Summary Container
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100, height: 100,
                      child: CircularProgressIndicator(
                        value: progress, 
                        strokeWidth: 10, 
                        backgroundColor: Colors.grey.shade200,
                        color: remaining < 0 ? Colors.red : Colors.teal,
                      ),
                    ),
                    Column(
                      children: [
                        Text("$remaining", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text("kcal left", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildMacroRow("Protein", totalProtein, proteinGoal, Colors.blue),
                      const SizedBox(height: 12),
                      _buildMacroRow("Carbs", totalCarbs, carbsGoal, Colors.orange),
                      const SizedBox(height: 12),
                      _buildMacroRow("Fat", totalFat, fatGoal, Colors.red),
                    ],
                  ),
                )
              ],
            ),
          ), 
          // Meal Log List
          Expanded(
            child: foodLog.isEmpty 
            ? const Center(child: Text("No meals recorded for this day"))
            : ListView.builder(
                itemCount: foodLog.length,
                itemBuilder: (context, index) {
                  final food = foodLog[index];
                  return ListTile(
                    title: Text(food['name'].toString().toUpperCase()),
                    subtitle: Text(
                      "${food['calories']} kcal | P: ${food['protein']}g | C: ${food['carbs'] ?? 0}g | F: ${food['fat'] ?? 0}g",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(index),
                    ),
                  );
                },
              ),
          ),
          Text("Developed by: Argil", style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, double current, int goal, Color color) {
    double progress = goal > 0 ? current / goal : 0.0;
    if (progress > 1.0) progress = 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${current.toInt()}g / ${goal}g"),
          ],
        ),
        LinearProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.1)),
      ],
    );
  }
}