// ============================================================
// SiberKalkan - Giriş / Kayıt Ekranı
// Dosya Yolu: lib/screens/auth_screen.dart
// Firebase Auth ile email/şifre + anonim giriş
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siber_kalkan/providers/app_providers.dart';
import 'package:siber_kalkan/screens/role_selection_screen.dart';
import 'package:siber_kalkan/services/auth_service.dart';
import 'package:siber_kalkan/utils/constants.dart';
import 'package:siber_kalkan/models/user_model.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      _goToRoleSelection(result);
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'E-posta ve şifre gerekli');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      _goToRoleSelection(result);
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  Future<void> _handleAnonymous() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.loginAnonymously(
      displayName: _nameController.text.trim().isEmpty
          ? 'Kullanıcı'
          : _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      _goToRoleSelection(result);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final result = await authService.loginWithGoogle();

    setState(() => _isLoading = false);

    if (result.success) {
      _goToRoleSelection(result);
    } else if (result.error != 'Giriş iptal edildi') {
      setState(() => _errorMessage = result.error);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Şifre sıfırlamak için e-posta girin');
      return;
    }

    final authService = ref.read(authServiceProvider);
    final error = await authService.resetPassword(email);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Şifre sıfırlama e-postası gönderildi',
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        setState(() => _errorMessage = error);
      }
    }
  }

  void _goToRoleSelection(AuthResult result) {
    // Kullanıcı bilgisini kaydet (rol henüz seçilmedi)
    final userModel = UserModel(
      uid: result.uid!,
      role: '', // Rol seçimi ekranında belirlenecek
      displayName: result.displayName ?? 'Kullanıcı',
    );
    ref.read(userProvider.notifier).setUser(userModel);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                AppConstants.appName,
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.grey,
                  labelStyle: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: 'Giriş Yap'),
                    Tab(text: 'Kayıt Ol'),
                  ],
                  onTap: (_) => setState(() => _errorMessage = null),
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final isRegister = _tabController.index == 1;
                    return Column(
                      children: [
                        // İsim alanı (sadece kayıt)
                        if (isRegister)
                          _buildField(
                            controller: _nameController,
                            label: 'Ad Soyad',
                            icon: Icons.person_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ad soyad gerekli';
                              }
                              return null;
                            },
                          ),
                        if (isRegister) const SizedBox(height: 16),

                        // Email
                        _buildField(
                          controller: _emailController,
                          label: 'E-posta',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'E-posta gerekli';
                            }
                            if (!v.contains('@')) return 'Geçersiz e-posta';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Şifre
                        _buildField(
                          controller: _passwordController,
                          label: 'Şifre',
                          icon: Icons.lock_rounded,
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.grey,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre gerekli';
                            if (isRegister && v.length < 6) {
                              return 'En az 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Şifremi unuttum (sadece giriş)
                        if (!isRegister)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleResetPassword,
                              child: Text(
                                'Şifremi Unuttum',
                                style: GoogleFonts.nunito(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),

                        // Hata mesajı
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.dangerRed, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.nunito(
                                      color: AppColors.dangerRed,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Ana buton
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (isRegister
                                    ? _handleRegister
                                    : _handleLogin),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    isRegister ? 'Kayıt Ol' : 'Giriş Yap',
                                    style: GoogleFonts.nunito(fontSize: 20),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Ayırıcı
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'veya',
                      style: GoogleFonts.nunito(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Google ile Giriş
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata_rounded,
                      color: AppColors.primaryGreen, size: 36),
                  label: Text(
                    'Google ile Giriş Yap',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Anonim devam
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleAnonymous,
                  icon: const Icon(Icons.person_outline,
                      color: AppColors.primaryGreen),
                  label: Text(
                    'Hesapsız Devam Et',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yaşlılar için önerilir — hızlı başlangıç',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.nunito(fontSize: 18),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(color: AppColors.grey),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
      ),
    );
  }
}
