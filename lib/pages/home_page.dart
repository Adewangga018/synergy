import 'dart:math';
import 'package:flutter/material.dart';
import 'package:synergy/models/user_profile.dart';
import 'package:synergy/services/auth_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'account_page.dart';
import 'personal_notes_page.dart';
import 'competitions_page.dart';
import 'volunteer_activities_page.dart';
import 'organizations_page.dart';
import 'documents_page.dart';
import 'projects_page.dart';
import 'course_schedules_page.dart';
import 'calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _motivationalQuote = '';

  // Daftar kata-kata motivasi untuk mahasiswa
  final List<String> _motivationalQuotes = [
    'Setiap langkah kecil adalah kemajuan menuju kesuksesan besar.',
    'Prestasi hari ini adalah investasi untuk masa depan cemerlang.',
    'Jangan takut gagal, karena kegagalan adalah guru terbaik.',
    'Organisasi dan volunteer bukan hanya CV builder, tapi character builder.',
    'Kompetensi + Karakter = Mahasiswa Unggul!',
    'Catat setiap pencapaianmu, karena progress kecil adalah kemenangan.',
    'Mahasiswa berprestasi bukan yang sempurna, tapi yang konsisten.',
    'Balance antara akademik, organisasi, dan pengembangan diri adalah kunci.',
    'Setiap kompetisi adalah kesempatan belajar dan berkembang.',
    'Networking hari ini adalah peluang kerja masa depan.',
    'Jangan membandingkan journey-mu dengan orang lain, fokus pada progresmu.',
    'Soft skills sama pentingnya dengan hard skills di dunia kerja.',
    'Dokumentasikan setiap pencapaian, sekecil apapun itu.',
    'Leadership bukan tentang jabatan, tapi tentang memberi dampak.',
    'Keluar dari zona nyaman adalah tempat pertumbuhan dimulai.',
    'Mahasiswa aktif bukan yang sibuk, tapi yang produktif dan bermakna.',
    'Setiap pengalaman adalah portfolio untuk masa depanmu.',
    'Gagal dalam kompetisi? Itu artinya kamu berani mencoba!',
    'Konsisten lebih penting dari intensitas sesaat.',
    'Manfaatkan masa kuliahmu untuk eksplorasi dan inovasi.',
    'Prestasi bukan hanya juara, tapi juga keberanian berpartisipasi.',
    'Volunteer mengajarkan empati, leadership mengajarkan tanggung jawab.',
    'Setiap hari adalah kesempatan untuk belajar sesuatu yang baru.',
    'Jangan menunda, mulai dari yang kecil hari ini.',
    'Mahasiswa hebat adalah yang belajar dari pengalaman dan mentoring orang lain.',
    'Komitmen pada diri sendiri adalah investasi terbaik.',
    'Sukses adalah hasil dari persiapan, kerja keras, dan belajar dari kesalahan.',
    'Jangan hanya kuliah, tapi juga berkontribusi untuk masyarakat.',
    'Setiap kegiatan adalah peluang untuk mengembangkan skill baru.',
    'Fokus pada progress, bukan perfection.',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _generateRandomQuote();
  }

  void _generateRandomQuote() {
    final random = Random();
    setState(() {
      _motivationalQuote = _motivationalQuotes[random.nextInt(_motivationalQuotes.length)];
    });
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

  void _navigateToAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo-synergy.png',
          height: 40,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            // Fallback jika logo tidak ada
            return const Text('Synergy', style: TextStyle(color: Colors.white));
          },
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: _navigateToAccount,
            tooltip: 'Akun Saya',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Gagal memuat profil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Motivational Hero Banner
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF013880), // Biru ITS Gelap
                              Color(0xFF0078C1), // Biru ITS Terang
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF013880).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.wb_sunny,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Halo selamat datang ${_userProfile!.namaPanggilan}, Gimana kabarmu?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.format_quote,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _motivationalQuote,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Menu
                      Text(
                        'Menu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _buildMenuCard(
                            icon: Icons.note_alt,
                            title: 'Catatan Pribadi',
                            color: const Color(0xFF0078C1),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PersonalNotesPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.emoji_events,
                            title: 'Perlombaan',
                            color: const Color(0xFFFFB300),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CompetitionsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.volunteer_activism,
                            title: 'Volunteer & Kegiatan',
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const VolunteerActivitiesPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.corporate_fare,
                            title: 'Organisasi',
                            color: const Color(0xFF013880),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const OrganizationsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.folder,
                            title: 'Dokumen',
                            color: const Color(0xFF9C27B0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const DocumentsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.work,
                            title: 'Projects',
                            color: const Color(0xFFFF6F00),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ProjectsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.schedule,
                            title: 'Jadwal Kuliah',
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CourseSchedulesPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.calendar_month,
                            title: 'Kalender',
                            color: const Color(0xFFE91E63),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CalendarPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
