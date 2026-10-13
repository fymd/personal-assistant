import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  bool _sendingCode = false;
  bool _loggingIn = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool get _canSendCode =>
      _phoneController.text.trim().length >= 11 && _countdown == 0 && !_sendingCode;

  bool get _canLogin =>
      _phoneController.text.trim().length >= 11 &&
      _codeController.text.trim().length >= 4 &&
      !_loggingIn;

  Future<void> _onSendCode() async {
    final phone = _phoneController.text.trim();
    if (!_canSendCode) return;

    setState(() => _sendingCode = true);
    try {
      await ref.read(authStateProvider.notifier).sendCode(phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('验证码已发送（开发环境固定为 123456）'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCountdown();
      _codeFocus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发送失败：$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _onLogin() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (!_canLogin) return;

    setState(() => _loggingIn = true);
    try {
      await ref.read(authStateProvider.notifier).login(phone, code);
      // 登录成功后由上层根据 authState 跳转，此处无需额外处理
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('登录失败：$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 72),

              // 标题
              Text(
                '登录',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '使用手机号登录你的账号',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),

              const SizedBox(height: 48),

              // 手机号
              _InputField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                colors: colors,
                hint: '手机号',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 14),

              // 验证码 + 获取按钮
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      controller: _codeController,
                      focusNode: _codeFocus,
                      colors: colors,
                      hint: '验证码',
                      icon: Icons.shield_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _onLogin(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: _canSendCode ? _onSendCode : null,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        disabledForegroundColor: colors.secondaryText,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _sendingCode
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            )
                          : Text(
                              _countdown > 0 ? '${_countdown}s' : '获取验证码',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 登录按钮
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canLogin ? _onLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor: colors.primary.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loggingIn
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 开发提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border.withOpacity(0.5)),
                ),
                child: Text(
                  '开发环境：验证码固定为 123456\n后端地址：http://10.0.2.2:8080（Android 模拟器）',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AppColors colors;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 16,
        color: colors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: colors.secondaryText),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
