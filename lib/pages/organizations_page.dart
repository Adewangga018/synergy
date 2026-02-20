import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synergy/models/organization.dart';
import 'package:synergy/services/organization_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'add_edit_organization_page.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final _organizationService = OrganizationService();
  List<Organization> _organizations = [];
  bool _isLoading = true;
  OrganizationScale? _filterScale;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() => _isLoading = true);
    try {
      final organizations = await _organizationService.getOrganizations(
        filterByScale: _filterScale,
      );
      if (mounted) {
        setState(() {
          _organizations = organizations;
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

  void _showScaleFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Semua Skala'),
            onTap: () {
              setState(() => _filterScale = null);
              _loadOrganizations();
              Navigator.pop(context);
            },
          ),
          ...OrganizationScale.values.map((scale) {
            String scaleText;
            switch (scale) {
              case OrganizationScale.department:
                scaleText = 'Departemen/Prodi';
                break;
              case OrganizationScale.faculty:
                scaleText = 'Fakultas';
                break;
              case OrganizationScale.campus:
                scaleText = 'Kampus';
                break;
              case OrganizationScale.external:
                scaleText = 'Eksternal';
                break;
            }
            return ListTile(
              leading: Icon(Icons.circle, color: Organization.getScaleColor(scale)),
              title: Text(scaleText),
              onTap: () {
                setState(() => _filterScale = scale);
                _loadOrganizations();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _navigateToAddEdit([Organization? organization]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditOrganizationPage(organization: organization),
      ),
    );

    if (result == true) {
      _loadOrganizations();
    }
  }

  Future<void> _deleteOrganization(Organization organization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Organisasi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${organization.orgName}"?',
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
        await _organizationService.deleteOrganization(organization.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organisasi berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrganizations();
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
        title: const Text('Organisasi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_filterScale != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            tooltip: 'Filter Skala',
            onPressed: _showScaleFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _organizations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.corporate_fare,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterScale != null
                            ? 'Tidak ada organisasi dengan filter ini'
                            : 'Belum ada data organisasi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrganizations,
                  child: ListView.builder(
                    itemCount: _organizations.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final organization = _organizations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.corporate_fare,
                            color: organization.scaleColor,
                            size: 32,
                          ),
                          title: Text(
                            organization.orgName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Jabatan: ${organization.position}'),
                              Text(
                                'Skala: ${organization.scaleString}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: organization.scaleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (organization.startDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    organization.endDate != null
                                        ? '${DateFormat('d MMM yyyy').format(organization.startDate!)} - ${DateFormat('d MMM yyyy').format(organization.endDate!)}'
                                        : '${DateFormat('d MMM yyyy').format(organization.startDate!)} - Sekarang',
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
                                _navigateToAddEdit(organization);
                              } else if (value == 'delete') {
                                _deleteOrganization(organization);
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
                          onTap: () => _navigateToAddEdit(organization),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Organisasi',
      ),
    );
  }
}
