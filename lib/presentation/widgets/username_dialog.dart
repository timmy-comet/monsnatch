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

  void _submit(BuildContext context) {
    if (context.read<UserBloc>().state is UserLoading) return;

    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "Please enter a name");
      return;
    }
    if (name.length < 2) {
      setState(() => _error = "Name too short");
      return;
    }

    setState(() => _error = null);
    context.read<UserBloc>().createGuest(name);
    // No pop here — the BlocListener below pops on UserLoaded and surfaces
    // server errors inline so the dialog stays open until success.
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (ctx, state) {
        if (state is UserLoaded) {
          Navigator.of(ctx).pop();
        } else if (state is UserError) {
          setState(() => _error = state.message);
        }
      },
      builder: (ctx, state) {
        final isSubmitting = state is UserLoading;
        return AlertDialog(
          title: const Text(
            "Enter your name",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller:         _controller,
                autofocus:          true,
                enabled:            !isSubmitting,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText:  "Your name",
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _submit(ctx),
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
              onPressed: isSubmitting ? null : () => _submit(ctx),
              child: isSubmitting
                  ? const SizedBox(
                      width:  16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Continue"),
            ),
          ],
        );
      },
    );
  }
}
