import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<Activity>> _events = {};
  final List<Map<String, dynamic>> _family = [];
  final List<Map<String, dynamic>> _actors = [];
  String? _familyName;

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
            .select('carecoins_balance, family_id')
            .eq('id', user.id)
            .maybeSingle();

    if (profile != null) {
      setState(() {
        _balance = profile['carecoins_balance'] ?? 0;
      });

      final familyId = profile['family_id'];
      if (familyId != null) {
        final members = await Supabase.instance.client
            .from('users')
            .select('id, email, carecoins_balance')
            .eq('family_id', familyId)
            .order('carecoins_balance', ascending: false);

        final activities = await Supabase.instance.client
            .from('activities')
            .select('title, scheduled_at')
            .eq('family_id', familyId);

        final familyInfo = await Supabase.instance.client
            .from('families')
            .select('name')
            .eq('id', familyId)
            .maybeSingle();

        final actorList = await Supabase.instance.client
            .from('actors')
            .select('name, type')
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
          _familyName = familyInfo?['name'] as String?;
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

  List<Activity> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName =
        user?.userMetadata?['full_name'] ?? user?.email ?? 'Guest';
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
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CareCoins Dashboard'),
            if (_familyName != null)
              Text(
                'Family: $_familyName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
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
              'Welcome, $userName!\nBalance: $_balance CareCoins',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TableCalendar<Activity>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
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
                    trailing: Text('${m['carecoins_balance'] ?? 0} CC'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
