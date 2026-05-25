import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const OshiTabiMapApp());
}

class OshiTabiMapApp extends StatelessWidget {
  const OshiTabiMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '推し旅マップ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    EventPage(),
    GoodsPage(),
    ExpensePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'イベント',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag),
            label: 'グッズ',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: '費用',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '推し旅マップ',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final data = await DatabaseHelper.instance.getEvents();

    setState(() {
      events = data;
    });
  }

  Future<void> addEvent(Map<String, dynamic> event) async {
    await DatabaseHelper.instance.insertEvent(event);
    await loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント'),
      ),
      body: events.isEmpty
          ? const Center(
              child: Text('まだイベントが登録されていません'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(
                      event['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${event['date']} / ${event['venue']}',
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventAddPage(),
            ),
          );

          if (result != null) {
            await addEvent(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GoodsPage extends StatelessWidget {
  const GoodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('グッズ'),
    );
  }
}

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('費用'),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('設定'),
    );
  }
}

class EventAddPage extends StatefulWidget {
  const EventAddPage({super.key});

  @override
  State<EventAddPage> createState() => _EventAddPageState();
}

class _EventAddPageState extends State<EventAddPage> {
  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final venueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント追加'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'イベント名',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: '日付',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: venueController,
              decoration: const InputDecoration(
                labelText: '会場',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    {
                      'title': titleController.text,
                      'date': dateController.text,
                      'venue': venueController.text,
                    },
                  );
                },
                child: const Text('登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}