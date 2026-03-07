import 'dart:io';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // --- CONFIGURATION ---
  // Environment variables injection (Use --dart-define=DRIVE_CLIENT_ID=xxx)
  static const String _clientId = String.fromEnvironment('DRIVE_CLIENT_ID');
  static const String _clientSecret = String.fromEnvironment('DRIVE_CLIENT_SECRET');

  // Scope: driveFile (Sirf wahi files jo is app ne banayi hain)
  static final _scopes = [drive.DriveApi.driveFileScope];

  AutoRefreshingAuthClient? _authClient;

  /// Check if keys are actually provided
  bool _ensureKeysProvided() {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      print('\n[GOOGLE DRIVE] ERROR: OAuth keys missing!');
      print('Please run the app with:');
      print('flutter run --dart-define=DRIVE_CLIENT_ID=xxx --dart-define=DRIVE_CLIENT_SECRET=yyy\n');
      return false;
    }
    return true;
  }

  /// Private helper to get or refresh the client
  Future<AutoRefreshingAuthClient?> _getAuthClient() async {
    if (_authClient != null) return _authClient;
    if (!_ensureKeysProvided()) return null;

    final prefs = await SharedPreferences.getInstance();
    final savedCredentials = prefs.getString('drive_credentials');

    if (savedCredentials != null && savedCredentials.isNotEmpty) {
      try {
        final clientId = ClientId(_clientId, _clientSecret);
        final credentials = AccessCredentials.fromJson(
          jsonDecode(savedCredentials),
        );

        // Auto-refreshing client create karein
        final baseClient = http.Client();
        _authClient = autoRefreshingClient(clientId, credentials, baseClient);

        // Agar token refresh ho toh storage update karein
        _authClient!.credentialUpdates.listen((newCredentials) {
          prefs.setString(
            'drive_credentials',
            jsonEncode(newCredentials.toJson()),
          );
          print("Tokens refreshed and saved.");
        });

        print("Successfully loaded cached credentials.");
        return _authClient;
      } catch (e) {
        print('Error loading saved credentials, clearing them: $e');
        await prefs.remove('drive_credentials');
      }
    }
    return null;
  }

  /// Manually trigger Sign-In via Browser
  Future<bool> signIn() async {
    if (!_ensureKeysProvided()) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientId = ClientId(_clientId, _clientSecret);

      // clientViaUserConsent automatically opens a local server to listen for the redirect
      final client = await clientViaUserConsent(clientId, _scopes, (url) async {
        print('Opening browser for Auth: $url');
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print('Could not launch $url. Please open manually.');
        }
      });

      // Save credentials for future use
      prefs.setString(
        'drive_credentials',
        jsonEncode(client.credentials.toJson()),
      );
      _authClient = client;

      print('Sign-in successful!');
      return true;
    } catch (e) {
      print('Sign-in error: $e');
      return false;
    }
  }

  /// Logout/Clear Credentials
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('drive_credentials');
    _authClient?.close();
    _authClient = null;
    print('Signed out.');
  }

  /// Main Function: Upload or Update Backup
  Future<bool> uploadBackup(File file) async {
    try {
      final client = await _getAuthClient();
      if (client == null) {
        print('No valid session. User must sign in first.');
        return false;
      }

      final driveApi = drive.DriveApi(client);
      final fileName = p.basename(file.path);

      // 1. Check or Create "POS_Backups" Folder
      String? folderId;
      final folderQuery =
          "name = 'POS_Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final folderSearchResult = await driveApi.files.list(q: folderQuery);

      if (folderSearchResult.files != null &&
          folderSearchResult.files!.isNotEmpty) {
        folderId = folderSearchResult.files!.first.id;
      } else {
        print('Creating new folder: POS_Backups');
        final newFolder = drive.File()
          ..name = 'POS_Backups'
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(newFolder);
        folderId = createdFolder.id;
      }

      // 2. Check if file already exists inside that folder
      final fileQuery =
          "name = '$fileName' and '$folderId' in parents and trashed = false";
      final existingFiles = await driveApi.files.list(q: fileQuery);

      final media = drive.Media(file.openRead(), file.lengthSync());

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // UPDATE existing file
        final fileId = existingFiles.files!.first.id!;
        await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
        print('Backup updated successfully.');
      } else {
        // CREATE new file
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [folderId!];
        await driveApi.files.create(driveFile, uploadMedia: media);
        print('New backup created successfully.');
      }

      return true;
    } catch (e) {
      print('Backup Upload Failed: $e');
      return false;
    }
  }
}
