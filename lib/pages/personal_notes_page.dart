import 'package:flutter/material.dart';
import 'package:synergy/models/personal_note.dart';
import 'package:synergy/services/personal_notes_service.dart';
import 'package:synergy/pages/add_edit_note_page.dart';
import 'package:synergy/constants/app_colors.dart';
import 'package:intl/intl.dart';

class PersonalNotesPage extends StatefulWidget {
  const PersonalNotesPage({super.key});

  @override
  State<PersonalNotesPage> createState() => _PersonalNotesPageState();
}

class _PersonalNotesPageState extends State<PersonalNotesPage> {
  final _notesService = PersonalNotesService();
  final _searchController = TextEditingController();
  
  List<PersonalNote> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  NoteSortOrder _sortOrder = NoteSortOrder.newestFirst;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _notesService.getNotes(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        sortOrder: _sortOrder,
      );
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat catatan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == NoteSortOrder.newestFirst
          ? NoteSortOrder.oldestFirst
          : NoteSortOrder.newestFirst;
    });
    _loadNotes();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    // Delay search untuk performa lebih baik
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) {
        _loadNotes();
      }
    });
  }

  Future<void> _navigateToAddEditNote({PersonalNote? note}) async {
    final isEdit = note != null;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNotePage(note: note),
      ),
    );

    if (result == true) {
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Catatan berhasil diperbarui' : 'Catatan berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(PersonalNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Apakah Anda yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _notesService.deleteNote(note.id);
        _loadNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Kemarin ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Pribadi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Sort button
          IconButton(
            icon: Icon(
              _sortOrder == NoteSortOrder.newestFirst
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: Colors.white,
            ),
            tooltip: _sortOrder == NoteSortOrder.newestFirst
                ? 'Terbaru dulu'
                : 'Terlama dulu',
            onPressed: _toggleSortOrder,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Notes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.note_add : Icons.search_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Belum ada catatan'
                                  : 'Tidak ada hasil pencarian',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambah catatan',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToAddEditNote(note: note),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            color: Colors.red,
                                            onPressed: () => _deleteNote(note),
                                            tooltip: 'Hapus',
                                          ),
                                        ],
                                      ),
                                      if (note.content != null && note.content!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          note.content!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(note.updatedAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditNote(),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
