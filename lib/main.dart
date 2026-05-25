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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(
                            event: event,
                          ),
                        ),
                      );
                    },
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

class GoodsPage extends StatefulWidget {
  const GoodsPage({super.key});

  @override
  State<GoodsPage> createState() => _GoodsPageState();
}

class _GoodsPageState extends State<GoodsPage> {
  bool isPriceVisible = true;
  final List<Map<String, String>> goodsList = [
    {
      'group': 'DIALOGUE+',
      'member': '内山悠里菜',
      'category': 'アクスタ',
      'name': 'ライブグッズ アクスタ',
      'quantity': '2',
      'price': '3000',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalPrice = goodsList.fold<int>(
      0,
      (sum, item) => sum + int.parse(item['price']!),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('グッズ'),
      ),
      body: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.pink.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '総グッズ数: ${goodsList.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    isPriceVisible
                        ? '総金額: ¥$totalPrice'
                        : '総金額: ******',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        isPriceVisible = !isPriceVisible;
                      });
                    },
                    icon: Icon(
                      isPriceVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: goodsList.isEmpty
          ? const Center(
              child: Text('まだグッズが登録されていません'),
            )
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goodsList.length,
              itemBuilder: (context, index) {
                final goods = goodsList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(
                      goods['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${goods['group']} / ${goods['member']}\n'
                      '${goods['category']} / ${goods['quantity']}個 / ${goods['price']}円',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );    
  }
}

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  bool isAmountVisible = true;

  final List<Map<String, String>> expenses = [
    {
      'event': 'DIALOGUE+ FCイベント',
      'category': 'チケット代',
      'amount': '7700',
      'memo': '先行チケット',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalAmount = expenses.fold<int>(
      0,
      (sum, item) => sum + int.parse(item['amount']!),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('費用'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.pink.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAmountVisible
                        ? '合計金額: ¥$totalAmount'
                        : '合計金額: ******',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isAmountVisible = !isAmountVisible;
                    });
                  },
                  icon: Icon(
                    isAmountVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(
                    child: Text('まだ費用が登録されていません'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text(
                            expense['category']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${expense['event']}\n${expense['memo']}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            isAmountVisible
                                ? '¥${expense['amount']}'
                                : '******',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseAddPage(),
            ),
          );

          if (result != null) {
            setState(() {
              expenses.add(result);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
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

class GoodsAddPage extends StatefulWidget {
  const GoodsAddPage({super.key});

  @override
  State<GoodsAddPage> createState() => _GoodsAddPageState();
}

class _GoodsAddPageState extends State<GoodsAddPage> {
  final groupController = TextEditingController();
  final memberController = TextEditingController();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();

  String selectedCategory = 'CD';

  final List<String> categories = const [
    'CD',
    'Blu-ray',
    'DVD',
    'アクスタ',
    '缶バッジ',
    '写真',
    'タオル',
    'Tシャツ',
    'その他',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グッズ追加'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memberController,
              decoration: const InputDecoration(
                labelText: 'メンバー名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '商品名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '個数・枚数',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額',
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
                      'group': groupController.text,
                      'member': memberController.text,
                      'category': selectedCategory,
                      'name': nameController.text,
                      'quantity': quantityController.text,
                      'price': priceController.text,
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

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント詳細'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              event['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              event['date'],
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 8),

            Text(
              event['venue'],
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '費用合計: ¥0',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text('交通費: ¥0'),
                  Text('宿泊費: ¥0'),
                  Text('チケット代: ¥0'),
                  Text('グッズ代: ¥0'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'このイベントで購入したグッズ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: const [
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.shopping_bag),
                      title: Text('ライブグッズ アクスタ'),
                      subtitle: Text('2個 / 3000円'),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: Icon(Icons.shopping_bag),
                      title: Text('缶バッジ'),
                      subtitle: Text('5個 / 2500円'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseAddPage extends StatefulWidget {
  const ExpenseAddPage({super.key});

  @override
  State<ExpenseAddPage> createState() => _ExpenseAddPageState();
}

class _ExpenseAddPageState extends State<ExpenseAddPage> {
  final amountController = TextEditingController();
  final memoController = TextEditingController();

  String selectedCategory = 'チケット代';

  final List<String> categories = const [
    'チケット代',
    '交通費',
    '宿泊費',
    'グッズ代',
    '飲食代',
    'その他',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('費用追加'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'メモ',
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
                      'category': selectedCategory,
                      'amount': amountController.text,
                      'memo': memoController.text,
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