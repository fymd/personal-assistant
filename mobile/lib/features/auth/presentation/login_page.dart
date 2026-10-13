import 'package:flutter/material.dart';

/// 登录页占位
/// 后续实现：手机号输入 + 验证码发送/校验
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: const Center(
        child: Text('手机号 + 验证码登录（待实现）'),
      ),
    );
  }
}
