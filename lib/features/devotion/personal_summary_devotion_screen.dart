import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firebase/ramakoti_service.dart';

class PersonalSummaryScreen extends StatefulWidget {
  const PersonalSummaryScreen({super.key});

  @override
  State<PersonalSummaryScreen> createState() => _PersonalSummaryScreenState();
}

class _PersonalSummaryScreenState extends State<PersonalSummaryScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softBorder = Color(0xFFEADFD2);

  static const List<int> _manualWritingOptions = [11, 27, 54, 108, 216, 504, 1008];
  static const List<int> _japaOptions = [108, 216, 324, 504, 1008];
  static const List<int> _additionalOptions = [11, 27, 54, 108, 216, 504, 1008];

  int _selectedManualWriting = 0;
  int _selectedJapa = 0;
  int _selectedAdditional = 0;

  bool _consentChecked = false;
  bool _isSaving = false;

  int get _totalSelected =>
      _selectedManualWriting + _selectedJapa + _selectedAdditional;

  Future<void> _save() async {
    if (_totalSelected <= 0) {
      _showSnackBar('Please select at least one devotional entry.');
      return;
    }

    if (!_consentChecked) {
      _showSnackBar('Please confirm your devotional entries before saving.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnackBar('No authenticated user found.');
      return;
    }

    try {
      setState(() => _isSaving = true);

      await RamakotiService.instance.addPersonalDevotion(
        uid: uid,
        manualWritingIncrement: _selectedManualWriting,
        japaIncrement: _selectedJapa,
        additionalDevotionIncrement: _selectedAdditional,
        consentConfirmed: _consentChecked,
      );

      if (!mounted) return;

      setState(() {
        _selectedManualWriting = 0;
        _selectedJapa = 0;
        _selectedAdditional = 0;
        _consentChecked = false;
      });

      _showSnackBar('Personal devotion saved successfully.');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildOptionChips({
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((value) {
        final selected = selectedValue == value;

        return ChoiceChip(
          label: Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _textPrimary,
            ),
          ),
          selected: selected,
          onSelected: (_) {
            onSelected(selected ? 0 : value);
          },
          selectedColor: _accent,
          backgroundColor: _softAccent,
          side: BorderSide(
            color: selected ? _accent : _softBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _softBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildOptionChips(
            options: options,
            selectedValue: selectedValue,
            onSelected: onSelected,
          ),
          if (selectedValue > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Selected: $selectedValue',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Personal Devotion Summary',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Manual Writing',
                subtitle:
                'Sri Rama Nama written outside the app, such as in books or notebooks.',
                options: _manualWritingOptions,
                selectedValue: _selectedManualWriting,
                onSelected: (value) {
                  setState(() => _selectedManualWriting = value);
                },
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Japa',
                subtitle: 'Japa count offered personally outside the app.',
                options: _japaOptions,
                selectedValue: _selectedJapa,
                onSelected: (value) {
                  setState(() => _selectedJapa = value);
                },
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Additional Devotion',
                subtitle:
                'Includes japa performed using mechanical or digital counters and other personal devotional practices outside the app.',
                options: _additionalOptions,
                selectedValue: _selectedAdditional,
                onSelected: (value) {
                  setState(() => _selectedAdditional = value);
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _softAccent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _softBorder),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Total Devotion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _totalSelected.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _softBorder),
                ),
                child: CheckboxListTile(
                  value: _consentChecked,
                  onChanged: (value) {
                    setState(() {
                      _consentChecked = value ?? false;
                    });
                  },
                  activeColor: _accent,
                  title: const Text(
                    'I confirm that these counts are my personal devotional entries and are entered truthfully.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'These entries affect Personal Devotion Summary and Global Devotion Count only. They do not affect writer progress, certificates, or mandali writing totals.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Save Devotion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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