import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/api_constants.dart';
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
        scopes: const ['email', 'profile'],
        serverClientId: ApiConstants.googleServerClientId,
      );
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null || !mounted) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Token Google tidak tersedia. Silakan coba lagi.');
      }

      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthGoogleLoginRequested(
          idToken: idToken,
          serverAuthCode: account.serverAuthCode,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
                          image: AssetImage('assets/background.png'),
                          fit: BoxFit.cover,
                          alignment: Alignment(0, -1.0),
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -0.6),
                            radius: 0.9,
                            focal: Alignment(0, -0.6),
                            focalRadius: 0.1,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xF2FFFFFF),
                              Color(0xE6FFFFFF),
                              Color(0xCCFFFFFF),
                              Color(0x99FFFFFF),
                              Color(0x55FFFFFF),
                              Color(0x22FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [
                              0.0,
                              0.10,
                              0.20,
                              0.35,
                              0.55,
                              0.75,
                              0.90,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: heroBottom - 1,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0x33FFFFFF),
                            const Color(0x88FFFFFF),
                            const Color(0xCCFFFFFF),
                            const Color(0xFFFFFFFF),
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
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
                  if (!keyboardVisible)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: cardBottom + cardHeight - 20,
                      height: height * 0.29,
                      child: IgnorePointer(
                        child: Image.asset(
                          'assets/sp_ppl.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
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
        const SizedBox(height: 6),
        Text(
          'Akses layanan dan informasi serikat pekerja\nkapan saja, dimana saja secara digital',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: _LoginScreenState._navy.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
            height: 1.4,
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
