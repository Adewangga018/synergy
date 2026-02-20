import 'package:flutter/material.dart';
import 'package:synergy/models/user_profile.dart';
import 'package:synergy/services/auth_service.dart';
import 'package:synergy/services/profile_photo_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _authService = AuthService();
  final _photoService = ProfilePhotoService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0078C1)),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0078C1)),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(fromCamera: true);
              },
            ),
            if (_userProfile?.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto({required bool fromCamera}) async {
    try {
      setState(() => _isUploadingPhoto = true);

      // Pick image
      final imageFile = fromCamera
          ? await _photoService.pickFromCamera()
          : await _photoService.pickFromGallery();

      if (imageFile == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Upload (otomatis update database juga)
      await _photoService.uploadPhoto(imageFile);

      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isUploadingPhoto = true);

      // Hapus foto (otomatis update database juga)
      await _photoService.deletePhoto(_userProfile!.photoUrl!);

      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout gagal: ${e.toString()}'),
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
        title: const Text('Akun Saya', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Gagal memuat profil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header dengan Avatar
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                // Avatar dengan foto atau initial
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFF013880),
                                  backgroundImage: _userProfile!.photoUrl != null
                                      ? NetworkImage(_userProfile!.photoUrl!)
                                      : null,
                                  child: _userProfile!.photoUrl == null
                                      ? Text(
                                          _userProfile!.namaPanggilan[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                // Loading indicator saat upload
                                if (_isUploadingPhoto)
                                  Positioned.fill(
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.black54,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                // Edit button
                                if (!_isUploadingPhoto)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _showPhotoOptions,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0078C1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userProfile!.namaPanggilan,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profil Card
                      Card(
                        elevation: 2,
                        color: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Pribadi',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const Divider(height: 24, color: Colors.white),
                              _buildProfileItem(
                                icon: Icons.person,
                                label: 'Nama Lengkap',
                                value: _userProfile!.namaLengkap,
                              ),
                              const SizedBox(height: 16),
                              _buildProfileItem(
                                icon: Icons.badge,
                                label: 'NRP',
                                value: _userProfile!.nrp,
                              ),
                              const SizedBox(height: 16),
                              _buildProfileItem(
                                icon: Icons.school,
                                label: 'Jurusan',
                                value: _userProfile!.jurusan,
                              ),
                              const SizedBox(height: 16),
                              _buildProfileItem(
                                icon: Icons.calendar_today,
                                label: 'Angkatan',
                                value: _userProfile!.angkatan,
                              ),
                              const SizedBox(height: 16),
                              _buildProfileItem(
                                icon: Icons.email,
                                label: 'Email',
                                value: _userProfile!.email,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar dari Akun'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
