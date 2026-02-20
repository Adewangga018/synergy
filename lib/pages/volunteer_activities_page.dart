import 'package:flutter/material.dart';
import 'package:synergy/models/volunteer_activity.dart';
import 'package:synergy/services/volunteer_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'add_edit_volunteer_page.dart';

class VolunteerActivitiesPage extends StatefulWidget {
  const VolunteerActivitiesPage({super.key});

  @override
  State<VolunteerActivitiesPage> createState() => _VolunteerActivitiesPageState();
}

class _VolunteerActivitiesPageState extends State<VolunteerActivitiesPage> {
  final _volunteerService = VolunteerService();
  List<VolunteerActivity> _activities = [];
  bool _isLoading = true;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final activities = await _volunteerService.getActivities(
        activeOnly: _showActiveOnly,
      );
      if (mounted) {
        setState(() {
          _activities = activities;
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

  Future<void> _navigateToAddEdit([VolunteerActivity? activity]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditVolunteerPage(activity: activity),
      ),
    );

    if (result == true) {
      _loadActivities();
    }
  }

  Future<void> _deleteActivity(VolunteerActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kegiatan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${activity.activityName}"?',
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
        await _volunteerService.deleteActivity(activity.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kegiatan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadActivities();
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
        title: const Text('Volunteer & Kegiatan', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            tooltip: _showActiveOnly ? 'Tampilkan Semua' : 'Hanya Aktif',
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              _loadActivities();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showActiveOnly
                            ? 'Belum ada kegiatan aktif'
                            : 'Belum ada data volunteer/kegiatan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadActivities,
                  child: ListView.builder(
                    itemCount: _activities.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final activity = _activities[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            activity.isActive
                                ? Icons.check_circle
                                : Icons.history,
                            color: activity.isActive
                                ? Colors.green
                                : Colors.grey,
                            size: 32,
                          ),
                          title: Text(
                            activity.activityName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Peran: ${activity.role}'),
                              Text(
                                'Durasi: ${activity.durationString}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (activity.isActive)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Sedang Aktif',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
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
                                _navigateToAddEdit(activity);
                              } else if (value == 'delete') {
                                _deleteActivity(activity);
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
                          onTap: () => _navigateToAddEdit(activity),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Volunteer/Kegiatan',
      ),
    );
  }
}
