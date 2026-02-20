class UserProfile {
  final String id;
  final String namaLengkap;
  final String namaPanggilan;
  final String nrp;
  final String jurusan;
  final String email;
  final String angkatan;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.namaLengkap,
    required this.namaPanggilan,
    required this.nrp,
    required this.jurusan,
    required this.email,
    required this.angkatan,
    this.photoUrl,
  });

  // Convert dari JSON (dari Supabase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      namaPanggilan: json['nama_panggilan'] as String,
      nrp: json['nrp'] as String,
      jurusan: json['jurusan'] as String,
      email: json['email'] as String,
      angkatan: json['angkatan'] as String,
      photoUrl: json['photo_url'] as String?,
    );
  }

  // Convert ke JSON (untuk kirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'nama_panggilan': namaPanggilan,
      'nrp': nrp,
      'jurusan': jurusan,
      'email': email,
      'angkatan': angkatan,
      'photo_url': photoUrl,
    };
  }
}
