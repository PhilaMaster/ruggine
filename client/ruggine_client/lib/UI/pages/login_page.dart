import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/message_service.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await auth.login(
                  _emailController.text,
                  _passwordController.text,
                )
                //     .then((err) {
                //   if (err == null) {
                //     MessageService.show("Login successful");
                //     Navigator.pushReplacementNamed(context, '/');
                //   } else {
                //     MessageService.show(err);
                //   }
                // })
                ;
              },
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
