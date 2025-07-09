import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilySetupPage extends StatefulWidget {
  const FamilySetupPage({super.key});

  @override
  State<FamilySetupPage> createState() => _FamilySetupPageState();
}

class _FamilySetupPageState extends State<FamilySetupPage> {
  bool _createMode = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _actorsController = TextEditingController();

  Future<void> _joinFamily() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'join-family-search',
        body: {'query': query},
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _createFamily() async {
    final name = _familyNameController.text.trim();
    if (name.isEmpty) return;
    final role = _roleController.text.trim();
    final actors = _actorsController.text.trim();
    try {
      await Supabase.instance.client.functions.invoke(
        'create-family',
        body: {
          'family_name': name,
          'role': role,
          'actors': actors.split(',').map((e) => e.trim()).toList(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Family created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _familyNameController.dispose();
    _roleController.dispose();
    _actorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Join Existing'),
                  selected: !_createMode,
                  onSelected: (_) => setState(() => _createMode = false),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Create New'),
                  selected: _createMode,
                  onSelected: (_) => setState(() => _createMode = true),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_createMode) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search families',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _joinFamily,
                child: const Text('Search'),
              ),
            ] else ...[
              TextField(
                controller: _familyNameController,
                decoration: const InputDecoration(
                  labelText: 'Family name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Your role',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _actorsController,
                decoration: const InputDecoration(
                  labelText: 'Actors cared for (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createFamily,
                child: const Text('Create Family'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
