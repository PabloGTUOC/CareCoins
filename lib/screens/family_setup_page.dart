import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _actorTypes = ['child', 'elderly', 'pet'];
const _actorTypeLabels = {'child': 'Child', 'elderly': 'Elderly', 'pet': 'Pet'};

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
  final TextEditingController _pinController = TextEditingController();
  final List<_ActorEntry> _actors = [_ActorEntry()];

  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchFamilies() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'join-family-search',
        body: {'query': query},
      );
      if (response.status == 200 && response.data != null) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(
            response.data['families'] ?? [],
          );
        });
      } else {
        setState(() => _searchResults = []);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed')));
      }
    } catch (e) {
      setState(() => _searchResults = []);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showPinDialog(String familyId, String familyName) async {
    final pinController = TextEditingController();
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Join "$familyName"'),
            content: TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final enteredPin = pinController.text.trim();
                  if (enteredPin.length != 4 ||
                      int.tryParse(enteredPin) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid PIN format')),
                    );
                    return;
                  }

                  try {
                    final response = await Supabase.instance.client.functions
                        .invoke(
                          'join-pin',
                          body: {'family_id': familyId, 'pin': enteredPin},
                        );

                    if (response.status == 200 && mounted) {
                      Navigator.of(context).pop(); // ❗ Close dialog first
                      await Future.delayed(
                        const Duration(milliseconds: 100),
                      ); // optional delay for smoother UX
                      Navigator.pushReplacementNamed(context, '/home');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully joined family'),
                        ),
                      );
                      await Future.delayed(const Duration(milliseconds: 800));
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Incorrect PIN')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Join'),
              ),
            ],
          ),
    );
  }

  Future<void> _createFamily() async {
    final name = _familyNameController.text.trim();
    final role = _roleController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || pin.length != 4 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 4-digit PIN')),
      );
      return;
    }

    final actorPayload =
        _actors
            .map((a) => {'name': a.nameController.text.trim(), 'type': a.type})
            .where((a) => a['name']!.isNotEmpty)
            .toList();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-family',
        body: {
          'family_name': name,
          'role': role,
          'pin': pin,
          'actors': actorPayload,
        },
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Family created')));
          await Future.delayed(const Duration(milliseconds: 800));
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
                onPressed: _searchFamilies,
                child: const Text('Search'),
              ),
              const SizedBox(height: 16),
              if (_searchResults.isNotEmpty)
                ..._searchResults.map(
                  (f) => ListTile(
                    title: Text(f['name'] ?? 'Unnamed'),
                    subtitle: Text('ID: ${f['id']}'),
                    trailing: TextButton(
                      onPressed: () => _showPinDialog(f['id'], f['name']),
                      child: const Text('Join'),
                    ),
                  ),
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
                                        child: Text(_actorTypeLabels[t]!),
                                      ),
                                    )
                                    .toList(),
                          ),
                          if (_actors.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed:
                                  () => setState(
                                    () => _actors.removeAt(entry.key),
                                  ),
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
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: '4-digit PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
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
