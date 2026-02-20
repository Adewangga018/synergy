import 'package:flutter/material.dart';
import 'package:synergy/models/competition.dart';
import 'package:synergy/services/competition_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'add_edit_competition_page.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  final _competitionService = CompetitionService();
  List<Competition> _competitions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() => _isLoading = true);
    try {
      final competitions = await _competitionService.getCompetitions(
        categoryFilter: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _competitions = competitions;
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

  Future<void> _navigateToAddEdit([Competition? competition]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditCompetitionPage(competition: competition),
      ),
    );

    if (result == true) {
      _loadCompetitions();
    }
  }

  Future<void> _deleteCompetition(Competition competition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Perlombaan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${competition.compName}"?',
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
        await _competitionService.deleteCompetition(competition.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perlombaan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCompetitions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perlombaan', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari perlombaan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadCompetitions();
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _competitions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Belum ada data perlombaan'
                            : 'Tidak ada hasil pencarian',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompetitions,
                  child: ListView.builder(
                    itemCount: _competitions.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final competition = _competitions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.emoji_events,
                            color: competition.achievementColor,
                            size: 32,
                          ),
                          title: Text(
                            competition.compName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (competition.category != null)
                                Text('Kategori: ${competition.category}'),
                              if (competition.achievement != null)
                                Text(
                                  'Prestasi: ${competition.achievement}',
                                  style: TextStyle(
                                    color: competition.achievementColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              Text(
                                'Tanggal: ${competition.formattedEventDate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigateToAddEdit(competition);
                              } else if (value == 'delete') {
                                _deleteCompetition(competition);
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
                          onTap: () => _navigateToAddEdit(competition),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Perlombaan',
      ),
    );
  }
}
