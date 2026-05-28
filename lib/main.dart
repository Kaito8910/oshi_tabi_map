import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'dart:io';

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
      locale: const Locale('ja'),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('ja'),
      ],
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
  int homeRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        refreshKey: homeRefreshKey,
        onNavigate: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const OshiPage(),
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
        onHidePriceChanged: saveHidePriceSetting,
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

            if (index == 0) {
              homeRefreshKey++;
            }
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.favorite), label: '推し'),
          NavigationDestination(icon: Icon(Icons.event), label: 'イベント'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'グッズ'),
          NavigationDestination(icon: Icon(Icons.attach_money), label: '費用'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      hidePriceOnStartup = prefs.getBool('hidePriceOnStartup') ?? false;
    });
  }

  Future<void> saveHidePriceSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hidePriceOnStartup', value);

    setState(() {
      hidePriceOnStartup = value;
    });
  }
}

class HomePage extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final int refreshKey;

  const HomePage({
    super.key,
    required this.refreshKey,
    required this.onNavigate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int eventCount = 0;
  int goodsQuantity = 0;
  int prefectureCount = 0;
  List<Map<String, dynamic>> recentOshis = [];
  Map<String, dynamic>? nextEvent;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) {
      loadSummary();
    }
  }

  Future<void> loadSummary() async {
    final events = await DatabaseHelper.instance.getEvents();
    final goods = await DatabaseHelper.instance.getGoods();
    final oshis = await DatabaseHelper.instance.getOshis();

    final totalGoodsQuantity = goods.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 0),
    );

    
    oshis.sort((a, b) {
      final aDate = DateTime.tryParse(a['start_date'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['start_date'] ?? '') ?? DateTime.now();

      return aDate.compareTo(bDate);
    });

    final today = DateTime.now();

    final upcomingEvents = events.where((event) {
      final eventDate =
          DateTime.tryParse(event['date']) ?? DateTime(1900);

      return !eventDate.isBefore(
        DateTime(today.year, today.month, today.day),
      );
    }).toList();

    upcomingEvents.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['date']) ?? DateTime.now();

      final bDate =
          DateTime.tryParse(b['date']) ?? DateTime.now();

      return aDate.compareTo(bDate);
    });

    final prefectures = events
      .map((e) => e['prefecture'])
      .where((p) => p != null && p.toString().isNotEmpty)
      .toSet();

    setState(() {
      eventCount = events.length;
      goodsQuantity = totalGoodsQuantity;
      recentOshis = oshis.take(3).toList();

      prefectureCount = prefectures.length;

      nextEvent =
          upcomingEvents.isNotEmpty
              ? upcomingEvents.first
              : null;
    });
    
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String getRemainingDays(String? date) {
      if (date == null) {
        return '予定なし';
      }

      final eventDate = DateTime.tryParse(date);

      if (eventDate == null) {
        return '予定なし';
      }

      final today = DateTime.now();

      final difference =
          eventDate.difference(
            DateTime(today.year, today.month, today.day),
          ).inDays;

      if (difference == 0) {
        return '今日';
      }

      return 'あと$difference日';
    }

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
              childAspectRatio: 0.9,
              children: [
                _SummaryCard(
                  icon: Icons.event,
                  title: '参戦イベント',
                  value: '$eventCount件',
                  onTap: () {
                    widget.onNavigate(2);
                  },
                ),
                _SummaryCard(
                  icon: Icons.shopping_bag,
                  title: 'グッズ',
                  value: '$goodsQuantity個',
                  onTap: () {
                    widget.onNavigate(3);
                  },
                ),
                
                _SummaryCard(
                  icon: Icons.event_available,
                  title: nextEvent != null
                      ? nextEvent!['title']
                      : '次のイベント',
                  value: nextEvent != null
                      ? getRemainingDays(nextEvent!['date'])
                      : '予定なし',
                  onTap: () {
                    widget.onNavigate(2);
                  },
                ),

                _SummaryCard(
                  icon: Icons.map,
                  title: '遠征',
                  value: '$prefectureCount都道府県',
                ),
              ],
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlbumPage(),
                  ),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('アルバムを見る'),
            ),
          ],
        ),
      ),
    );
  }
}

