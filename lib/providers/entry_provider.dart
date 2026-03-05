import 'package:flutter/material.dart';
import '../models/entry_model.dart';
import '../database/db_helper.dart';

class EntryProvider with ChangeNotifier {
  List<EntryModel> _entries = [];
  bool _isLoading = false;

  List<EntryModel> get entries => _entries;
  bool get isLoading => _isLoading;

  EntryProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    _entries = await DBHelper().getAllEntries();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(EntryModel entry) async {
    await DBHelper().insertEntry(entry);
    await loadEntries();
  }

  Future<void> updateEntry(EntryModel entry) async {
    await DBHelper().updateEntry(entry);
    await loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    await DBHelper().deleteEntry(id);
    await loadEntries();
  }

  Future<void> searchEntries(String query) async {
    if (query.isEmpty) {
      await loadEntries();
    } else {
      _isLoading = true;
      notifyListeners();
      _entries = await DBHelper().searchEntries(query);
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyDateFilter(DateTime start, DateTime end) {
    _entries = _entries
        .where(
          (e) =>
              e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
    notifyListeners();
  }

  // Dashboard calculations
  int get totalEntries => _entries.length;

  double get totalDieselExpense =>
      _entries.fold(0, (sum, item) => sum + item.dieselExpense);

  double get totalOtherExpenses =>
      _entries.fold(0, (sum, item) => sum + item.otherExpense);

  double get totalOverallExpense =>
      _entries.fold(0, (sum, item) => sum + item.totalExpense);

  double get totalEarnings =>
      _entries.fold(0, (sum, item) => sum + item.earnings);

  double get totalProfit => _entries.fold(0, (sum, item) => sum + item.profit);
}
