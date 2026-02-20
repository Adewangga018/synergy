import 'package:flutter/material.dart';
import 'package:synergy/models/competition.dart';
import 'package:synergy/services/competition_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AddEditCompetitionPage extends StatefulWidget {
  final Competition? competition;

  const AddEditCompetitionPage({
    super.key,
    this.competition,
  });

  @override
  State<AddEditCompetitionPage> createState() => _AddEditCompetitionPageState();
}

class _AddEditCompetitionPageState extends State<AddEditCompetitionPage> {
  final _formKey = GlobalKey<FormState>();
  final _competitionService = CompetitionService();
  final _compNameController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedAchievement;
  DateTime? _eventDate;
  bool _isSaving = false;

  // Daftar pilihan kategori
  final List<String> _categoryOptions = [
    'Kampus',
    'Kota/Kabupaten',
    'Provinsi',
    'Nasional',
    'Internasional',
  ];

  // Daftar pilihan prestasi
  final List<String> _achievementOptions = [
    'Juara 1',
    'Juara 2',
    'Juara 3',
    'Harapan 1',
    'Harapan 2',
    'Harapan 3',
    'Peserta',
  ];

  bool get _isEdit => widget.competition != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _compNameController.text = widget.competition!.compName;
      _selectedCategory = widget.competition!.category;
      _selectedAchievement = widget.competition!.achievement;
      _eventDate = widget.competition!.eventDate;
    }
  }

  @override
  void dispose() {
    _compNameController.dispose();
    super.dispose();
  }

  Future<void> _selectEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Event',
    );

    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  void _clearEventDate() {
    setState(() => _eventDate = null);
  }

  Future<void> _saveCompetition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final compName = _compNameController.text.trim();

      if (_isEdit) {
        await _competitionService.updateCompetition(
          competitionId: widget.competition!.id,
          compName: compName,
          category: _selectedCategory,
          achievement: _selectedAchievement,
          eventDate: _eventDate,
        );
      } else {
        await _competitionService.createCompetition(
          compName: compName,
          category: _selectedCategory,
          achievement: _selectedAchievement,
          eventDate: _eventDate,
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
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Perlombaan' : 'Tambah Perlombaan',
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
              onPressed: _saveCompetition,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Nama Perlombaan
            TextFormField(
              controller: _compNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Perlombaan',
                hintText: 'Contoh: Lomba Karya Tulis Ilmiah Nasional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.emoji_events),
              ),
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama perlombaan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kategori (Dropdown)
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                helperText: 'Pilih tingkat/skala perlombaan',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tidak ditentukan'),
                ),
                ..._categoryOptions.map((category) {
                  IconData icon;
                  switch (category) {
                    case 'Kampus':
                      icon = Icons.school;
                      break;
                    case 'Kota/Kabupaten':
                      icon = Icons.location_city;
                      break;
                    case 'Provinsi':
                      icon = Icons.map;
                      break;
                    case 'Nasional':
                      icon = Icons.flag;
                      break;
                    case 'Internasional':
                      icon = Icons.public;
                      break;
                    default:
                      icon = Icons.category;
                  }
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),

            // Prestasi (Dropdown)
            DropdownButtonFormField<String>(
              value: _selectedAchievement,
              decoration: const InputDecoration(
                labelText: 'Prestasi (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.military_tech),
                helperText: 'Pilih pencapaian yang diraih',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tidak ada prestasi'),
                ),
                ..._achievementOptions.map((achievement) {
                  return DropdownMenuItem(
                    value: achievement,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: _getAchievementColor(achievement),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(achievement),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() => _selectedAchievement = value);
              },
            ),
            const SizedBox(height: 16),

            // Tanggal Event
            InkWell(
              onTap: _selectEventDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal Event (Opsional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: _eventDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearEventDate,
                          tooltip: 'Hapus tanggal',
                        )
                      : const Icon(Icons.calendar_today),
                  helperText: _eventDate == null ? 'Tanggal pelaksanaan perlombaan' : null,
                ),
                child: Text(
                  _eventDate != null ? dateFormat.format(_eventDate!) : 'Belum ditentukan',
                  style: TextStyle(
                    fontSize: 16,
                    color: _eventDate == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview Achievement Badge
            if (_selectedAchievement != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAchievementColor(_selectedAchievement!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getAchievementColor(_selectedAchievement!)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: _getAchievementColor(_selectedAchievement!),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preview Badge Prestasi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAchievement!,
                            style: TextStyle(
                              fontSize: 16,
                              color: _getAchievementColor(_selectedAchievement!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getAchievementColor(String achievement) {
    switch (achievement) {
      case 'Juara 1':
        return const Color(0xFFFFD700); // Gold
      case 'Juara 2':
        return const Color(0xFFC0C0C0); // Silver
      case 'Juara 3':
        return const Color(0xFFCD7F32); // Bronze
      case 'Harapan 1':
      case 'Harapan 2':
      case 'Harapan 3':
        return const Color(0xFF00A86B); // Green
      case 'Peserta':
        return const Color(0xFF0078C1); // Blue
      default:
        return const Color(0xFF666666); // Gray
    }
  }
}
