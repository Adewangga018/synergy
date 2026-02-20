import 'package:flutter/material.dart';
import 'package:synergy/services/auth_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaLengkapController = TextEditingController();
  final _namaPanggilanController = TextEditingController();
  final _nrpController = TextEditingController();
  final _jurusanController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _angkatanController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Daftar jurusan
  final List<String> _jurusanList = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Teknik Elektro',
    'Teknik Mesin',
    'Teknik Kimia',
    'Teknik Sipil',
    'Manajemen',
    'Akuntansi',
  ];

  String? _selectedJurusan;

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _namaPanggilanController.dispose();
    _nrpController.dispose();
    _jurusanController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _angkatanController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan konfirmasi password tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cek apakah NRP sudah terdaftar
      final nrpExists = await _authService.isNRPExists(_nrpController.text.trim());
      if (nrpExists) {
        throw Exception('NRP sudah terdaftar');
      }

      // Cek apakah email sudah terdaftar
      final emailExists = await _authService.isEmailExists(_emailController.text.trim());
      if (emailExists) {
        throw Exception('Email sudah terdaftar');
      }

      // Register user
      await _authService.register(
        namaLengkap: _namaLengkapController.text.trim(),
        namaPanggilan: _namaPanggilanController.text.trim(),
        nrp: _nrpController.text.trim(),
        jurusan: _selectedJurusan ?? '',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        angkatan: _angkatanController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Registrasi gagal';
        
        if (e.toString().contains('over_email_send_rate_limit')) {
          errorMessage = 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
        } else if (e.toString().contains('User already registered')) {
          errorMessage = 'Email sudah terdaftar.';
        } else if (e.toString().contains('NRP sudah terdaftar')) {
          errorMessage = 'NRP sudah terdaftar.';
        } else if (e.toString().contains('Email sudah terdaftar')) {
          errorMessage = 'Email sudah terdaftar.';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat Akun Baru',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),

                // Nama Lengkap
                TextFormField(
                  controller: _namaLengkapController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukkan nama lengkap Anda',
                    prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nama Panggilan
                TextFormField(
                  controller: _namaPanggilanController,
                  decoration: InputDecoration(
                    labelText: 'Nama Panggilan',
                    hintText: 'Masukkan nama panggilan Anda',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama panggilan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // NRP
                TextFormField(
                  controller: _nrpController,
                  decoration: InputDecoration(
                    labelText: 'NRP',
                    hintText: 'Masukkan NRP Anda',
                    prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NRP tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Jurusan (Dropdown)
                DropdownButtonFormField<String>(
                  value: _selectedJurusan,
                  decoration: InputDecoration(
                    labelText: 'Jurusan',
                    prefixIcon: const Icon(Icons.school, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _jurusanList.map((String jurusan) {
                    return DropdownMenuItem<String>(
                      value: jurusan,
                      child: Text(jurusan),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedJurusan = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jurusan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Angkatan
                TextFormField(
                  controller: _angkatanController,
                  decoration: InputDecoration(
                    labelText: 'Angkatan',
                    hintText: 'Contoh: 2024',
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Angkatan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email Anda',
                    prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    hintText: 'Masukkan ulang password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Masuk di sini'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
