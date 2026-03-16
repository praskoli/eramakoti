import 'package:flutter/material.dart';

import '../../../features/navigation/main_bottom_nav_screen.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';

class CreateMandaliScreen extends StatefulWidget {
  const CreateMandaliScreen({super.key});

  @override
  State<CreateMandaliScreen> createState() => _CreateMandaliScreenState();
}

class _CreateMandaliScreenState extends State<CreateMandaliScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _accent = Color(0xFFFF9E2C);

  static const List<String> _categories = <String>[
    'Community',
    'Temple',
    'Youth',
    'Town',
    'School',
    'Family',
    'Bhajan Group',
  ];

  static const List<_ChallengeTargetOption> _challengeTargets =
  <_ChallengeTargetOption>[
    _ChallengeTargetOption(label: '10 Ten', value: 10),
    _ChallengeTargetOption(label: '1 Lakh', value: 100000),
    _ChallengeTargetOption(label: '10 Lakh', value: 1000000),
    _ChallengeTargetOption(label: '1 Crore', value: 10000000),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _challengeTitleController = TextEditingController();

  String? _selectedCategory;
  int? _selectedChallengeTarget = 100000;

  bool _isPublic = true;
  bool _saving = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _challengeTitleController.dispose();
    super.dispose();
  }

  String get _displayPreview {
    final base = _nameController.text.trim();
    if (base.isEmpty) return 'Your Bhakta Mandali name will appear here';
    if (base.toLowerCase().endsWith('bhakta mandali')) return base;
    return '$base Bhakta Mandali';
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    final target = _selectedChallengeTarget;
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid challenge target.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await BhaktaMandaliService.instance.createMandali(
        baseName: _nameController.text.trim(),
        category: (_selectedCategory ?? '').trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        challengeTitle: _challengeTitleController.text.trim(),
        challengeTarget: target,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bhakta Mandali created successfully.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainBottomNavScreen(initialIndex: 2),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create Mandali: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Mandali',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _displayPreview,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _nameController,
              label: 'Mandali Name',
              hint: 'Ex: Hyderabad Youth',
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Enter Mandali name';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _dropdownField<String>(
              value: _selectedCategory,
              label: 'Category',
              hint: 'Select category',
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Select category';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _field(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe this Bhakta Mandali',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isPublic,
              activeColor: _accent,
              title: const Text('Public discoverable'),
              subtitle: const Text(
                'Allow devotees to discover this Mandali publicly.',
              ),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 18),
            const Text(
              'Challenge',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _challengeTitleController,
              label: 'Challenge Title',
              hint: 'Ex: Rama Nama Challenge',
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter challenge title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _dropdownField<int>(
              value: _selectedChallengeTarget,
              label: 'Challenge Target',
              hint: 'Select challenge target',
              items: _challengeTargets
                  .map(
                    (option) => DropdownMenuItem<int>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedChallengeTarget = value;
                });
              },
              validator: (value) {
                if (value == null || value <= 0) {
                  return 'Select challenge target';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dateCard(
                    label: 'Start Date',
                    value: _formatDate(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateCard(
                    label: 'End Date',
                    value: _formatDate(_endDate),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saving ? null : _create,
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Create Bhakta Mandali'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required T? value,
    required String label,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      isExpanded: true,
    );
  }

  Widget _dateCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeTargetOption {
  final String label;
  final int value;

  const _ChallengeTargetOption({
    required this.label,
    required this.value,
  });
}