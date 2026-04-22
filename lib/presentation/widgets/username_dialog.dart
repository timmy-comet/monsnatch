import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/user/user_bloc.dart';

class UsernameDialog extends StatefulWidget {
  const UsernameDialog({super.key});

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() => _error = "Please enter a name");
      return;
    }

    if (name.length < 2) {
      setState(() => _error = "Name too short");
      return;
    }

    context.read<UserBloc>().createGuest(name);

    Navigator.of(context).pop(); // close dialog
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Enter your name",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: "Your name",
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          const Text(
            "This will be your display name",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submit,
          child: const Text("Continue"),
        ),
      ],
    );
  }
}