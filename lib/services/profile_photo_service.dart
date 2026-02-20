import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Service sederhana untuk handle foto profil
/// Support Web & Mobile menggunakan XFile
class ProfilePhotoService {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();
  
  // Gunakan bucket 'avatars' (bucket standar Supabase untuk foto profil)
  static const String bucketName = 'avatars';

  /// Pilih gambar dari galeri
  Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Gagal memilih gambar: $e');
    }
  }

  /// Ambil foto dari kamera
  Future<XFile?> pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Gagal mengambil foto: $e');
    }
  }

  /// Upload foto profil (langsung upload + update database)
  /// Support Web & Mobile dengan menggunakan bytes dari XFile
  Future<String> uploadPhoto(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Baca bytes dari XFile (works di web & mobile)
      final bytes = await imageFile.readAsBytes();

      // Upload ke Supabase Storage menggunakan bytes
      await _supabase.storage.from(bucketName).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final photoUrl = _supabase.storage.from(bucketName).getPublicUrl(fileName);

      // Update profile di database
      await _supabase.from('profiles').update({
        'photo_url': photoUrl,
      }).eq('id', userId);

      return photoUrl;
    } catch (e) {
      throw Exception('Gagal upload foto: $e');
    }
  }

  /// Hapus foto profil (langsung hapus + update database)
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Extract filename dari URL
      final uri = Uri.parse(photoUrl);
      final fileName = uri.pathSegments.last;

      // Hapus dari storage
      await _supabase.storage.from(bucketName).remove([fileName]);

      // Update profile (set null)
      await _supabase.from('profiles').update({
        'photo_url': null,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Gagal hapus foto: $e');
    }
  }
}
