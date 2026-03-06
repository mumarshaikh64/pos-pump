import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'google_drive_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final GoogleDriveService _googleDriveService = GoogleDriveService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isBackingUp = false;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        print('Internet connected. Checking for backup...');
        autoBackup();
      }
    });
  }

  Future<void> autoBackup() async {
    if (_isBackingUp) return;
    _isBackingUp = true;

    try {
      String dbPath = join(await getDatabasesPath(), 'pos_pump.db');
      File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        bool success = await _googleDriveService.uploadBackup(dbFile);
        if (success) {
          print('Auto backup successful');
        } else {
          print('Auto backup failed');
        }
      } else {
        print('Database file not found at $dbPath');
      }
    } catch (e) {
      print('Error during auto backup: $e');
    } finally {
      _isBackingUp = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
