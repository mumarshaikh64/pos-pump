import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // IMPORTANT: For one central account, we use a Service Account.
  // The user should paste their service_account.json content here or load it from assets.
  static const Map<String, dynamic> _credentials = {
    "type": "service_account",
    "project_id": "pos-system-489509",
    "private_key_id": "f6a94a17a0814c4e4dad4ba1969865d74664f992",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQDmdIa4CPsExehd\nyDjvyYBsKP48Mv8Xq+lzTZsyXreKlOmXs/ixBO+EL5Ufo3ZhUr4A4D1XVhSbskp+\nJ8ku7y/10aOCSQ2+TpiXntIxgnHIl9tCKAiTgHQRDujYgB28Tw2o0qxpWEl5e3iV\nD/OZt1QYkZ9GdXk+IEFjEjpUNw0HEZBO/CzmvHOhRRRE0F0820UBCp7uH3xKipTZ\n0O/607HkRphcXjTpxOBaW+CZC5b+8BpMeuYkF7UCw/rCROwqjt4yx+SaRKMLD1hq\nGFkjrmIPuw7UhwbSrL1JBZRkvql2FdWHn10zocUpcuwiR91ytumU5dPZgwG1cMaE\ntv7KL/J9AgMBAAECgf4EyXMffw1TnUBaLU0k4VQ+ufOZ1JzpnqoIGMBAW5a8tO/G\nwFC2hMXzBHfZ3wWxQ5brJ3yQBNWku74fBS+1D3vUZbx1pmsbf27xsW4/3NT2sc1p\n1L/yMvJwTXt4QIVqdQnStW276M3JVWhxblsbmTWgxvJGewzHc3yUR6Bm46I1YuIw\n188wkN6IqNIo2Fqy1T4xff5wns+Cxqyaj9Gq1VS7NMaNt8hxinRBO7oMseY6nVef\nXbfsultsBiYbtBGDwAbUG4KwnnWKscnWlbfUDbStciVLCRKTCTbPf6Uaup1Qdqb9\n2f2mYZjcLiWMadYAidSaZ2r/cbTfZlFWGEztXwKBgQD/7KCjQ/C6Y1NoMb15lj/2\nK/jLVzlRJWVwUhxHU+iGTbBU6bbDPirF+yLhZF9igP+ChLWyevXxClLpiFEDajLR\nGsMkmjTPcg2+ySXFk3XiUyQJ6eGg2zFi8yB6mgjsswQqAB260dlCvQU8IqA1dBn9\nGaVtBAm8eofF1q+NedzjLwKBgQDmhfiIs9iMw34P2AMT1j2yMhWf6+yDQG68UWMe\nl10JzJTDh3GkxQpM+0UIJri4+TNXygF7q7KMx4o6zbGhm5v7EjIjZoh31qd/3pOl\nb9m0e1Uc8G2VFEtl5AmrUvw2Jbte2gR9hHutCxRZIynjjy5XGJDZeg+kRgCdU/6s\nAvjKEwKBgFGbgPXO2lp1Bcm54rN8x9SV3PXqUGqhxCD27fGIviLlbw8En7TOhBEx\nrcO1n/znKZLTAqVxNC+ynRG+2CaAnMe1AvkO+zwTIHLv7U19Yh/TZzCKFdqXSr5E\nzNyLdcEUrIVAGDrUY7U2VQ8B85hX91mP7gI/QWOKpvTdKomwjFEdAoGBAJ5sLYxN\nBKJga08aJatJTecbsm7QJR9idXen+xV38nGcjhP+DiStYVHcUOm0Kri8UgOgCPrj\n2XYUX7PfzpaAqWaXb6uSeHDbLQucfB1yy8vUAn874CNW6iYg3GBITJotviIGdJWK\nKbCXb6l+l/gSW0dx04IR95Puo9d7dQbjl/TPAoGBAM0sR9yD7WP2w+PCB+jndAGE\nC+3HQJ5Es8PdbnWIMTf1HPvIv71hLo2YOOj9MC5lEk8uJCBlljCjrb24fixxh/NH\nQJPYHPdS1GvwWjZiyjF8atdx4ausilDZxQptZzzpuJt2pzig+bHeJEu44T/yx0QL\nxOWF9s1232iDgwV/VbMb\n-----END PRIVATE KEY-----\n",
    "client_email": "pos-system@pos-system-489509.iam.gserviceaccount.com",
    "client_id": "112769718686491131664",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/pos-system%40pos-system-489509.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  static final _scopes = [drive.DriveApi.driveFileScope];

  Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
    return await clientViaServiceAccount(accountCredentials, _scopes);
  }

  Future<bool> uploadBackup(File file) async {
    try {
      final client = await _getAuthClient();
      final driveApi = drive.DriveApi(client);

      try {
        final fileName = p.basename(file.path);
        
        // 1. Find the shared folder 'POS_Backups'
        String? folderId;
        // Search more broadly
        final folderQuery = "name = 'POS_Backups' and trashed = false";
        final folderSearchResult = await driveApi.files.list(q: folderQuery);
        
        print('Debug: Found ${folderSearchResult.files?.length ?? 0} items matching "POS_Backups"');
        if (folderSearchResult.files != null) {
          for (var f in folderSearchResult.files!) {
            print('Debug: Found item: ${f.name} (ID: ${f.id}, Mime: ${f.mimeType})');
          }
        }
        
        if (folderSearchResult.files != null && folderSearchResult.files!.isNotEmpty) {
          // Find the one that is a folder
          final folder = folderSearchResult.files!.firstWhere(
            (f) => f.mimeType == 'application/vnd.google-apps.folder',
            orElse: () => folderSearchResult.files!.first,
          );
          folderId = folder.id;
        } else {
          print('CRITICAL: Folder "POS_Backups" not found!');
          print('Please ensure:');
          print('1. Folder name is exactly "POS_Backups"');
          print('2. It is shared with: ${_credentials['client_email']}');
          return false;
        }

        // 2. Search for existing file with the same name INSIDE that folder
        final query = "name = '$fileName' and '$folderId' in parents and trashed = false";
        final fileList = await driveApi.files.list(q: query);

        final media = drive.Media(
          file.openRead(),
          file.lengthSync(),
          contentType: 'application/octet-stream',
        );

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          // Update existing file
          final existingFileId = fileList.files!.first.id!;
          await driveApi.files.update(
            drive.File(name: fileName),
            existingFileId,
            uploadMedia: media,
          );
          print('Backup updated in "POS_Backups" folder');
        } else {
          // Create new file inside the folder
          final driveFile = drive.File();
          driveFile.name = fileName;
          driveFile.parents = [folderId!];
          
          await driveApi.files.create(
            driveFile,
            uploadMedia: media,
          );
          print('New backup created in "POS_Backups" folder');
        }

        return true;
      } finally {
        client.close();
      }
    } catch (e) {
      print('Error uploading backup: $e');
      return false;
    }
  }

  // No longer needs manual signIn/signOut for the user
  Future<bool> signIn() async => true;
  Future<void> signOut() async {}
}
