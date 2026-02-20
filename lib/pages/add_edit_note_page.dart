import 'package:flutter/material.dart';
import 'package:synergy/models/personal_note.dart';
import 'package:synergy/services/personal_notes_service.dart';
import 'package:synergy/constants/app_colors.dart';

class AddEditNotePage extends StatefulWidget {
  final PersonalNote? note;

  const AddEditNotePage({
    super.key,
    this.note,
  });

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesService = PersonalNotesService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (_isEdit) {
        await _notesService.updateNote(
          noteId: widget.note!.id,
          title: title,
          content: content.isEmpty ? null : content,
        );
      } else {
        await _notesService.createNote(
          title: title,
          content: content.isEmpty ? null : content,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true untuk indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan' : 'Tambah Catatan',
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
              onPressed: _saveNote,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Judul
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Masukkan judul catatan...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: !_isEdit,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Isi Catatan
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                hintText: 'Tulis catatan Anda di sini...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null, // Unlimited lines
              minLines: 15, // Minimum 15 lines
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Info tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    size: 20, 
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan akan otomatis tersimpan saat Anda klik tombol ✓ di atas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
