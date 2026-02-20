import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synergy/models/project.dart';
import 'package:synergy/services/project_service.dart';
import 'package:synergy/pages/add_edit_project_page.dart';
import 'package:synergy/constants/app_colors.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _projectService = ProjectService();
  final _searchController = TextEditingController();
  
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, ongoing, completed

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _projectService.getProjects();
      setState(() {
        _projects = projects;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _projects;

    // Filter by status
    if (_statusFilter == 'ongoing') {
      filtered = filtered.where((p) => p.isOngoing).toList();
    } else if (_statusFilter == 'completed') {
      filtered = filtered.where((p) => !p.isOngoing).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final query = _searchQuery.toLowerCase();
        return project.title.toLowerCase().contains(query) ||
            (project.overview?.toLowerCase().contains(query) ?? false) ||
            project.role.toLowerCase().contains(query) ||
            (project.technologies?.any((tech) => tech.toLowerCase().contains(query)) ?? false);
      }).toList();
    }

    setState(() => _filteredProjects = filtered);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _applyFilters();
  }

  void _onStatusFilterChanged(String? value) {
    if (value != null) {
      setState(() => _statusFilter = value);
      _applyFilters();
    }
  }

  Future<void> _navigateToAddEdit([Project? project]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProjectPage(project: project),
      ),
    );

    if (result == true) {
      _loadProjects();
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Project'),
        content: Text('Yakin ingin menghapus "${project.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _projectService.deleteProject(project.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProjects();
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

  Future<void> _openUrl(String? url, String label) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka $label'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka URL: ${e.toString()}'),
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
        title: const Text('Projects', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Cari project, role, atau teknologi...',
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
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Status Filter
                      Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 8),
                          const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _statusFilter,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Semua')),
                                DropdownMenuItem(value: 'ongoing', child: Text('Sedang Berjalan')),
                                DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                              ],
                              onChanged: _onStatusFilterChanged,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Results Count
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[200],
                    child: Row(
                      children: [
                        Text(
                          '${_filteredProjects.length} project ditemukan',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Projects List
                Expanded(
                  child: _filteredProjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _statusFilter != 'all'
                                    ? 'Tidak ada project yang sesuai'
                                    : 'Belum ada project',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = _filteredProjects[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: project.isOngoing ? Colors.green : Colors.blue,
                                  child: Icon(
                                    project.isOngoing ? Icons.pending_actions : Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  project.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    
                                    // Role
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          project.role,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Duration
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('MMM yyyy').format(project.startDate)} - ${project.endDate != null ? DateFormat('MMM yyyy').format(project.endDate!) : 'Sekarang'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${project.formattedDuration})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Technologies
                                    if (project.technologies != null && project.technologies!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: project.technologies!.take(3).map((tech) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                tech,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                            );
                                          }).toList()
                                            ..addAll(
                                              project.technologies!.length > 3
                                                  ? [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        child: Text(
                                                          '+${project.technologies!.length - 3}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
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
                                      _navigateToAddEdit(project);
                                    } else if (value == 'view_project') {
                                      _openUrl(project.projectUrl, 'Project URL');
                                    } else if (value == 'view_repo') {
                                      _openUrl(project.repositoryUrl, 'Repository');
                                    } else if (value == 'delete') {
                                      _deleteProject(project);
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
                                    if (project.projectUrl != null && project.projectUrl!.isNotEmpty)
                                      const PopupMenuItem(
                                        value: 'view_project',
                                        child: Row(
                                          children: [
                                            Icon(Icons.open_in_new, size: 20),
                                            SizedBox(width: 8),
                                            Text('Buka Project'),
                                          ],
                                        ),
                                      ),
                                    if (project.repositoryUrl != null && project.repositoryUrl!.isNotEmpty)
                                      const PopupMenuItem(
                                        value: 'view_repo',
                                        child: Row(
                                          children: [
                                            Icon(Icons.code, size: 20),
                                            SizedBox(width: 8),
                                            Text('Buka Repository'),
                                          ],
                                        ),
                                      ),
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
                                onTap: () => _navigateToAddEdit(project),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Tambah Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
