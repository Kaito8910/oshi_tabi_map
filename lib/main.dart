import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const OshiTabiMapApp());
}

class OshiTabiMapApp extends StatefulWidget {
  const OshiTabiMapApp({super.key});

  @override
  State<OshiTabiMapApp> createState() => _OshiTabiMapAppState();
}

class _OshiTabiMapAppState extends State<OshiTabiMapApp> {
  bool darkMode = false;

  void updateDarkMode(bool value) {
    setState(() {
      darkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '推し旅マップ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      home: MainScreen(
        darkMode: darkMode,
        onDarkModeChanged: updateDarkMode,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const MainScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  bool hidePriceOnStartup = false;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const EventPage(),
      GoodsPage(
        hidePriceOnStartup: hidePriceOnStartup,
      ),
      ExpensePage(
        hidePriceOnStartup: hidePriceOnStartup,
      ),
      SettingsPage(
        hidePriceOnStartup: hidePriceOnStartup,
        darkMode: widget.darkMode,
        onHidePriceChanged: (value) {
          setState(() {
            hidePriceOnStartup = value;
          });
        },
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

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
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.event), label: 'イベント'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'グッズ'),
          NavigationDestination(icon: Icon(Icons.attach_money), label: '費用'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int eventCount = 0;
  int goodsQuantity = 0;
  int expenseTotal = 0;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<void> loadSummary() async {
    final events = await DatabaseHelper.instance.getEvents();
    final goods = await DatabaseHelper.instance.getGoods();
    final expenses = await DatabaseHelper.instance.getExpenses();

    final totalGoodsQuantity = goods.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 0),
    );

    final totalExpense = expenses.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int? ?? 0),
    );

    setState(() {
      eventCount = events.length;
      goodsQuantity = totalGoodsQuantity;
      expenseTotal = totalExpense;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('推し旅マップ'),
      ),
      body: RefreshIndicator(
        onRefresh: loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '推し活の記録をまとめよう',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('イベント・グッズ・費用をまとめて管理できます'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'サマリー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _SummaryCard(
                  icon: Icons.event,
                  title: 'イベント',
                  value: '$eventCount件',
                ),
                _SummaryCard(
                  icon: Icons.shopping_bag,
                  title: 'グッズ',
                  value: '$goodsQuantity個',
                ),
                _SummaryCard(
                  icon: Icons.attach_money,
                  title: '費用',
                  value: '¥$expenseTotal',
                ),
                const _SummaryCard(
                  icon: Icons.map,
                  title: '遠征',
                  value: '0都道府県',
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              '次にやること',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Card(
              child: ListTile(
                leading: Icon(Icons.add),
                title: Text('イベントを登録する'),
                subtitle: Text('まずは参加予定・参加済みイベントを追加しよう'),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.shopping_bag),
                title: Text('グッズを登録する'),
                subtitle: Text('CD・Blu-ray・アクスタなどを記録しよう'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
  final bool hidePriceOnStartup;

  const GoodsPage({
    super.key,
    required this.hidePriceOnStartup,
  });

  @override
  State<GoodsPage> createState() => _GoodsPageState();
}

class _GoodsPageState extends State<GoodsPage> {
  bool isPriceVisible = true;
  List<Map<String, dynamic>> goodsList = [];

  @override
  void initState() {
    super.initState();
    isPriceVisible = !widget.hidePriceOnStartup;
    loadGoods();
  }

  Future<void> loadGoods() async {
    final data = await DatabaseHelper.instance.getGoods();

    setState(() {
      goodsList = data;
    });
  }

  Future<void> addGoods(Map<String, dynamic> goods) async {
    await DatabaseHelper.instance.insertGoods(goods);
    await loadGoods();
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity = goodsList.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 0),
    );

    final totalPrice = goodsList.fold<int>(
      0,
      (sum, item) => sum + (item['price'] as int? ?? 0),
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.amber.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '総グッズ数: $totalQuantity',
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
                            goods['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${goods['group_name']} / ${goods['member_name']}\n'
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GoodsAddPage(),
            ),
          );

          if (result != null) {
            await addGoods(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ExpensePage extends StatefulWidget {
  final bool hidePriceOnStartup;

  const ExpensePage({
    super.key,
    required this.hidePriceOnStartup,
  });

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  bool isAmountVisible = true;

  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    isAmountVisible = !widget.hidePriceOnStartup;
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final data = await DatabaseHelper.instance.getExpenses();

    setState(() {
      expenses = data;
    });
  }

  Future<void> addExpense(Map<String, dynamic> expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
    await loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = expenses.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int? ?? 0),
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.amber.shade100,
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
                            expense['category'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${expense['event_name'] ?? 'イベント未設定'}\n${expense['memo'] ?? ''}',
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
            await addExpense(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
class SettingsPage extends StatelessWidget {
  final bool hidePriceOnStartup;
  final bool darkMode;
  final ValueChanged<bool> onHidePriceChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsPage({
    super.key,
    required this.hidePriceOnStartup,
    required this.darkMode,
    required this.onHidePriceChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '表示設定',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('起動時に総金額を非表示'),
            subtitle: const Text('グッズ・費用の金額を隠します'),
            value: hidePriceOnStartup,
            onChanged: onHidePriceChanged,
          ),
          SwitchListTile(
            title: const Text('ダークモード'),
            subtitle: const Text('画面を暗いテーマにします'),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'データ管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('バックアップ'),
            subtitle: const Text('今後実装予定'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('データ復元'),
            subtitle: const Text('今後実装予定'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('データ初期化'),
            subtitle: const Text('すべてのデータを削除'),
            onTap: () {},
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('推し旅マップ'),
            subtitle: Text('Version 0.1.0'),
          ),
        ],
      ),
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
                      'event_id': null,
                      'group_name': groupController.text,
                      'member_name': memberController.text,
                      'category': selectedCategory,
                      'name': nameController.text,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'price': int.tryParse(priceController.text) ?? 0,
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
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.amber.shade50,
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
  final eventController = TextEditingController();

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
            TextField(
              controller: eventController,
              decoration: const InputDecoration(
                labelText: '対象イベント',
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
                      'event_id': null,
                      'event_name': eventController.text,
                      'category': selectedCategory,
                      'amount': int.tryParse(amountController.text) ?? 0,
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