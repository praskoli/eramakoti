import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import 'ramakoti_writer_screen.dart';

class SelectLanguageTargetScreen extends StatefulWidget {
  const SelectLanguageTargetScreen({super.key});

  @override
  State<SelectLanguageTargetScreen> createState() =>
      _SelectLanguageTargetScreenState();
}

class _SelectLanguageTargetScreenState
    extends State<SelectLanguageTargetScreen> {
  static const Color _bgColor = Color(0xFFF6EEDD);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF6F6256);
  static const Color _borderColor = Color(0xFFE4D6C4);

  final List<String> _languages = const [
    'English',
    'Telugu',
    'Hindi',
  ];

  final List<_TargetOption> _targets = const [
    _TargetOption(label: '108 Ten', value: 108),
    _TargetOption(label: '1 Lakh', value: 100000),
    _TargetOption(label: '10 Lakh', value: 1000000),
    _TargetOption(label: '1 Crore', value: 10000000),
  ];

  String _selectedLanguage = 'English';
  int _selectedTarget = 10000000;
  bool _saving = false;

  Future<void> _continue() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await RamakotiService.instance.saveLanguageAndTarget(
        uid: user.uid,
        language: _selectedLanguage,
        targetCount: _selectedTarget,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const RamakotiWriterScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save selection: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Select Language & Target',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  const Text(
                    '🙏 Begin Your Ramakoti Journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose your preferred language and sacred target.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Choose your preferred language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: InputDecoration(
                            labelText: 'Language',
                            labelStyle: const TextStyle(color: _textSecondary),
                            filled: true,
                            fillColor: const Color(0xFFFFFBF6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _borderColor,
                                width: 1.3,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _accent,
                                width: 1.8,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: _languages
                              .map(
                                (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLanguage = value);
                            }
                          },
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Select your Ramakoti target',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          value: _selectedTarget,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: InputDecoration(
                            labelText: 'Target',
                            labelStyle: const TextStyle(color: _textSecondary),
                            filled: true,
                            fillColor: const Color(0xFFFFFBF6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _accent,
                                width: 1.8,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _accent,
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: _targets
                              .map(
                                (item) => DropdownMenuItem(
                              value: item.value,
                              child: Text(item.label),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTarget = value);
                            }
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Start Writing',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetOption {
  final String label;
  final int value;

  const _TargetOption({
    required this.label,
    required this.value,
  });
}