class OshiPage extends StatefulWidget {
  const OshiPage({super.key});

  @override
  State<OshiPage> createState() => _OshiPageState();
}

class _OshiPageState extends State<OshiPage> {
  List<Map<String, dynamic>> oshis = [];

  @override
  void initState() {
    super.initState();
    loadOshis();
  }

  Future<void> loadOshis() async {
    final data = await DatabaseHelper.instance.getOshis();

    setState(() {
      oshis = data;
    });
  }

  Future<void> addOshi(Map<String, dynamic> oshi) async {
    await DatabaseHelper.instance.insertOshi(oshi);
    await loadOshis();
  }

  Future<void> updateOshiItem(
    int id,
    Map<String, dynamic> oshi,
  ) async {
    await DatabaseHelper.instance.updateOshi(id, oshi);
    await loadOshis();
  }

  Future<void> deleteOshiItem(int id) async {
    await DatabaseHelper.instance.deleteOshi(id);
    await loadOshis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推し'),
      ),
      body: oshis.isEmpty
          ? const Center(
              child: Text('まだ推しが登録されていません'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: oshis.length,
              itemBuilder: (context, index) {
                final oshi = oshis[index];
                final color = Color(
                  int.tryParse(oshi['color_value']?.toString() ?? '') ?? 0xFFFF9800,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OshiDetailPage(
                            oshi: oshi,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Text(
                        oshi['name'].toString().isNotEmpty
                            ? oshi['name'].toString()[0]
                            : '?',
                        style: TextStyle(
                          color: color == Colors.black
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      oshi['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${oshi['group_name'] ?? ''}\n${oshi['memo'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OshiAddPage(
                                  oshi: oshi,
                                ),
                              ),
                            );

                            if (result != null) {
                              await updateOshiItem(oshi['id'], result);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await deleteOshiItem(oshi['id']);
                          },
                        ),
                      ],
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
              builder: (context) => const OshiAddPage(),
            ),
          );

          if (result != null) {
            await addOshi(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class OshiAddPage extends StatefulWidget {
  final Map<String, dynamic>? oshi;

  const OshiAddPage({
    super.key,
    this.oshi,
  });

  @override
  State<OshiAddPage> createState() => _OshiAddPageState();
}

class _OshiAddPageState extends State<OshiAddPage> {
  final nameController = TextEditingController();
  final groupController = TextEditingController();
  final memoController = TextEditingController();
  final startDateController = TextEditingController();

  final colorController = TextEditingController();
  Color selectedColor = Colors.orange;

  @override
  void initState() {
    super.initState();

    if (widget.oshi != null) {
      nameController.text = widget.oshi!['name'];
      groupController.text = widget.oshi!['group_name'] ?? '';
      memoController.text = widget.oshi!['memo'] ?? '';
      startDateController.text =
      widget.oshi!['start_date'] ?? formatDate(DateTime.now());
      colorController.text = widget.oshi!['color'] ?? '';
      selectedColor = Color(
        int.tryParse(widget.oshi!['color_value']?.toString() ?? '') ?? 0xFFFF9800,
      );
    } else {
      startDateController.text = formatDate(DateTime.now());
    }
  }

  String formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.oshi == null ? '推し追加' : '推し編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '推し名',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: startDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '推し始めた日',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: () {
                DateTime selectedDate =
                    DateTime.tryParse(startDateController.text) ??
                    DateTime.now();

                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SizedBox(
                      height: 260,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () {
                                  startDateController.text =
                                      formatDate(selectedDate);

                                  Navigator.pop(context);
                                },
                                child: const Text('決定'),
                              ),
                            ],
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              dateOrder: DatePickerDateOrder.ymd,
                              initialDateTime: selectedDate,
                              onDateTimeChanged: (date) {
                                selectedDate = date;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'メンバーカラー名',
                hintText: '例：サーモンピンク、ミントグリーン',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('表示カラー'),
              subtitle: const Text('タップして色を選択'),
              trailing: CircleAvatar(
                backgroundColor: selectedColor,
              ),
              onTap: () async {
                final color = await showColorPickerDialog(
                  context,
                  selectedColor,
                );

                setState(() {
                  selectedColor = color;
                });
              },
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
                      'name': nameController.text,
                      'group_name': groupController.text,
                      'group_name_normalized': normalizeText(groupController.text),
                      'color': colorController.text,
                      'color_value': selectedColor.toARGB32().toString(),
                      'memo': memoController.text,
                      'start_date': startDateController.text,
                    },
                  );
                },
                child: Text(widget.oshi == null ? '登録' : '更新'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OshiDetailPage extends StatefulWidget {
  final Map<String, dynamic> oshi;

  const OshiDetailPage({
    super.key,
    required this.oshi,
  });

  @override
  State<OshiDetailPage> createState() => _OshiDetailPageState();
}

class _OshiDetailPageState extends State<OshiDetailPage> {
  List<Map<String, dynamic>> goodsList = [];

  @override
  void initState() {
    super.initState();
    loadOshiGoods();
  }

  Future<void> loadOshiGoods() async {
    final allGoods = await DatabaseHelper.instance.getGoods();

    final filteredGoods = allGoods.where((goods) {
      return goods['oshi_id'] == widget.oshi['id'] ;
    }).toList();

    setState(() {
      goodsList = filteredGoods;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.tryParse(widget.oshi['color_value']?.toString() ?? '') ?? 0xFFFF9800,
    );

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
        title: Text(widget.oshi['name']),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color,
                  child: Text(
                    widget.oshi['name'].toString().isNotEmpty
                        ? widget.oshi['name'].toString()[0]
                        : '?',
                    style: TextStyle(
                      color: color == Colors.black
                          ? Colors.white
                          : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.oshi['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((widget.oshi['group_name'] ?? '').toString().isNotEmpty)
                        Text(
                          widget.oshi['group_name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      if ((widget.oshi['color'] ?? '').toString().isNotEmpty)
                        Text(
                          'カラー：${widget.oshi['color']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _SummaryCard(
                icon: Icons.shopping_bag,
                title: 'グッズ数',
                value: '$totalQuantity個',
              ),
              _SummaryCard(
                icon: Icons.attach_money,
                title: 'グッズ金額',
                value: '¥$totalPrice',
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            '関連グッズ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (goodsList.isEmpty)
            const Card(
              child: ListTile(
                title: Text('この推しのグッズはまだありません'),
              ),
            )
          else
            ...goodsList.map((goods) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(goods['name']),
                  subtitle: Text(
                    '${goods['category']} / ${goods['quantity']}個 / ${goods['price']}円',
                  ),
                ),
              );
            }),
        ],
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

  Future<void> deleteEventItem(int id) async {
    await DatabaseHelper.instance.deleteEvent(id);
    await loadEvents();
  }

  Future<void> updateEventItem(
    int id,
    Map<String, dynamic> event,
  ) async {
    await DatabaseHelper.instance.updateEvent(id, event);
    await loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    DateTime parseDate(String date) {
      return DateTime.tryParse(date.replaceAll('/', '-')) ?? DateTime(1900);
    }

    final upcomingEvents = events.where((event) {
      final eventDate = parseDate(event['date']);
      return !eventDate.isBefore(
        DateTime(today.year, today.month, today.day),
      );
    }).toList();

    final pastEvents = events.where((event) {
      final eventDate = parseDate(event['date']);
      return eventDate.isBefore(
        DateTime(today.year, today.month, today.day),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント'),
      ),
      body: events.isEmpty
        ? const Center(
            child: Text('まだイベントが登録されていません'),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'これからのイベント',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (upcomingEvents.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('予定されているイベントはありません'),
                  ),
                )
              else
                ...upcomingEvents.map((event) {
                  return EventCard(
                    event: event,
                    onDelete: () async {
                      await deleteEventItem(event['id']);
                    },
                    onEdit: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventAddPage(
                            event: event,
                          ),
                        ),
                      );

                      if (result != null) {
                        await updateEventItem(event['id'], result);
                      }
                    },
                  );
                }),

              const SizedBox(height: 24),

              const Text(
                '過去のイベント',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (pastEvents.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('過去のイベントはありません'),
                  ),
                )
              else
                ...pastEvents.map((event) {
                  return EventCard(
                    event: event,
                    onDelete: () async {
                      await deleteEventItem(event['id']);
                    },
                    onEdit: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventAddPage(
                            event: event,
                          ),
                        ),
                      );

                      if (result != null) {
                        await updateEventItem(event['id'], result);
                      }
                    },
                  );
                }),
            ],
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

  Future<void> deleteGoodsItem(int id) async {
    await DatabaseHelper.instance.deleteGoods(id);
    await loadGoods();
  }

  Future<void> updateGoodsItem(
    int id,
    Map<String, dynamic> goods,
  ) async {
    await DatabaseHelper.instance.updateGoods(id, goods);
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GoodsAddPage(
                                        goods: goods,
                                      ),
                                    ),
                                  );

                                  if (result != null) {
                                    await updateGoodsItem(goods['id'], result);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await deleteGoodsItem(goods['id']);
                                },
                              ),
                            ],
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

