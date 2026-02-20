import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synergy/models/document.dart';
import 'package:synergy/services/document_service.dart';
import 'package:synergy/constants/app_colors.dart';

class AddEditDocumentPage extends StatefulWidget {
  final Document? document;

  const AddEditDocumentPage({
    super.key,
    this.document,
  });

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentService = DocumentService();
  final _titleController = TextEditingController();
  final _overviewController = TextEditingController();
  final _tagsController = TextEditingController();
  
  DocumentCategory _selectedCategory = DocumentCategory.other;
  DateTime? _documentDate;
  PlatformFile? _selectedFile;
  String? _existingFileName;
  String? _existingFileUrl;
  bool _removeExistingFile = false;
  bool _isSaving = false;

  bool get _isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.document!.title;
      _overviewController.text = widget.document!.overview ?? '';
      _selectedCategory = widget.document!.category ?? DocumentCategory.other;
      _documentDate = widget.document!.documentDate;
      _existingFileName = widget.document!.fileName;
      _existingFileUrl = widget.document!.fileUrl;
      
      // Load tags
      if (widget.document!.tags != null && widget.document!.tags!.isNotEmpty) {
        _tagsController.text = widget.document!.tags!.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _overviewController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDocumentDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _documentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Dokumen',
    );
    if (selectedDate != null) {
      setState(() => _documentDate = selectedDate);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt', 'xlsx', 'xls', 'ppt', 'pptx'],
        allowMultiple: false,
        withData: true, // Important: load bytes for all platforms
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        setState(() {
          _selectedFile = platformFile;
          _removeExistingFile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      if (_isEdit && _existingFileUrl != null) {
        _removeExistingFile = true;
      }
    });
  }

  Future<void> _viewExistingFile() async {
    if (_existingFileUrl == null) return;

    try {
      final url = Uri.parse(_existingFileUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _parseTags(String tagsText) {
    if (tagsText.trim().isEmpty) return [];
    return tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final overview = _overviewController.text.trim();
      final overviewValue = overview.isEmpty ? null : overview;
      final tags = _parseTags(_tagsController.text);
      final tagsValue = tags.isEmpty ? null : tags;

      if (_isEdit) {
        await _documentService.updateDocument(
          documentId: widget.document!.id,
          title: title,
          overview: overviewValue,
          documentDate: _documentDate,
          category: _selectedCategory,
          tags: tagsValue,
          newFileBytes: _selectedFile?.bytes,
          newFileName: _selectedFile?.name,
          removeFile: _removeExistingFile,
        );
      } else {
        await _documentService.createDocument(
          title: title,
          overview: overviewValue,
          documentDate: _documentDate,
          category: _selectedCategory,
          tags: tagsValue,
          fileBytes: _selectedFile?.bytes,
          fileName: _selectedFile?.name,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  IconData _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.certificate:
        return Icons.workspace_premium;
      case DocumentCategory.transcript:
        return Icons.receipt_long;
      case DocumentCategory.idCard:
        return Icons.badge;
      case DocumentCategory.familyCard:
        return Icons.family_restroom;
      case DocumentCategory.diploma:
        return Icons.school;
      case DocumentCategory.portfolio:
        return Icons.work;
      case DocumentCategory.report:
        return Icons.assessment;
      case DocumentCategory.proposal:
        return Icons.article;
      case DocumentCategory.research:
        return Icons.science;
      case DocumentCategory.other:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine file to display
    String? displayFileName;
    if (_selectedFile != null) {
      displayFileName = _selectedFile!.name;
    } else if (_isEdit && !_removeExistingFile && _existingFileName != null) {
      displayFileName = _existingFileName;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Dokumen' : 'Tambah Dokumen',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDocument,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Judul Dokumen
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Dokumen',
                hintText: 'Contoh: Sertifikat Lomba Hackathon 2024',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul dokumen harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kategori Dokumen
            DropdownButtonFormField<DocumentCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori Dokumen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: DocumentCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: Document.getCategoryColor(category),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Overview/Deskripsi
            TextFormField(
              controller: _overviewController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi/Overview (Opsional)',
                hintText: 'Ringkasan singkat tentang dokumen ini',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Tanggal Dokumen
            InkWell(
              onTap: _pickDocumentDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Dokumen (Opsional)',
                  hintText: 'Pilih tanggal dokumen',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _documentDate != null
                      ? DateFormat('d MMMM yyyy').format(_documentDate!)
                      : 'Belum dipilih',
                  style: TextStyle(
                    color: _documentDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (Opsional)',
                hintText: 'Pisahkan dengan koma: hackathon, juara, 2024',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
                helperText: 'Gunakan koma (,) untuk memisahkan tags',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // File Upload Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file, color: Color(0xFF0078C1)),
                        const SizedBox(width: 8),
                        const Text(
                          'File Dokumen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (displayFileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayFileName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isEdit && _selectedFile == null && !_removeExistingFile && _existingFileUrl != null)
                              IconButton(
                                icon: const Icon(Icons.download, color: Colors.blue),
                                onPressed: _viewExistingFile,
                                tooltip: 'Unduh file',
                              ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _removeFile,
                              tooltip: 'Hapus file',
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Belum ada file dipilih',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(displayFileName != null ? 'Ganti File' : 'Pilih File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Format: PDF, DOC, DOCX, JPG, PNG, TXT, XLS, XLSX, PPT, PPTX',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dokumen akan tersimpan dengan aman di cloud storage. Anda bisa mengupload file hingga 50MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
