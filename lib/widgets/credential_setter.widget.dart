import 'package:flutter/material.dart';
import 'package:manga_tracker/services/credentials.service.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:provider/provider.dart';

class CredentialSetter extends StatefulWidget {
  final String id;
  final String name;

  const CredentialSetter({super.key, required this.id, required this.name});

  @override
  State<CredentialSetter> createState() => _CredentialSetterState();
}

class _CredentialSetterState extends State<CredentialSetter> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final credential = context.read<CredentialsStore>().get(widget.id);
    if (credential != null) {
      _loginController.text = credential.login;
      _passwordController.text = credential.password;
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    await context.read<CredentialsStore>().set(
      widget.id,
      Credential(
        login: _loginController.text,
        password: _passwordController.text,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Az adatok sikeresen el lettek mentve!')),
    );
  }

  Future<void> _handleDelete() async {
    await context.read<CredentialsStore>().delete(widget.id);
    if (!mounted) return;
    setState(() {
      _loginController.clear();
      _passwordController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Az adatok sikeresen törölve lettek!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              color: AppColors.font,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInput(
            controller: _loginController,
            hint: 'Email / Felhasználónév',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          _buildInput(
            controller: _passwordController,
            hint: 'Jelszó',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  label: 'Mentés',
                  color: AppColors.primary,
                  onTap: _handleSave,
                ),
              ),
              const SizedBox(width: 8),
              _buildButton(
                label: 'Törlés',
                color: const Color(0xFFDC2626),
                onTap: _handleDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: AppColors.font, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.fontMuted),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