  Future<void> deleteExpenseItem(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    await loadExpenses();
  }

  Future<void> updateExpenseItem(
    int id,
    Map<String, dynamic> expense,
  ) async {
    await DatabaseHelper.instance.updateExpense(id, expense);
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAmountVisible
                                    ? '¥${expense['amount']}'
                                    : '******',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExpenseAddPage(
                                        expense: expense,
                                      ),
                                    ),
                                  );

                                  if (result != null) {
                                    await updateExpenseItem(expense['id'], result);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await deleteExpenseItem(expense['id']);
                                },
                              ),
                            ],
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

class SettingsPage extends StatefulWidget {
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
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> backupData() async {
    final data = await DatabaseHelper.instance.exportAllData();

    final tempDir = await getTemporaryDirectory();
    final backupDir = Directory('${tempDir.path}/oshi_tabi_backup');

    if (await backupDir.exists()) {
      await backupDir.delete(recursive: true);
    }

    await backupDir.create(recursive: true);

    final photosDir = Directory('${backupDir.path}/photos');
    await photosDir.create();

    final photos = data['photos'] as List<Map<String, dynamic>>;

    for (final photo in photos) {
      final path = photo['image_path']?.toString();

      if (path == null || path.isEmpty) continue;

      final sourceFile = File(path);

      if (await sourceFile.exists()) {
        final fileName = path.split('/').last;
        await sourceFile.copy('${photosDir.path}/$fileName');
      }
    }

    final jsonFile = File('${backupDir.path}/backup.json');
    await jsonFile.writeAsString(jsonEncode(data));

    final zipPath =
        '/storage/emulated/0/Download/oshi_tabi_backup.zip';

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addFile(jsonFile);
    encoder.addDirectory(photosDir);
    encoder.close();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloadにバックアップを保存しました'),
      ),
    );
  }

  Future<void> resetData() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('データ初期化'),
          content: const Text(
            'すべてのデータを削除します。\nこの操作は元に戻せません。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await DatabaseHelper.instance.clearAllData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('すべてのデータを削除しました'),
      ),
    );
  }

  Future<void> restoreData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('データ復元'),
          content: const Text(
            '現在のデータを削除して、バックアップから復元します。\nよろしいですか？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('復元する'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    const typeGroup = XTypeGroup(
      label: 'zip',
      extensions: ['zip'],
    );

    final result = await openFile(
      acceptedTypeGroups: [typeGroup],
    );

    if (result == null) return;

    final zipFile = File(result.path);

    final tempDir = await getTemporaryDirectory();
    final restoreDir = Directory('${tempDir.path}/oshi_tabi_restore');

    if (await restoreDir.exists()) {
      await restoreDir.delete(recursive: true);
    }

    await restoreDir.create(recursive: true);

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filePath = '${restoreDir.path}/${file.name}';

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    final jsonFile = File('${restoreDir.path}/backup.json');

    if (!await jsonFile.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('backup.jsonが見つかりません'),
        ),
      );
      return;
    }

    final jsonString = await jsonFile.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    await DatabaseHelper.instance.importAllData(data);

    final appDir = await getApplicationDocumentsDirectory();
    final restorePhotosDir = Directory('${restoreDir.path}/photos');

    if (await restorePhotosDir.exists()) {
      final files = restorePhotosDir.listSync();

      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;

          final newPath =
              '${appDir.path}/$fileName';

          await file.copy(newPath);
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('データを復元しました'),
      ),
    );
  }

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
            value: widget.hidePriceOnStartup,
            onChanged: widget.onHidePriceChanged,
          ),
          SwitchListTile(
            title: const Text('ダークモード'),
            subtitle: const Text('画面を暗いテーマにします'),
            value: widget.darkMode,
            onChanged: widget.onDarkModeChanged,
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
            subtitle: const Text('DownloadにZIPを保存'),
            onTap: backupData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('データ復元'),
            subtitle: const Text('ZIPから復元'),
            onTap: restoreData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('データ初期化'),
            subtitle: const Text('すべてのデータを削除'),
            onTap: resetData,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('推し旅マップ'),
            subtitle: Text('Version 1.2.8'),
          ),
        ],
      ),
    );
  }
}

