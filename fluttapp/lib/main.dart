import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hymn App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HymnListPage(),
    );
  }
}

class HymnListPage extends StatefulWidget {
  @override
  _HymnListPageState createState() => _HymnListPageState();
}

class _HymnListPageState extends State<HymnListPage> {
  List hymns = [];
  List filteredHymns = [];
  String language = 'en';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHymns();
  }

  Future<void> loadHymns() async {
    final String jsonString = await rootBundle.loadString('assets/hymns.json');
    final data = json.decode(jsonString);
    setState(() {
      hymns = data['hymns'];
      filteredHymns = hymns;
      isLoading = false;
    });
  }

  void filterHymns(String query) {
    setState(() {
      filteredHymns = hymns.where((hymn) {
        final title = hymn['title'][language].toLowerCase();
        final number = hymn['number'].toString();
        return title.contains(query.toLowerCase()) || number.contains(query);
      }).toList();
    });
  }

  void toggleTheme() {
    final isDarkMode = MyApp.of(context)?._themeMode == ThemeMode.dark;
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    MyApp.of(context)?.setThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hymns"),
        actions: [
          DropdownButton<String>(
            value: language,
            onChanged: (value) {
              setState(() {
                language = value!;
                filterHymns('');
              });
            },
            items: [
              DropdownMenuItem(value: 'en', child: Text("English")),
              DropdownMenuItem(value: 'yo', child: Text("Yoruba")),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(toggleTheme: toggleTheme),
      body: isLoading
          ? Center(child: Image.asset('assets/loading.png'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: filterHymns,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredHymns.length,
                    itemBuilder: (_, index) {
                      final hymn = filteredHymns[index];
                      return ListTile(
                        leading: Text(hymn['number'].toString()),
                        title: Text(hymn['title'][language]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HymnDetailPage(
                              hymn: hymn,
                              language: language,
                              onLanguageChange: (newLang) {
                                setState(() {
                                  language = newLang;
                                  filterHymns('');
                                });
                              },
                            ),
                          ),
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

class HymnDetailPage extends StatelessWidget {
  final Map hymn;
  final String language;
  final Function(String) onLanguageChange;

  HymnDetailPage({
    required this.hymn,
    required this.language,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hymn['title'][language]),
        actions: [
          DropdownButton<String>(
            value: language,
            onChanged: (value) {
              if (value != null) {
                onLanguageChange(value);
                Navigator.pop(context);
              }
            },
            items: [
              DropdownMenuItem(value: 'en', child: Text("English")),
              DropdownMenuItem(value: 'yo', child: Text("Yoruba")),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          hymn['lyrics'][language].replaceAll('\\n', '\n'),
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final VoidCallback toggleTheme;

  AppDrawer({required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(
              'CFM Hymns',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Toggle Dark Mode'),
            onTap: toggleTheme,
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'CFM Hymns',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.book),
                children: [
                  Text('Welcome to CFM Hymns App!'),
                  SizedBox(height: 10),
                  Text(
                    'The Official Hymn App of Christ Fishers of Men Bible Church.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Developed by: Tosin OLUYEMI',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Contact: toluyemi070@gmail.com\n09032946686',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}