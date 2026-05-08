import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _didPrefillEmail = false;

  static const _navy = Color(0xFF061B4E);
  static const _muted = Color(0xFF7E90B5);
  static const _fieldBorder = Color(0xFFC9D7EE);
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '479016220889-9oiqrc1229fqi057bu9h5im60g8p9shq.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthLoginOptionsRequested());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text,
        password: _passwordController.text,
        rememberAccount: false,
        enableBiometric: false,
      ),
    );
  }

  Future<void> _openGoogleSso() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: _googleServerClientId,
      );
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null || !mounted) return;

      final auth = await account.authentication;
      if (!mounted) return;

      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google belum mengembalikan id token. Periksa konfigurasi OAuth Android/iOS.',
            ),
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
        AuthGoogleLoginRequested(
          idToken: idToken,
          serverAuthCode: account.serverAuthCode,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'sign_in_canceled' => 'Login Google dibatalkan.',
        'network_error' => 'Koneksi ke Google bermasalah.',
        'sign_in_failed' =>
          'Google Sign-In gagal. Periksa OAuth package org.sppips.komando dan SHA-1 debug.',
        _ => 'Google Sign-In gagal (${e.code}). ${e.message ?? ''}',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final preferences = state is AuthLoginOptionsLoaded
              ? state.preferences
              : null;

          if (!_didPrefillEmail &&
              (preferences?.rememberedEmail?.isNotEmpty ?? false)) {
            _emailController.text = preferences!.rememberedEmail!;
            _didPrefillEmail = true;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final safeTop = MediaQuery.paddingOf(context).top;
              final safeBottom = MediaQuery.paddingOf(context).bottom;
              final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
              final keyboardVisible = keyboardInset > 0;
              final isShort = height < 760;
              final isVeryShort = height < 690;
              final cardHeight = (height * (isVeryShort ? 0.34 : 0.38)).clamp(
                292.0,
                340.0,
              );
              final keyboardLift = keyboardVisible
                  ? (keyboardInset - safeBottom + 12).clamp(0.0, height * 0.42)
                  : 0.0;
              final cardBottom = safeBottom + 32 + keyboardLift;
              final cardTop = height - cardBottom - cardHeight;
              final heroOverlap = keyboardVisible ? 34.0 : 190.0;
              final heroBottom = (cardTop - heroOverlap).clamp(0.0, height);

              return Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF8FBFF),
                            Color(0xFFF5FAFF),
                            Color(0xFFFDFDFD),
                            Colors.white,
                          ],
                          stops: [0, 0.42, 0.78, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: heroBottom,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/bg2.jpg'),
                          fit: BoxFit.cover,
                          alignment: Alignment(0, -1.0),
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xCCFFFFFF),
                              Color(0x99FFFFFF),
                              Color(0x33FFFFFF),
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x33FFFFFF),
                              Color(0x99FFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.08, 0.15, 0.25, 0.65, 0.82, 0.94, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: safeTop + (isShort ? 8 : 18),
                    left: 24,
                    right: 24,
                    child: _Header(isShort: isShort),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: 16,
                    right: 16,
                    bottom: cardBottom,
                    height: cardHeight,
                    child: _LoginCard(
                      isShort: isShort,
                      isVeryShort: isVeryShort,
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: isLoading,
                      onTogglePassword: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      onSubmit: _submit,
                      onGoogle: _openGoogleSso,
                    ),
                  ),
                  if (!keyboardVisible)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: safeBottom + 8,
                      child: Text(
                        'Versi Mobile 1.0.0',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  SizedBox.expand(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isShort});

  final bool isShort;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logoSize = isShort ? 72.0 : 92.0;

    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(height: isShort ? 4 : 8),
        Text(
          '1Komando',
          style: textTheme.displaySmall?.copyWith(
            color: _LoginScreenState._navy,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Serikat Pekerja PLN Indonesia Power Services',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: _LoginScreenState._navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.isShort,
    required this.isVeryShort,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoogle,
  });

  final bool isShort;
  final bool isVeryShort;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    final padding = isShort ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF103061).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LoginField(
              controller: emailController,
              isShort: isShort,
              hintText: 'Masukkan email Anda',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email wajib diisi';
                }
                return null;
              },
            ),
            SizedBox(height: isShort ? 10 : 14),
            _LoginField(
              controller: passwordController,
              isShort: isShort,
              hintText: 'Masukkan password Anda',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
              suffixIcon: IconButton(
                tooltip: obscurePassword
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF46659D),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password wajib diisi';
                }
                return null;
              },
            ),
            SizedBox(height: isShort ? 14 : 18),
            SizedBox(
              height: isShort ? 46 : 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: _LoginScreenState._navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ),
            if (!isVeryShort) ...[
              SizedBox(height: isShort ? 10 : 14),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFB8C7E2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Atau lanjutkan dengan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64779F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFB8C7E2))),
                ],
              ),
            ],
            SizedBox(height: isShort ? 8 : 12),
            SizedBox(
              height: isShort ? 44 : 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : onGoogle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _LoginScreenState._navy,
                  side: const BorderSide(color: Color(0xFFE0E7F3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleGlyph(),
                    const SizedBox(width: 10),
                    Text(
                      'Masuk dengan Google',
                      style: TextStyle(
                        fontSize: isShort ? 14 : 16,
                        fontWeight: FontWeight.w800,
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

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.isShort,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final bool isShort;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconSize = isShort ? 25.0 : 30.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: isShort ? 38 : 44,
          child: Icon(icon, color: _LoginScreenState._navy, size: iconSize),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: isShort ? 46 : 54,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              validator: validator,
              onFieldSubmitted: onFieldSubmitted,
              style: textTheme.bodyMedium?.copyWith(
                color: _LoginScreenState._navy,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF93A5C8),
                  fontSize: isShort ? 13 : 15,
                ),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isShort ? 12 : 15,
                ),
                border: _fieldBorder(),
                enabledBorder: _fieldBorder(),
                focusedBorder: _fieldBorder(
                  color: _LoginScreenState._navy,
                  width: 1.4,
                ),
                errorBorder: _fieldBorder(color: const Color(0xFFB42318)),
                focusedErrorBorder: _fieldBorder(
                  color: const Color(0xFFB42318),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder({
    Color color = _LoginScreenState._fieldBorder,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/google_logo.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}