class EventAddPage extends StatefulWidget {
  final Map<String, dynamic>? event;

  const EventAddPage({
    super.key,
    this.event,
  });

  @override
  State<EventAddPage> createState() => _EventAddPageState();
}

class _EventAddPageState extends State<EventAddPage> {
  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final venueController = TextEditingController();
  String selectedPrefecture = '東京都';

  final List<String> prefectures = const [
    '北海道',
    '青森県','岩手県','宮城県','秋田県','山形県','福島県',
    '茨城県','栃木県','群馬県','埼玉県','千葉県','東京都','神奈川県',
    '新潟県','富山県','石川県','福井県','山梨県','長野県','岐阜県','静岡県','愛知県',
    '三重県','滋賀県','京都府','大阪府','兵庫県','奈良県','和歌山県',
    '鳥取県','島根県','岡山県','広島県','山口県',
    '徳島県','香川県','愛媛県','高知県',
    '福岡県','佐賀県','長崎県','熊本県','大分県','宮崎県','鹿児島県',
    '沖縄県',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      titleController.text = widget.event!['title'];
      dateController.text = widget.event!['date'];
      venueController.text = widget.event!['venue'];
    } else {
      final now = DateTime.now();
      dateController.text = formatDate(now);
    }

    if (widget.event != null) {
      selectedPrefecture =
          widget.event!['prefecture'] ?? '東京都';
    }
  }

  String formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'イベント追加' : 'イベント編集'),
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
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '日付',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: () {
                DateTime selectedDate =
                    DateTime.tryParse(dateController.text) ?? DateTime.now();

                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SizedBox(
                      height: 260,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () {
                                  dateController.text = formatDate(selectedDate);
                                  Navigator.pop(context);
                                },
                                child: const Text('決定'),
                              ),
                            ],
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              dateOrder: DatePickerDateOrder.ymd,
                              initialDateTime: selectedDate,
                              onDateTimeChanged: (date) {
                                selectedDate = date;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: venueController,
              decoration: const InputDecoration(
                labelText: '会場',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: selectedPrefecture,
              decoration: const InputDecoration(
                labelText: '都道府県',
                border: OutlineInputBorder(),
              ),
              items: prefectures.map((prefecture) {
                return DropdownMenuItem(
                  value: prefecture,
                  child: Text(prefecture),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPrefecture = value!;
                });
              },
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
                      'prefecture': selectedPrefecture,
                    },
                  );
                },
                child: Text(widget.event == null ? '登録' : '更新'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoodsAddPage extends StatefulWidget {
  final int? defaultEventId;
  final Map<String, dynamic>? goods;

  const GoodsAddPage({
    super.key,
    this.defaultEventId,
    this.goods,
  });

  @override
  State<GoodsAddPage> createState() => _GoodsAddPageState();
}

class _GoodsAddPageState extends State<GoodsAddPage> {
  final groupController = TextEditingController();
  final memberController = TextEditingController();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  
  int? selectedOshiId;
  List<Map<String, dynamic>> oshis = [];

  String selectedCategory = 'CD';
  String purchaseType = 'イベント';
  int? selectedEventId;

  List<Map<String, dynamic>> events = [];

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
  void initState() {
    super.initState();

    if (widget.goods != null) {
      groupController.text = widget.goods!['group_name'];
      memberController.text = widget.goods!['member_name'];
      nameController.text = widget.goods!['name'];
      quantityController.text = widget.goods!['quantity'].toString();
      priceController.text = widget.goods!['price'].toString();
      selectedCategory = widget.goods!['category'];
      selectedEventId = widget.goods!['event_id'];
      purchaseType = selectedEventId == null ? 'その他' : 'イベント';
      selectedOshiId = widget.goods!['oshi_id'];
    } else if (widget.defaultEventId != null) {
      purchaseType = 'イベント';
      selectedEventId = widget.defaultEventId;
    }

    loadEvents();
    loadOshis();
  }

  Future<void> loadEvents() async {
    final data = await DatabaseHelper.instance.getEvents();

    setState(() {
      events = data;

      if (selectedEventId == null && events.isNotEmpty) {
        selectedEventId = events.first['id'];
      }
    });
  }

  Future<void> loadOshis() async {
    final data = await DatabaseHelper.instance.getOshis();

    setState(() {
      oshis = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goods == null ? 'グッズ追加' : 'グッズ編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: purchaseType,
              decoration: const InputDecoration(
                labelText: '購入タイプ',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'イベント',
                  child: Text('イベントで購入'),
                ),
                DropdownMenuItem(
                  value: 'その他',
                  child: Text('通販・店舗・中古など'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  purchaseType = value!;
                });
              },
            ),

            const SizedBox(height: 12),

            if (purchaseType == 'イベント')
              DropdownButtonFormField<int>(
                initialValue: selectedEventId,
                decoration: const InputDecoration(
                  labelText: '対象イベント',
                  border: OutlineInputBorder(),
                ),
                items: events.map((event) {
                  return DropdownMenuItem<int>(
                    value: event['id'],
                    child: Text(event['title']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEventId = value;
                  });
                },
              ),

            if (purchaseType == 'イベント')
              const SizedBox(height: 12),

            DropdownButtonFormField<int?>(
              initialValue: selectedOshiId,
              decoration: const InputDecoration(
                labelText: '推しリストから選択',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('選択しない'),
                ),
                ...oshis.map((oshi) {
                  return DropdownMenuItem<int?>(
                    value: oshi['id'],
                    child: Text(
                      '${oshi['group_name']} / ${oshi['name']}',
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedOshiId = value;

                  if (value != null) {
                    final selected = oshis.firstWhere(
                      (oshi) => oshi['id'] == value,
                    );

                    memberController.text =
                        selected['name'] ?? '';

                    groupController.text =
                        selected['group_name'] ?? '';
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            if (selectedOshiId == null) ...[
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
            ],

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
                      'event_id': purchaseType == 'イベント'
                          ? selectedEventId
                          : null,
                      'group_name': groupController.text,
                      'member_name': memberController.text,
                      'oshi_id': selectedOshiId,
                      'category': selectedCategory,
                      'name': nameController.text,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'price': int.tryParse(priceController.text) ?? 0,
                    },
                  );
                },
                child: Text(widget.goods == null ? '登録' : '更新'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  List<Map<String, dynamic>> eventGoods = [];
  List<Map<String, dynamic>> eventExpenses = [];
  List<Map<String, dynamic>> eventPhotos = [];
  final ImagePicker picker = ImagePicker();
  bool showGoods = false;
  bool showExpenses = false;

  @override
  void initState() {
    super.initState();
    loadEventGoods();
  }

  Future<void> loadEventGoods() async {
    final eventId = widget.event['id'];

    if (eventId == null) return;

    final goodsData =
      await DatabaseHelper.instance.getGoodsByEventId(eventId);

    final expenseData =
      await DatabaseHelper.instance.getExpensesByEventId(eventId);
      
    final photoData =
      await DatabaseHelper.instance.getPhotosByEventId(eventId);

    setState(() {
      eventGoods = goodsData;
      eventExpenses = expenseData;
      eventPhotos = photoData;
    });
  }

  Future<void> deleteEventGoodsItem(int id) async {
    await DatabaseHelper.instance.deleteGoods(id);
    await loadEventGoods();
  }

  Future<void> deleteEventExpenseItem(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    await loadEventGoods();
  }

  Future<void> updateEventGoodsItem(
    int id,
    Map<String, dynamic> goods,
  ) async {
    await DatabaseHelper.instance.updateGoods(id, goods);
    await loadEventGoods();
  }

  Future<void> addEventPhoto() async {
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    for (final image in images) {
      await DatabaseHelper.instance.insertPhoto({
        'event_id': widget.event['id'],
        'goods_id': null,
        'image_path': image.path,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    await loadEventGoods();
  }


  @override
  Widget build(BuildContext context) {
    final goodsTotal = eventGoods.fold<int>(
      0,
      (sum, item) => sum + (item['price'] as int? ?? 0),
    );
    final expenseTotal = eventExpenses.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int? ?? 0),
    );

    final totalCost = goodsTotal + expenseTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント詳細'),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addGoods',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoodsAddPage(
                    defaultEventId: widget.event['id'],
                  ),
                ),
              );

              if (result != null) {
                await DatabaseHelper.instance.insertGoods(result);
                await loadEventGoods();
              }
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('グッズ追加'),
          ),

          const SizedBox(height: 12),

          FloatingActionButton.extended(
            heroTag: 'addExpense',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseAddPage(
                    defaultEventId: widget.event['id'],
                    defaultEventName: widget.event['title'],
                  ),
                ),
              );

              if (result != null) {
                await DatabaseHelper.instance.insertExpense(result);
                await loadEventGoods();
              }
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('費用追加'),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            FilledButton.icon(
              onPressed: addEventPhoto,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('写真を追加'),
            ),

            const SizedBox(height: 12),

            Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event['date'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event['venue'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'グッズ代合計: ¥$goodsTotal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '費用合計: ¥$expenseTotal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '総額: ¥$totalCost',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('購入グッズ数: ${eventGoods.length}件'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text('購入グッズ ${eventGoods.length}件'),
                trailing: Icon(
                  showGoods ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  setState(() {
                    showGoods = !showGoods;
                  });
                },
              ),
            ),

            if (showGoods)
              eventGoods.isEmpty
                ? const Card(
                  child: ListTile(
                    title: Text('このイベントのグッズはまだありません'),
                  ),
                )
                : Column(
                    children: eventGoods.map((goods) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag),
                          title: Text(goods['name']),
                          subtitle: Text(
                            '${goods['group_name']} / ${goods['member_name']}\n'
                            '${goods['category']} / ${goods['quantity']}個 / ${goods['price']}円',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GoodsAddPage(
                                        goods: goods,
                                      ),
                                    ),
                                  );

                                  if (result != null) {
                                    await updateEventGoodsItem(goods['id'], result);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await deleteEventGoodsItem(goods['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('費用 ${eventExpenses.length}件'),
                trailing: Icon(
                  showExpenses ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  setState(() {
                    showExpenses = !showExpenses;
                  });
                },
              ),
            ),

            if (showExpenses)
              eventExpenses.isEmpty
                ? const Card(
                  child: ListTile(
                    title: Text('このイベントの費用はまだありません'),
                  ),
                )
                : Column(
                  children: eventExpenses.map((expense) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(expense['category']),
                        subtitle: Text(expense['memo'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('¥${expense['amount']}'),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await deleteEventExpenseItem(expense['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                const Text(
                  'イベント写真',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (eventPhotos.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('写真はまだありません'),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: eventPhotos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final photo = eventPhotos[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoViewerPage(
                                imagePath: photo['image_path'],
                                eventTitle: widget.event['title'],
                                eventDate: widget.event['date'],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photo['image_path']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class ExpenseAddPage extends StatefulWidget {
  final int? defaultEventId;
  final String? defaultEventName;
  final Map<String, dynamic>? expense;

  const ExpenseAddPage({
    super.key,
    this.defaultEventId,
    this.defaultEventName,
    this.expense,
  });

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
  void initState() {
    super.initState();

    if (widget.expense != null) {
      eventController.text = widget.expense!['event_name'] ?? '';
      selectedCategory = widget.expense!['category'];
      amountController.text = widget.expense!['amount'].toString();
      memoController.text = widget.expense!['memo'] ?? '';
    } else if (widget.defaultEventName != null) {
      eventController.text = widget.defaultEventName!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? '費用追加' : '費用編集'),
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
                      'event_id': widget.defaultEventId ?? widget.expense?['event_id'],
                      'event_name': eventController.text,
                      'category': selectedCategory,
                      'amount': int.tryParse(amountController.text) ?? 0,
                      'memo': memoController.text,
                    },
                  );
                },
                child: Text(widget.expense == null ? '登録' : '更新'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final Future<void> Function() onDelete;
  final Future<void> Function() onEdit;

  const EventCard({
    super.key,
    required this.event,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await onEdit();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

String normalizeText(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll('　', ' ')
      .replaceAll('＋', '+');
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
              ),

              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<Map<String, dynamic>> photos = [];

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    final data = await DatabaseHelper.instance.getAllPhotos();

    setState(() {
      photos = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アルバム'),
      ),
      body: photos.isEmpty
          ? const Center(
              child: Text('画像はまだ登録されていません'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];

                return GestureDetector(
                  onLongPress: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('画像を削除'),
                          content: const Text('この画像を削除しますか？'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: const Text('キャンセル'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: const Text('削除'),
                            ),
                          ],
                        );
                      },
                    );

                    if (result == true) {
                      final file = File(photo['image_path']);
                      if (await file.exists()) {
                        await file.delete();
                      }
                      await DatabaseHelper.instance.deletePhoto(
                        photo['id'],
                      );

                      await loadPhotos();
                    }
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewerPage(
                          imagePath: photo['image_path'],
                          eventTitle: photo['event_title'],
                          eventDate: photo['event_date'],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photo['image_path']),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PhotoViewerPage extends StatelessWidget {
  final String imagePath;
  final String? eventTitle;
  final String? eventDate;

  const PhotoViewerPage({
    super.key,
    required this.imagePath,
    this.eventTitle,
    this.eventDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真詳細'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            eventTitle ?? 'イベント未設定',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            eventDate ?? '',
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}