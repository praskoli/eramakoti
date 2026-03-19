import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';
import '../widgets/mandali_card.dart';
import 'mandali_detail_screen.dart';

class JoinMandaliScreen extends StatefulWidget {
  const JoinMandaliScreen({super.key});

  @override
  State<JoinMandaliScreen> createState() => _JoinMandaliScreenState();
}

class _JoinMandaliScreenState extends State<JoinMandaliScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _accent = Color(0xFFFF9E2C);

  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  BhaktaMandali? _preview;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findMandali() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 8-character invite code.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _preview = null;
    });

    try {
      final mandali = await BhaktaMandaliService.instance.getMandaliByInviteCode(code);
      if (!mounted) return;

      if (mandali == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mandali not found for this invite code.')),
        );
      }

      setState(() {
        _preview = mandali;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find Mandali: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _join() async {
    final mandali = _preview;
    if (mandali == null) return;

    setState(() => _loading = true);

    try {
      final mandaliId = mandali.mandaliId.trim();
      if (mandaliId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Mandali. Please try again.')),
        );
        return;
      }

      await BhaktaMandaliService.instance.joinMandaliById(mandaliId: mandaliId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${mandali.displayName}')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MandaliDetailScreen(mandaliId: mandaliId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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
        title: const Text(
          'Join with Code',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            onChanged: (_) {
              if (_preview != null) {
                setState(() {
                  _preview = null;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Invite Code',
              hintText: 'Enter 8-character code',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              onPressed: _loading ? null : _findMandali,
              child: _loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Find Mandali'),
            ),
          ),
          const SizedBox(height: 18),
          if (_preview != null)
            Column(
              children: [
                MandaliCard(mandali: _preview!),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _join,
                    child: const Text('Join Now'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
