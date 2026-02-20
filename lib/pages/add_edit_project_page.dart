import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synergy/models/project.dart';
import 'package:synergy/services/project_service.dart';
import 'package:synergy/constants/app_colors.dart';

class AddEditProjectPage extends StatefulWidget {
  final Project? project;

  const AddEditProjectPage({
    super.key,
    this.project,
  });

  @override
  State<AddEditProjectPage> createState() => _AddEditProjectPageState();
}

class _AddEditProjectPageState extends State<AddEditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = ProjectService();
  final _titleController = TextEditingController();
  final _overviewController = TextEditingController();
  final _roleController = TextEditingController();
  final _technologiesController = TextEditingController();
  final _projectUrlController = TextEditingController();
  final _repositoryUrlController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isOngoing = false;
  bool _isSaving = false;

  bool get _isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.project!.title;
      _overviewController.text = widget.project!.overview ?? '';
      _roleController.text = widget.project!.role;
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _isOngoing = widget.project!.isOngoing;
      _projectUrlController.text = widget.project!.projectUrl ?? '';
      _repositoryUrlController.text = widget.project!.repositoryUrl ?? '';
      
      // Load technologies
      if (widget.project!.technologies != null && widget.project!.technologies!.isNotEmpty) {
        _technologiesController.text = widget.project!.technologies!.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _overviewController.dispose();
    _roleController.dispose();
    _technologiesController.dispose();
    _projectUrlController.dispose();
    _repositoryUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Mulai',
    );
    if (selectedDate != null) {
      setState(() => _startDate = selectedDate);
    }
  }

  Future<void> _pickEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Selesai',
    );
    if (selectedDate != null) {
      setState(() {
        _endDate = selectedDate;
        _isOngoing = false;
      });
    }
  }

  List<String> _parseTechnologies(String techText) {
    if (techText.trim().isEmpty) return [];
    return techText
        .split(',')
        .map((tech) => tech.trim())
        .where((tech) => tech.isNotEmpty)
        .toList();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isOngoing && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai harus diisi atau centang "Masih Berjalan"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final overview = _overviewController.text.trim();
      final role = _roleController.text.trim();
      final technologies = _parseTechnologies(_technologiesController.text);
      final projectUrl = _projectUrlController.text.trim();
      final repositoryUrl = _repositoryUrlController.text.trim();

      if (_isEdit) {
        await _projectService.updateProject(
          projectId: widget.project!.id,
          title: title,
          overview: overview.isEmpty ? null : overview,
          startDate: _startDate!,
          endDate: _isOngoing ? null : _endDate,
          role: role,
          technologies: technologies.isEmpty ? null : technologies,
          projectUrl: projectUrl.isEmpty ? null : projectUrl,
          repositoryUrl: repositoryUrl.isEmpty ? null : repositoryUrl,
        );
      } else {
        await _projectService.createProject(
          title: title,
          overview: overview.isEmpty ? null : overview,
          startDate: _startDate!,
          endDate: _isOngoing ? null : _endDate,
          role: role,
          technologies: technologies.isEmpty ? null : technologies,
          projectUrl: projectUrl.isEmpty ? null : projectUrl,
          repositoryUrl: repositoryUrl.isEmpty ? null : repositoryUrl,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Project' : 'Tambah Project',
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
              onPressed: _saveProject,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Nama Project
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Project',
                hintText: 'Contoh: Aplikasi Mobile E-Commerce',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama project harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Role/Jabatan
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role/Jabatan',
                hintText: 'Contoh: Full Stack Developer, Project Manager',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Role/Jabatan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Overview/Deskripsi
            TextFormField(
              controller: _overviewController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Project (Opsional)',
                hintText: 'Ringkasan singkat tentang project ini',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Tanggal Mulai
            InkWell(
              onTap: _pickStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Mulai *',
                  hintText: 'Pilih tanggal mulai project',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _startDate != null
                      ? DateFormat('d MMMM yyyy').format(_startDate!)
                      : 'Belum dipilih',
                  style: TextStyle(
                    color: _startDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Checkbox: Masih Berjalan
            CheckboxListTile(
              title: const Text('Project masih berjalan'),
              subtitle: const Text('Centang jika project belum selesai'),
              value: _isOngoing,
              onChanged: (value) {
                setState(() {
                  _isOngoing = value ?? false;
                  if (_isOngoing) {
                    _endDate = null;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),

            // Tanggal Selesai (disabled jika ongoing)
            InkWell(
              onTap: _isOngoing ? null : _pickEndDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal Selesai ${_isOngoing ? '' : '*'}',
                  hintText: _isOngoing ? 'Project masih berjalan' : 'Pilih tanggal selesai',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event_available),
                  enabled: !_isOngoing,
                ),
                child: Text(
                  _isOngoing
                      ? 'Masih berjalan'
                      : (_endDate != null
                          ? DateFormat('d MMMM yyyy').format(_endDate!)
                          : 'Belum dipilih'),
                  style: TextStyle(
                    color: _isOngoing
                        ? Colors.grey
                        : (_endDate != null ? Colors.black : Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Technologies
            TextFormField(
              controller: _technologiesController,
              decoration: const InputDecoration(
                labelText: 'Teknologi/Tools (Opsional)',
                hintText: 'Flutter, Firebase, Node.js, PostgreSQL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
                helperText: 'Pisahkan dengan koma (,)',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Project URL
            TextFormField(
              controller: _projectUrlController,
              decoration: const InputDecoration(
                labelText: 'Project URL (Opsional)',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                helperText: 'Link demo atau website project',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Repository URL
            TextFormField(
              controller: _repositoryUrlController,
              decoration: const InputDecoration(
                labelText: 'Repository URL (Opsional)',
                hintText: 'https://github.com/username/repo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.terminal),
                helperText: 'Link GitHub, GitLab, atau repository lainnya',
              ),
              keyboardType: TextInputType.url,
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
                        'Tambahkan semua project yang pernah Anda kerjakan untuk memperkaya portfolio',
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
