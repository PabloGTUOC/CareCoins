import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Activity {
  Activity({required this.title, required this.date});
  final String title;
  final DateTime date;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _balance = 0;
  DateTime _selectedDay = DateTime.now();
  final Map<DateTime, List<Activity>> _events = {};
  final List<Map<String, dynamic>> _family = [];
  final List<Map<String, dynamic>> _actors = [];
  String? _familyName;
  int? _coinsStartMonth;
  int? _coinsPaid;
  int? _coinsPending;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile =
        await Supabase.instance.client
            .from('users')
            .select('coin_balance, family_id')
            .eq('id', user.id)
            .maybeSingle();

    if (profile != null) {
      final balance = profile['coin_balance'] ?? 0;
      final familyId = profile['family_id'];

      if (familyId != null) {
        final members = await Supabase.instance.client
            .from('users')
            .select('id, email, coin_balance')
            .eq('family_id', familyId)
            .order('coin_balance', ascending: false);

        final activities = await Supabase.instance.client
            .from('activities')
            .select('title, scheduled_at')
            .eq('family_id', familyId);

        final familyInfo =
            await Supabase.instance.client
                .from('families')
                .select('name, coins_start_month, coins_paid, coins_pending')
                .eq('id', familyId)
                .maybeSingle();

        final actorList = await Supabase.instance.client
            .from('actors')
            .select('id, name, type')
            .eq('family_id', familyId);

        final Map<DateTime, List<Activity>> mapped = {};
        for (final a in activities) {
          final when = DateTime.parse(a['scheduled_at']).toLocal();
          final day = DateTime(when.year, when.month, when.day);
          mapped
              .putIfAbsent(day, () => [])
              .add(Activity(title: a['title'], date: when));
        }

        setState(() {
          _balance = balance;
          _familyName = familyInfo?['name'];
          _coinsStartMonth = familyInfo?['coins_start_month'];
          _coinsPaid = familyInfo?['coins_paid'];
          _coinsPending = familyInfo?['coins_pending'];
          _family.clear();
          _family.addAll(List<Map<String, dynamic>>.from(members));
          _actors.clear();
          _actors.addAll(List<Map<String, dynamic>>.from(actorList));
          _events.clear();
          _events.addAll(mapped);
        });
      }
    }
  }

  List<DateTime> _getNext7Days() {
    final today = DateTime.now();
    return List.generate(7, (index) => today.add(Duration(days: index)));
  }

  List<Activity> _getActivitiesForHour(DateTime hour) {
    return _events[DateTime(hour.year, hour.month, hour.day)]
            ?.where((a) => a.date.hour == hour.hour)
            .toList() ??
        [];
  }

  Future<void> _logout(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final lastLogin =
          await Supabase.instance.client
              .from('login_history')
              .select()
              .eq('user_id', user.id)
              .filter('logout_time', 'is', null)
              .order('login_time', ascending: false)
              .limit(1)
              .maybeSingle();

      if (lastLogin != null) {
        final logoutTime = DateTime.now().toUtc();
        final loginTime = DateTime.parse(lastLogin['login_time']);
        final duration = logoutTime.difference(loginTime);

        await Supabase.instance.client
            .from('login_history')
            .update({
              'logout_time': logoutTime.toIso8601String(),
              'duration': duration.toString(),
            })
            .eq('id', lastLogin['id']);
      }
    }

    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> showCreateActivityDialog() async {
    final titleController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String type = 'Caring of';
    String? selectedActor;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Create New Activity'),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() => startTime = picked);
                                }
                              },
                              child: Text(
                                startTime != null
                                    ? 'Start: ${startTime!.format(context)}'
                                    : 'Select Start Time',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() => endTime = picked);
                                }
                              },
                              child: Text(
                                endTime != null
                                    ? 'End: ${endTime!.format(context)}'
                                    : 'Select End Time',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Activity Type',
                        ),
                        items:
                            ['Free time', 'House Chores', 'Caring of']
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => type = val);
                        },
                      ),
                      if (type == 'Caring of')
                        DropdownButtonFormField<String>(
                          value: selectedActor,
                          decoration: const InputDecoration(
                            labelText: 'Caring For',
                          ),
                          items:
                              _actors.map<DropdownMenuItem<String>>((actor) {
                                final actorId =
                                    actor['id']
                                        ?.toString(); // ensure String type
                                final actorName = actor['name'] ?? 'Unnamed';
                                return DropdownMenuItem<String>(
                                  value: actorId,
                                  child: Text(actorName),
                                );
                              }).toList(),
                          onChanged:
                              (val) => setState(() => selectedActor = val),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty ||
                          startTime == null ||
                          endTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fill all required fields'),
                          ),
                        );
                        return;
                      }

                      final start = DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        startTime!.hour,
                        startTime!.minute,
                      );

                      final end = DateTime(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                        endTime!.hour,
                        endTime!.minute,
                      );

                      if (end.isBefore(start)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End time must be after start time'),
                          ),
                        );
                        return;
                      }

                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) return;

                      final profile =
                          await Supabase.instance.client
                              .from('users')
                              .select('family_id')
                              .eq('id', user.id)
                              .maybeSingle();

                      final familyId = profile?['family_id'];
                      if (familyId == null) return;

                      final activityPayload = {
                        'title': title,
                        'type': type,
                        'actor': type == 'Caring of' ? selectedActor : null,
                        'scheduled_at': start.toIso8601String(),
                        'ends_at': end.toIso8601String(),
                        'user_id': user.id,
                        'family_id': familyId,
                      };

                      final response = await Supabase.instance.client.functions
                          .invoke('create-activity', body: activityPayload);

                      if (response.status == 200) {
                        Navigator.pop(context);
                        await _loadDashboardData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to create activity: ${response.data}',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Guest';

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(child: Text('Menu')),
            ListTile(title: Text('Home')),
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text('CareCoins Dashboard'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (_familyName != null)
              Text(
                'Family: $_familyName',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
            const SizedBox(height: 16),
            Text(
              'Balance: $_balance CareCoins',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_coinsStartMonth != null) ...[
              const SizedBox(height: 16),
              Text(
                'Family Coin Status',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Total This Month: $_coinsStartMonth CC',
                textAlign: TextAlign.center,
              ),
              Text('Paid: $_coinsPaid CC', textAlign: TextAlign.center),
              Text('Pending: $_coinsPending CC', textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],

            // Day Picker (Next 7 Days)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _getNext7Days().map((day) {
                      final isSelected =
                          day.day == _selectedDay.day &&
                          day.month == _selectedDay.month &&
                          day.year == _selectedDay.year;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          label: Text(DateFormat('E dd').format(day)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedDay = day),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Hourly Breakdown
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 24,
              itemBuilder: (context, index) {
                final hour = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                  index,
                );
                final hourLabel = DateFormat('HH:00').format(hour);
                final activities = _getActivitiesForHour(hour);

                return ListTile(
                  leading: Text(hourLabel),
                  title:
                      activities.isEmpty
                          ? const Text('No activity')
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                activities.map((a) => Text(a.title)).toList(),
                          ),
                );
              },
            ),

            const SizedBox(height: 24),
            if (_actors.isNotEmpty) ...[
              Text(
                'Family Actors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._actors.map(
                (a) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(a['name'] ?? ''),
                  subtitle: Text(a['type'] ?? ''),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Family Members',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._family
                .where((m) => m['id'] != user?.id)
                .map(
                  (m) => ListTile(
                    title: Text(m['email'] ?? ''),
                    trailing: Text('${m['coin_balance'] ?? 0} CC'),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateActivityDialog,
        tooltip: 'New Activity',
        child: const Icon(Icons.add),
      ),
    );
  }
}
