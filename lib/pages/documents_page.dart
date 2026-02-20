import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synergy/models/document.dart';
import 'package:synergy/services/document_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'add_edit_document_page.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _documentService = DocumentService();
  final _searchController = TextEditingController();
  List<Document> _documents = [];
  bool _isLoading = true;
  DocumentCategory? _filterCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final documents = await _documentService.getDocuments(
        filterByCategory: _filterCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Filter Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Semua Kategori'),
            onTap: () {
              setState(() => _filterCategory = null);
              _loadDocuments();
              Navigator.pop(context);
            },
          ),
          ...DocumentCategory.values.map((category) {
            return ListTile(
              leading: Icon(
                Document.getCategoryIcon(category),
                color: Document.getCategoryColor(category),
              ),
              title: Text(category.displayName),
              onTap: () {
                setState(() => _filterCategory = category);
                _loadDocuments();
                Navigator.pop(context);
              },
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadDocuments();
  }

  Future<void> _navigateToAddEdit([Document? document]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditDocumentPage(document: document),
      ),
    );

    if (result == true) {
      _loadDocuments();
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dokumen'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${document.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _documentService.deleteDocument(document.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dokumen berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDocuments();
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

  Future<void> _viewDocument(Document document) async {
    if (!document.hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumen ini tidak memiliki file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final url = document.fileUrl!;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka URL';
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

  Future<void> _downloadDocument(Document document) async {
    if (!document.hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumen ini tidak memiliki file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final url = _documentService.createDownloadLink(document) ?? document.fileUrl!;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mengunduh ${document.fileName ?? "dokumen"}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Tidak dapat membuka URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumen', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_filterCategory != null 
                ? Icons.filter_alt 
                : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            tooltip: 'Filter Kategori',
            onPressed: _showCategoryFilter,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari dokumen...',
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
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Tidak ada dokumen yang cocok'
                            : _filterCategory != null
                                ? 'Tidak ada dokumen dengan kategori ini'
                                : 'Belum ada dokumen',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    itemCount: _documents.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final document = _documents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: document.categoryColor.withOpacity(0.2),
                            child: Icon(
                              document.categoryIcon,
                              color: document.categoryColor,
                            ),
                          ),
                          title: Text(
                            document.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (document.overview != null)
                                Text(
                                  document.overview!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: document.categoryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      document.categoryString,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: document.categoryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (document.hasFile)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.attach_file,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            document.formattedFileSize,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (document.documentDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('d MMMM yyyy').format(document.documentDate!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigateToAddEdit(document);
                              } else if (value == 'view') {
                                _viewDocument(document);
                              } else if (value == 'download') {
                                _downloadDocument(document);
                              } else if (value == 'delete') {
                                _deleteDocument(document);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              if (document.hasFile) ...[
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_new, size: 20),
                                      SizedBox(width: 8),
                                      Text('Lihat File'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'download',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 20),
                                      SizedBox(width: 8),
                                      Text('Unduh File'),
                                    ],
                                  ),
                                ),
                              ],
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _navigateToAddEdit(document),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Tambah Dokumen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
