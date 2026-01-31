import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';

abstract class CloudBackupService {
  Future<void> backup(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> restore();
  
  static CloudBackupService get instance {
    if (Platform.isAndroid) {
      return GoogleDriveService();
    } else if (Platform.isIOS || Platform.isMacOS) {
      return ICloudService();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
}

class GoogleDriveService implements CloudBackupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  final String _fileName = 'didit_backup.json';

  Future<drive.DriveApi?> _getDriveApi() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    return drive.DriveApi(authenticateClient);
  }

  @override
  Future<void> backup(Map<String, dynamic> data) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Google Sign In failed');

    final jsonString = jsonEncode(data);
    final List<int> bytes = utf8.encode(jsonString);
    final Stream<List<int>> mediaStream = Stream.value(bytes);
    final media = drive.Media(mediaStream, bytes.length);

    // Search for existing file
    final fileList = await driveApi.files.list(
      q: "name = '$_fileName' and trashed = false",
      spaces: 'drive',
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      // Update existing
      final fileId = fileList.files!.first.id!;
      await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      // Create new
      final driveFile = drive.File()..name = _fileName;
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  @override
  Future<Map<String, dynamic>?> restore() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Google Sign In failed');

    final fileList = await driveApi.files.list(
      q: "name = '$_fileName' and trashed = false",
      spaces: 'drive',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      return null;
    }

    final fileId = fileList.files!.first.id!;
    
    // Download file content as media
    final response = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    
    final List<int> dataBytes = [];
    await for (final chunk in response.stream) {
      dataBytes.addAll(chunk);
    }

    final jsonString = utf8.decode(dataBytes);
    return jsonDecode(jsonString);
  }
}

class ICloudService implements CloudBackupService {
  /// The iCloud container ID. Must be configured in the Apple Developer Account.
  final String _containerId = 'iCloud.com.pooha302.didit';
  final String _fileName = 'didit_backup.json';

  @override
  Future<void> backup(Map<String, dynamic> data) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$_fileName');
    await file.writeAsString(jsonEncode(data));

    await ICloudStorage.upload(
      containerId: _containerId,
      filePath: file.path,
      destinationRelativePath: _fileName,
      onProgress: (stream) {
        stream.listen((progress) => debugPrint('iCloud Upload Progress: $progress'));
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> restore() async {
    final tempDir = await getTemporaryDirectory();
    final destinationPath = '${tempDir.path}/$_fileName';

    try {
      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: _fileName,
        destinationFilePath: destinationPath,
        onProgress: (stream) {
          stream.listen((progress) => debugPrint('iCloud Download Progress: $progress'));
        },
      );

      final file = File(destinationPath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return jsonDecode(jsonString);
      }
    } catch (e) {
      debugPrint('iCloud Restore Error: $e');
    }
    return null;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
