import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _actorTypes = ['Child', 'Adult', 'Senior', 'Pet'];

class _ActorEntry {
  _ActorEntry()
    : nameController = TextEditingController(),
      type = _actorTypes.first;

  final TextEditingController nameController;
  String type;
}

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
  final List<_ActorEntry> _actors = [_ActorEntry()];

  Future<void> _joinFamily() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'join-family-search',
        body: {'query': query},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _createFamily() async {
    final name = _familyNameController.text.trim();
    if (name.isEmpty) return;
    final role = _roleController.text.trim();
    final actorPayload =
        _actors
            .map((a) => {'name': a.nameController.text.trim(), 'type': a.type})
            .where((a) => a['name']!.isNotEmpty)
            .toList();
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-family',
        body: {'family_name': name, 'role': role, 'actors': actorPayload},
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Family created')));
          await Future.delayed(
            const Duration(milliseconds: 800),
          ); // optional pause for UX
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: ${response.data}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Guest';
    return Scaffold(
      appBar: AppBar(title: Text('Family Setup - $userName')),
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
              Column(
                children: [
                  ..._actors.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value.nameController,
                              decoration: const InputDecoration(
                                labelText: 'Actor name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: entry.value.type,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => entry.value.type = val);
                            },
                            items:
                                _actorTypes
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                          ),
                          if (_actors.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () {
                                setState(() => _actors.removeAt(entry.key));
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          () => setState(() => _actors.add(_ActorEntry())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Actor'),
                    ),
                  ),
                ],
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
