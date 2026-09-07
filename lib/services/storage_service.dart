import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

/// Sube archivos a Cloudinary (plan gratuito, sin tarjeta) usando un
/// "unsigned upload preset" y devuelve la URL pública (`secure_url`).
/// Se usa `XFile.readAsBytes()` en vez de `dart:io File`, porque
/// `dart:io` no existe en Flutter Web: así el mismo código funciona en
/// Android, iOS y Web sin distinguir plataforma.
class StorageService {
  static const String _cloudName = 'wzij8orl';
  static const String _uploadPreset = 'aq47wl1x';

  Uri get _endpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

  Future<String> _upload(XFile file, String folder) async {
    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 25),
      onTimeout: () {
        throw Exception('La subida tardó demasiado. Revisa tu conexión e inténtalo de nuevo.');
      },
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('No se pudo subir el archivo (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  Future<String> uploadProfilePhoto(XFile file, String uid) {
    return _upload(file, 'profile_photos/$uid');
  }

  Future<String> uploadPetPhoto(XFile file, String shelterId) {
    return _upload(file, 'pet_photos/$shelterId');
  }

  /// El carnet de vacunación puede subirse como foto (JPG/PNG) o como
  /// documento (PDF) escaneado; el endpoint `/auto/upload` de Cloudinary
  /// acepta ambos tipos sin configuración extra.
  Future<String> uploadVaccineDocument(XFile file, String petOwnerId) {
    return _upload(file, 'vaccine_cards/$petOwnerId');
  }
}
