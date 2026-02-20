import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/document.dart';
import 'dart:typed_data';

/// Service untuk mengelola Dokumen
/// Mendukung CRUD, upload file, dan filtering
class DocumentService {
  final _supabase = Supabase.instance.client;
  static const String tableName = 'documents';
  static const String bucketName = 'documents'; // Bucket untuk file dokumen

  /// CREATE - Tambah dokumen baru
  Future<Document> createDocument({
    required String title,
    String? overview,
    DateTime? documentDate,
    DocumentCategory? category,
    List<String>? tags,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();
      
      String? fileUrl;
      String? uploadedFileName;
      int? fileSize;

      // Upload file jika ada
      if (fileBytes != null && fileName != null) {
        final uploadResult = await _uploadFile(fileBytes, fileName);
        fileUrl = uploadResult['url'];
        uploadedFileName = uploadResult['name'];
        fileSize = uploadResult['size'];
      }

      final response = await _supabase.from(tableName).insert({
        'user_id': userId,
        'title': title,
        'overview': overview,
        'document_date': documentDate?.toIso8601String().split('T')[0],
        'file_url': fileUrl,
        'file_name': uploadedFileName,
        'file_size': fileSize,
        'category': category?.value,
        'tags': tags,
        'created_at': now.toIso8601String(),
      }).select().single();

      return Document.fromJson(response);
    } catch (e) {
      throw Exception('Gagal membuat dokumen: $e');
    }
  }

  /// READ - Ambil semua dokumen dengan filter
  Future<List<Document>> getDocuments({
    DocumentCategory? filterByCategory,
    String? searchQuery,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      dynamic query = _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);

      // Filter by category
      if (filterByCategory != null) {
        query = query.eq('category', filterByCategory.value);
      }

      // Search by title
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      // Sorting: yang terbaru dulu
      query = query.order('created_at', ascending: false);

      final List<dynamic> response = await query;

      return response.map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil dokumen: $e');
    }
  }

  /// READ - Ambil satu dokumen berdasarkan ID
  Future<Document?> getDocumentById(String documentId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('id', documentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return Document.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil dokumen: $e');
    }
  }

  /// UPDATE - Edit dokumen
  Future<Document> updateDocument({
    required String documentId,
    required String title,
    String? overview,
    DateTime? documentDate,
    DocumentCategory? category,
    List<String>? tags,
    Uint8List? newFileBytes,
    String? newFileName,
    bool removeFile = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Data yang akan diupdate
      Map<String, dynamic> updateData = {
        'title': title,
        'overview': overview,
        'document_date': documentDate?.toIso8601String().split('T')[0],
        'category': category?.value,
        'tags': tags,
      };

      // Jika ada file baru untuk diupload
      if (newFileBytes != null && newFileName != null) {
        // Hapus file lama jika ada
        final oldDoc = await getDocumentById(documentId);
        if (oldDoc?.fileUrl != null) {
          await _deleteFile(oldDoc!.fileUrl!);
        }

        // Upload file baru
        final uploadResult = await _uploadFile(newFileBytes, newFileName);
        updateData['file_url'] = uploadResult['url'];
        updateData['file_name'] = uploadResult['name'];
        updateData['file_size'] = uploadResult['size'];
      } else if (removeFile) {
        // Hapus file jika diminta
        final oldDoc = await getDocumentById(documentId);
        if (oldDoc?.fileUrl != null) {
          await _deleteFile(oldDoc!.fileUrl!);
        }
        updateData['file_url'] = null;
        updateData['file_name'] = null;
        updateData['file_size'] = null;
      }

      final response = await _supabase
          .from(tableName)
          .update(updateData)
          .eq('id', documentId)
          .eq('user_id', userId)
          .select()
          .single();

      return Document.fromJson(response);
    } catch (e) {
      throw Exception('Gagal update dokumen: $e');
    }
  }

  /// DELETE - Hapus dokumen
  Future<void> deleteDocument(String documentId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Hapus file dari storage jika ada
      final document = await getDocumentById(documentId);
      if (document?.fileUrl != null) {
        await _deleteFile(document!.fileUrl!);
      }

      // Hapus data dari database
      await _supabase
          .from(tableName)
          .delete()
          .eq('id', documentId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Gagal hapus dokumen: $e');
    }
  }

  /// UTILITY - Upload file ke Supabase Storage
  Future<Map<String, dynamic>> _uploadFile(Uint8List fileBytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last;
      final storagePath = '$userId/$timestamp.$fileExtension';

      // Upload file binary
      await _supabase.storage.from(bucketName).uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileExtension),
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(storagePath);

      // Get file size
      final fileSize = fileBytes.length;

      return {
        'url': publicUrl,
        'name': fileName,
        'size': fileSize,
      };
    } on StorageException catch (e) {
      if (e.message.contains('Bucket not found')) {
        throw Exception('Storage bucket "$bucketName" belum dibuat. Silakan buat bucket di Supabase Dashboard → Storage → Create Bucket dengan nama "$bucketName"');
      }
      throw Exception('Gagal upload file: ${e.message}');
    } catch (e) {
      throw Exception('Gagal upload file: $e');
    }
  }

  /// UTILITY - Get content type based on file extension
  String _getContentType(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      default:
        return 'application/octet-stream';
    }
  }

  /// UTILITY - Hapus file dari Supabase Storage
  Future<void> _deleteFile(String fileUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      // Path format: /storage/v1/object/public/documents/{userId}/{fileName}
      if (pathSegments.length >= 2) {
        final storagePath = pathSegments.sublist(pathSegments.length - 2).join('/');
        await _supabase.storage.from(bucketName).remove([storagePath]);
      }
    } catch (e) {
      // Ignore errors saat hapus file (file mungkin sudah tidak ada)
      print('Gagal hapus file: $e');
    }
  }

  /// UTILITY - Hitung total dokumen
  Future<int> getDocumentsCount() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(tableName)
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// UTILITY - Hitung dokumen per kategori
  Future<Map<DocumentCategory, int>> getCountByCategory() async {
    try {
      final docs = await getDocuments();
      final Map<DocumentCategory, int> counts = {};

      for (var category in DocumentCategory.values) {
        counts[category] = docs.where((doc) => doc.category == category).length;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  /// UTILITY - Get public URL untuk file
  String getFileUrl(String storagePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
  }

  /// UTILITY - Download file (return URL untuk dibuka)
  String? getDownloadUrl(Document document) {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      return null;
    }
    return document.fileUrl;
  }

  /// UTILITY - Create download link dengan filename
  String? createDownloadLink(Document document) {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      return null;
    }
    // URL dengan response-content-disposition untuk force download
    final uri = Uri.parse(document.fileUrl!);
    final downloadUri = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'download': document.fileName ?? 'document',
      },
    );
    return downloadUri.toString();
  }
}
