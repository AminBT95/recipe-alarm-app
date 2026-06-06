import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(const InitializationSettings(android: androidInit));
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  runApp(const RecetteAlarmApp());
}

class C {
  static const cream = Color(0xFFFBF4EA);
  static const card = Color(0xFFFFFCF7);
  static const ink = Color(0xFF1D2622);
  static const muted = Color(0xFF80756B);
  static const green = Color(0xFF5C715E);
  static const sage = Color(0xFF9CAF96);
  static const gold = Color(0xFFD7A84B);
  static const terracotta = Color(0xFFB86B4B);
  static const clay = Color(0xFFE8D3C0);
  static const blush = Color(0xFFF4E6D8);
  static const red = Color(0xFFD95D59);
}

class Ingredient {
  String name;
  double qty;
  String unit;
  bool have;
  String icon;
  String imagePath;
  bool needsThaw;
  int thawHours;
  Ingredient({required this.name, required this.qty, required this.unit, this.have = false, this.icon = 'restaurant', this.imagePath = '', this.needsThaw = false, this.thawHours = 12});
  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'unit': unit, 'have': have, 'icon': icon, 'imagePath': imagePath, 'needsThaw': needsThaw, 'thawHours': thawHours};
  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: j['name'] ?? '',
        qty: (j['qty'] as num? ?? 0).toDouble(),
        unit: j['unit'] ?? '',
        have: j['have'] ?? false,
        icon: j['icon'] ?? guessIngredientIcon(j['name'] ?? ''),
        imagePath: j['imagePath'] ?? '',
        needsThaw: j['needsThaw'] ?? false,
        thawHours: j['thawHours'] ?? 12,
      );
}

class CookStep {
  String title;
  String type;
  int minutes;
  int seconds;
  int temp;
  String note;
  String imagePath;
  String videoUrl;
  bool parallel;
  int parallelGroup;
  CookStep({
    required this.title,
    this.type = 'Cuisson',
    required this.minutes,
    this.seconds = 0,
    required this.temp,
    required this.note,
    this.imagePath = '',
    this.videoUrl = '',
    this.parallel = false,
    this.parallelGroup = 0,
  });
  int get totalSeconds => (minutes * 60) + seconds;
  Map<String, dynamic> toJson() => {
    'title': title,
    'type': type,
    'minutes': minutes,
    'seconds': seconds,
    'temp': temp,
    'note': note,
    'imagePath': imagePath,
    'videoUrl': videoUrl,
    'parallel': parallel,
    'parallelGroup': parallelGroup,
  };
  factory CookStep.fromJson(Map<String, dynamic> j) => CookStep(
        title: j['title'] ?? '',
        type: j['type'] ?? 'Cuisson',
        minutes: j['minutes'] ?? 0,
        seconds: j['seconds'] ?? 0,
        temp: j['temp'] ?? 0,
        note: j['note'] ?? '',
        imagePath: j['imagePath'] ?? '',
        videoUrl: j['videoUrl'] ?? '',
        parallel: j['parallel'] ?? false,
        parallelGroup: j['parallelGroup'] ?? 0,
      );
}

class Recipe {
  String id;
  String title;
  String category;
  String imagePath;
  String difficulty;
  String liquidNote;
  String thawNote;
  int minutes;
  int servings;
  int rating;
  int temp;
  bool favorite;
  List<String> videos;
  List<Ingredient> ingredients;
  List<CookStep> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.category,
    this.imagePath = '',
    this.difficulty = 'Facile',
    this.liquidNote = '',
    this.thawNote = '',
    this.minutes = 30,
    this.servings = 4,
    this.rating = 5,
    this.temp = 160,
    this.favorite = false,
    List<String>? videos,
    List<Ingredient>? ingredients,
    List<CookStep>? steps,
  })  : videos = videos ?? [],
        ingredients = ingredients ?? [],
        steps = steps ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'imagePath': imagePath,
        'difficulty': difficulty,
        'liquidNote': liquidNote,
        'thawNote': thawNote,
        'minutes': minutes,
        'servings': servings,
        'rating': rating,
        'temp': temp,
        'favorite': favorite,
        'videos': videos,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: j['title'] ?? 'Recette',
        category: j['category'] ?? 'Autres',
        imagePath: j['imagePath'] ?? '',
        difficulty: j['difficulty'] ?? 'Facile',
        liquidNote: j['liquidNote'] ?? '',
        thawNote: j['thawNote'] ?? '',
        minutes: j['minutes'] ?? 30,
        servings: j['servings'] ?? 4,
        rating: j['rating'] ?? 5,
        temp: j['temp'] ?? 160,
        favorite: j['favorite'] ?? false,
        videos: List<String>.from(j['videos'] ?? []),
        ingredients: (j['ingredients'] as List? ?? []).map((e) => Ingredient.fromJson(e)).toList(),
        steps: (j['steps'] as List? ?? []).map((e) => CookStep.fromJson(e)).toList(),
      );
}


class AppSettings {
  bool alarmSound;
  bool vibration;
  bool keepAwake;
  bool repeatAlarm;
  bool showFullScreen;
  int glassMl;
  String themeName;
  bool thawNotifications;
  bool autoBackup;
  int defaultExtraMinutes;
  double fontScale;
  String alarmTone;
  bool enableCustomTimers;
  bool showMealTimers;

  AppSettings({
    this.alarmSound = true,
    this.vibration = true,
    this.keepAwake = true,
    this.repeatAlarm = true,
    this.showFullScreen = true,
    this.glassMl = 200,
    this.themeName = 'Crème premium',
    this.thawNotifications = true,
    this.autoBackup = true,
    this.defaultExtraMinutes = 5,
    this.fontScale = 1.0,
    this.alarmTone = 'Fort classique',
    this.enableCustomTimers = true,
    this.showMealTimers = true,
  });

  Map<String, dynamic> toJson() => {
        'alarmSound': alarmSound,
        'vibration': vibration,
        'keepAwake': keepAwake,
        'repeatAlarm': repeatAlarm,
        'showFullScreen': showFullScreen,
        'glassMl': glassMl,
        'themeName': themeName,
        'thawNotifications': thawNotifications,
        'autoBackup': autoBackup,
        'defaultExtraMinutes': defaultExtraMinutes,
        'fontScale': fontScale,
        'alarmTone': alarmTone,
        'enableCustomTimers': enableCustomTimers,
        'showMealTimers': showMealTimers,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        alarmSound: j['alarmSound'] ?? true,
        vibration: j['vibration'] ?? true,
        keepAwake: j['keepAwake'] ?? true,
        repeatAlarm: j['repeatAlarm'] ?? true,
        showFullScreen: j['showFullScreen'] ?? true,
        glassMl: j['glassMl'] ?? 200,
        themeName: j['themeName'] ?? 'Crème premium',
        thawNotifications: j['thawNotifications'] ?? true,
        autoBackup: j['autoBackup'] ?? true,
        defaultExtraMinutes: j['defaultExtraMinutes'] ?? 5,
        fontScale: (j['fontScale'] as num? ?? 1.0).toDouble(),
        alarmTone: j['alarmTone'] ?? 'Fort classique',
        enableCustomTimers: j['enableCustomTimers'] ?? true,
        showMealTimers: j['showMealTimers'] ?? true,
      );
}

class Store extends ChangeNotifier {
  List<Recipe> recipes = [];
  List<String> categories = ['Tajines','Desserts','Plats','Gâteaux','Jus','Soupes','Salades','Pain','Autres'];
  Map<String, String> mealPlan = {};
  Map<String, String> categoryIcons = {};
  AppSettings settings = AppSettings();

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('recipes_v4') ?? sp.getString('recipes_v3');
    final oldRaw = sp.getString('recipes_v2');
    final settingsRaw = sp.getString('settings_v1');
    final catsRaw = sp.getString('categories_v1');
    final mealRaw = sp.getString('meal_plan_v1');
    final catIconsRaw = sp.getString('category_icons_v1');
    if (settingsRaw != null) {
      settings = AppSettings.fromJson(jsonDecode(settingsRaw));
    }
    if (catsRaw != null) {
      categories = List<String>.from(jsonDecode(catsRaw));
    }
    if (mealRaw != null) {
      mealPlan = Map<String, String>.from(jsonDecode(mealRaw));
    }
    final source = raw ?? oldRaw;
    if (source == null) {
      recipes = [sampleRecipe(), sampleDessert()];
      await save();
    } else {
      recipes = (jsonDecode(source) as List).map((e) => Recipe.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> save({bool notify = true}) async {
    final sp = await SharedPreferences.getInstance();
    final payload = jsonEncode(recipes.map((e) => e.toJson()).toList());
    await sp.setString('recipes_v4', payload);
    await sp.setString('recipes_v3', payload);
    await sp.setString('settings_v1', jsonEncode(settings.toJson()));
    await sp.setString('categories_v1', jsonEncode(categories));
    await sp.setString('meal_plan_v1', jsonEncode(mealPlan));
    await sp.setString('category_icons_v1', jsonEncode(categoryIcons));
    if (settings.autoBackup) {
      await sp.setString('recette_alarm_auto_backup', exportJson());
    }
    if (notify) notifyListeners();
  }

  void upsert(Recipe recipe) {
    final index = recipes.indexWhere((e) => e.id == recipe.id);
    if (index == -1) {
      recipes.insert(0, recipe);
    } else {
      recipes[index] = Recipe.fromJson(recipe.toJson());
    }
    save();
  }

  void remove(Recipe recipe) {
    recipes.removeWhere((e) => e.id == recipe.id);
    save();
  }

  Recipe? byId(String id) {
    try { return recipes.firstWhere((e) => e.id == id); } catch (_) { return null; }
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'settings': settings.toJson(),
        'categories': categories,
        'mealPlan': mealPlan,
        'categoryIcons': categoryIcons,
        'recipes': recipes.map((e) => e.toJson()).toList(),
      });

  Future<bool> importJson(String raw) async {
    final data = jsonDecode(raw);
    if (data is Map && data['recipes'] is List) {
      recipes = (data['recipes'] as List).map((e) => Recipe.fromJson(e)).toList();
      if (data['settings'] is Map) settings = AppSettings.fromJson(Map<String, dynamic>.from(data['settings']));
      if (data['categories'] is List) categories = List<String>.from(data['categories']);
      if (data['mealPlan'] is Map) mealPlan = Map<String, String>.from(data['mealPlan']);
      if (data['categoryIcons'] is Map) categoryIcons = Map<String, String>.from(data['categoryIcons']);
    } else if (data is List) {
      recipes = data.map((e) => Recipe.fromJson(e)).toList();
    } else {
      return false;
    }
    await save();
    return true;
  }

  Future<void> resetSamples() async {
    recipes = [sampleRecipe(), sampleDessert()];
    await save();
  }
}

Recipe sampleRecipe() => Recipe(
      id: 'r1',
      title: 'Tajine Poulet aux Olives',
      category: 'Tajines',
      minutes: 45,
      servings: 4,
      rating: 5,
      temp: 160,
      difficulty: 'Moyen',
      liquidNote: '0.7 L d’eau ≈ 3 verres et demi',
      thawNote: 'Sortir le poulet du congélateur la veille au soir.',
      videos: ['https://youtube.com'],
      ingredients: [
        Ingredient(name: 'Poulet fermier', qty: 1.5, unit: 'kg'),
        Ingredient(name: 'Olives vertes', qty: 1, unit: 'verre'),
        Ingredient(name: 'Oignons', qty: 2, unit: 'pièces'),
        Ingredient(name: 'Eau', qty: 0.7, unit: 'L'),
        Ingredient(name: 'Safran', qty: 1, unit: 'pincée'),
      ],
      steps: [
        CookStep(title: 'Faire revenir le poulet', minutes: 10, temp: 160, note: 'Remuer doucement et surveiller le feu.'),
        CookStep(title: 'Ajouter les oignons, épices et eau', minutes: 20, temp: 180, note: 'Vérifier l’eau pour éviter que la sauce sèche.'),
        CookStep(title: 'Ajouter les olives et réduire le feu', minutes: 15, temp: 120, note: 'Baisser le feu et vérifier la sauce.'),
      ],
    );

Recipe sampleDessert() => Recipe(
      id: 'r2',
      title: 'Gâteau Yaourt Maison',
      category: 'Desserts',
      minutes: 35,
      servings: 6,
      rating: 4,
      temp: 180,
      difficulty: 'Facile',
      liquidNote: '1 pot de yaourt peut servir de mesure.',
      ingredients: [
        Ingredient(name: 'Yaourt', qty: 1, unit: 'pot'),
        Ingredient(name: 'Farine', qty: 3, unit: 'pots'),
        Ingredient(name: 'Sucre', qty: 2, unit: 'pots'),
        Ingredient(name: 'Huile', qty: 0.5, unit: 'pot'),
        Ingredient(name: 'Œufs', qty: 3, unit: 'pièces'),
      ],
      steps: [
        CookStep(title: 'Mélanger les ingrédients', minutes: 8, temp: 0, note: 'Mélange homogène sans grumeaux.'),
        CookStep(title: 'Cuisson au four', minutes: 27, temp: 180, note: 'Vérifier avec un couteau avant de sortir.'),
      ],
    );

class RecetteAlarmApp extends StatefulWidget {
  const RecetteAlarmApp({super.key});
  @override
  State<RecetteAlarmApp> createState() => _RecetteAlarmAppState();
}

class _RecetteAlarmAppState extends State<RecetteAlarmApp> {
  final store = Store();
  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Recette Alarm',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: C.cream,
          colorScheme: ColorScheme.fromSeed(seedColor: C.green, primary: C.green, secondary: C.terracotta, tertiary: C.gold, surface: C.card),
          textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(bodyColor: C.ink, displayColor: C.ink),
          appBarTheme: const AppBarTheme(backgroundColor: C.cream, elevation: 0, foregroundColor: C.ink, centerTitle: false),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: C.card,
            indicatorColor: C.green.withOpacity(.12),
            labelTextStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ),
        home: MainShell(store: store),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Store store;
  const MainShell({super.key, required this.store});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store, onAdd: () => openEditor(context, widget.store)),
      ShoppingPage(store: widget.store),
      FavoritesPage(store: widget.store),
      MorePage(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: index,
              height: 66,
              onDestinationSelected: (i) => setState(() => index = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Recettes'),
                NavigationDestination(icon: Icon(Icons.shopping_basket_outlined), selectedIcon: Icon(Icons.shopping_basket_rounded), label: 'Courses'),
                NavigationDestination(icon: Icon(Icons.favorite_outline_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Favoris'),
                NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.dashboard_customize_rounded), label: 'Plus'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Store store;
  final VoidCallback onAdd;
  const HomePage({super.key, required this.store, required this.onAdd});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String query = '';
  String category = 'Tous';
  List<String> get cats => ['Tous', ...widget.store.categories];

  @override
  Widget build(BuildContext context) {
    final list = widget.store.recipes.where((r) {
      final q = query.toLowerCase().trim();
      final matchQuery = q.isEmpty || r.title.toLowerCase().contains(q) || r.category.toLowerCase().contains(q) || r.ingredients.any((i)=>i.name.toLowerCase().contains(q)) || r.steps.any((st)=>st.title.toLowerCase().contains(q) || st.type.toLowerCase().contains(q));
      final matchCat = category == 'Tous' || r.category == category;
      return matchQuery && matchCat;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.green,
        foregroundColor: Colors.white,
        elevation: 10,
        icon: const Icon(Icons.add),
        label: const Text('Recette'),
        onPressed: widget.onAdd,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(children: [
                _header(),
                const SizedBox(height: 18),
                _search(),
                const SizedBox(height: 18),
                _categoryBar(),
                const SizedBox(height: 18),
                _smartCard(),
                const SizedBox(height: 22),
                _section('Recettes', '${list.length} disponibles'),
                const SizedBox(height: 14),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  childAspectRatio: .70,
                ),
                delegate: SliverChildBuilderDelegate((_, i) => RecipeCard(store: widget.store, recipe: list[i]), childCount: list.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.local_dining_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour Soukaina 👋', style: TextStyle(fontSize: 14, color: C.muted, fontWeight: FontWeight.w700)),
              SizedBox(height: 3),
              Text('Que cuisine-t-on aujourd’hui ?', style: TextStyle(fontSize: 22, height: 1.12, color: C.ink, fontWeight: FontWeight.w800)),
            ]),
          ),
          IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
        ],
      );

  Widget _search() => Container(
        decoration: soft(radius: 24),
        child: TextField(
          onChanged: (v) => setState(() => query = v),
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: Icon(Icons.filter_list_rounded),
            hintText: 'Rechercher recette, ingrédient...',
            contentPadding: EdgeInsets.symmetric(vertical: 17),
          ),
        ),
      );

  Widget _categoryBar() => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final selected = cats[i] == category;
            return ChoiceChip(
              selected: selected,
              label: Text(cats[i]),
              avatar: Icon(_catIcon(cats[i]), size: 18),
              onSelected: (_) => setState(() => category = cats[i]),
              labelStyle: TextStyle(fontWeight: FontWeight.w900, color: selected ? Colors.white : C.ink),
              selectedColor: C.green,
              backgroundColor: C.card,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            );
          },
        ),
      );

  Widget _smartCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF5C715E), Color(0xFF8D7B68)]),
          boxShadow: shadow(),
        ),
        child: Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mode anti-brûlure', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('Alarmes fortes, vibration et étapes claires pendant la cuisson.', style: TextStyle(color: Color(0xFFE9F4EC), height: 1.35, fontWeight: FontWeight.w600)),
            ]),
          ),
          Container(
            width: 72,
            height: 66,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(26)),
            child: const Icon(Icons.timer_rounded, color: C.gold, size: 38),
          ),
        ]),
      );

  Widget _section(String title, String sub) => Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.ink))),
        Text(sub, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800)),
      ]);
}

class RecipeCard extends StatelessWidget {
  final Store store;
  final Recipe recipe;
  const RecipeCard({super.key, required this.store, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(store: store, recipe: recipe))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: soft(radius: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: RecipeImage(recipe: recipe, radius: 28)),
              Positioned(left: 10, bottom: 10, child: miniPill('${recipe.minutes} min', Icons.schedule_rounded)),
              Positioned(
                right: 8,
                bottom: 5,
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(.88)),
                  onPressed: () {
                    recipe.favorite = !recipe.favorite;
                    store.save();
                  },
                  icon: Icon(recipe.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: C.red),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe.category, style: const TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(recipe.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, height: 1.18, fontWeight: FontWeight.w800, color: C.ink)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded, color: C.gold, size: 18),
                Text(' ${recipe.rating}.0', style: const TextStyle(fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${recipe.servings} pers.', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final Store store;
  final Recipe recipe;
  const DetailPage({super.key, required this.store, required this.recipe});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late String id;
  @override
  void initState() { super.initState(); id = widget.recipe.id; }
  Recipe get recipe => widget.store.byId(id) ?? widget.recipe;

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RecipeEditorPage(store: widget.store, recipe: recipe)));
    if (changed == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (_, __) => Scaffold(
        body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 295,
            pinned: true,
            backgroundColor: C.cream,
            actions: [
              IconButton.filledTonal(onPressed: _edit, icon: const Icon(Icons.edit_rounded)),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(background: Padding(padding: const EdgeInsets.fromLTRB(16, 70, 16, 18), child: RecipeImage(recipe: r, radius: 34))),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
            sliver: SliverList.list(children: [
              Text(r.title, style: const TextStyle(fontSize: 25, height: 1.08, fontWeight: FontWeight.w800, color: C.ink)),
              const SizedBox(height: 9),
              Row(children: [
                const Icon(Icons.star_rounded, color: C.gold),
                Text(' ${r.rating}/5', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                Text(r.category, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                infoTile(Icons.schedule_rounded, '${r.minutes} min'),
                infoTile(Icons.people_alt_rounded, '${r.servings} pers.'),
                infoTile(Icons.thermostat_rounded, '${r.temp}°C'),
                infoTile(Icons.signal_cellular_alt_rounded, r.difficulty),
              ]),
              const SizedBox(height: 18),
              if (r.liquidNote.isNotEmpty) premiumNote(Icons.water_drop_rounded, 'Liquide conseillé', r.liquidNote),
              _title('Ingrédients', action: TextButton.icon(onPressed: _edit, icon: const Icon(Icons.add_rounded), label: const Text('Gérer'))),
              if (r.ingredients.isEmpty) premiumEmpty(Icons.kitchen_rounded, 'Aucun ingrédient', 'Ajoute les ingrédients depuis Modifier.'),
              ...r.ingredients.map((i) => ingredientRow(i)),
              _title('Étapes de cuisson', action: TextButton.icon(onPressed: _edit, icon: const Icon(Icons.add_alarm_rounded), label: const Text('Gérer'))),
              if (r.steps.isEmpty) premiumEmpty(Icons.timer_off_rounded, 'Aucune étape', 'Ajoute les étapes avec durée, température et note anti-brûlure.'),
              ...r.steps.asMap().entries.map((e) => stepRow(e.key, e.value)),
              if (r.videos.isNotEmpty) _title('Vidéos'),
              ...r.videos.map((v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_fill_rounded, color: C.terracotta),
                    title: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => launchUrl(Uri.parse(v), mode: LaunchMode.externalApplication),
                  )),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: r.steps.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CookingPage(recipe: r, store: widget.store))),
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Cuisson guidée étape par étape'),
                style: mainButtonStyle(),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: r.steps.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => MultiTimerPage(store: widget.store, recipe: r))),
                icon: const Icon(Icons.timer_rounded),
                label: const Text('Lancer chronos simultanés'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShoppingPage(store: widget.store, recipe: r))),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Liste de courses'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _title(String t, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Row(children: [Expanded(child: Text(t, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.ink))), if (action != null) action]),
  );
}

class CookingPage extends StatefulWidget {
  final Recipe recipe;
  final Store store;
  const CookingPage({super.key, required this.recipe, required this.store});
  @override
  State<CookingPage> createState() => _CookingPageState();
}

class _CookingPageState extends State<CookingPage> {
  int index = 0;
  int remaining = 0;
  int total = 1;
  Timer? timer;
  bool running = false;
  bool alarmOpen = false;

  CookStep get step => widget.recipe.steps[index];

  @override
  void initState() {
    super.initState();
    _loadStep();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _loadStep() {
    total = step.totalSeconds <= 0 ? 1 : step.totalSeconds;
    remaining = total;
    running = false;
  }

  void start() {
    timer?.cancel();
    setState(() => running = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining <= 1) {
        timer?.cancel();
        setState(() {
          remaining = 0;
          running = false;
        });
        fireAlarm();
      } else {
        setState(() => remaining--);
      }
    });
  }

  void pause() {
    timer?.cancel();
    setState(() => running = false);
  }

  Future<void> fireAlarm() async {
    if (alarmOpen) return;
    alarmOpen = true;
    if (widget.store.settings.vibration && (await Vibration.hasVibrator() ?? false)) {
      Vibration.vibrate(pattern: [0, 700, 300, 900, 300, 1000]);
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'burn_alarm',
        'Alarmes cuisson',
        channelDescription: 'Alarmes anti-brûlure pour les recettes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: widget.store.settings.alarmSound,
        fullScreenIntent: widget.store.settings.showFullScreen,
      ),
    );
    await notifications.show(99, 'Temps écoulé', step.note.isEmpty ? 'Vérifie la cuisson maintenant.' : step.note, details);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AlarmSheet(note: step.note, onMore: (extraSeconds) {
        Navigator.pop(context);
        setState(() {
          remaining = extraSeconds;
          total = extraSeconds;
        });
        start();
      }),
    );
    alarmOpen = false;
  }

  void nextStep() {
    timer?.cancel();
    if (index >= widget.recipe.steps.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      index++;
      _loadStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          children: [
            Row(children: [
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              const Spacer(),
              Text('Étape ${index + 1}/${widget.recipe.steps.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: C.muted)),
            ]),
            const SizedBox(height: 8),
            Text(widget.recipe.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 16,
                    strokeCap: StrokeCap.round,
                    color: C.gold,
                    backgroundColor: Colors.white,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$minutes:$seconds', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: C.ink)),
                  const Text('restantes', style: TextStyle(color: C.muted, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: soft(radius: 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(step.title, style: const TextStyle(fontSize: 22, height: 1.15, fontWeight: FontWeight.w900, color: C.ink)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  miniPill(step.seconds > 0 ? '${step.minutes}m ${step.seconds}s' : '${step.minutes} min', Icons.schedule_rounded),
                  miniPill(step.type, stepTypeIcon(step.type)),
                  if (step.parallel) miniPill('Parallèle', Icons.call_split_rounded),
                  if (step.temp > 0) miniPill('${step.temp}°C', Icons.thermostat_rounded),
                ]),
                if (step.note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('⚠ ${step.note}', style: const TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w800, color: C.terracotta)),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: running ? pause : start, icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(running ? 'Pause' : 'Démarrer'), style: mainButtonStyle())),
              const SizedBox(width: 10),
              IconButton.filledTonal(onPressed: () => setState(() => remaining += 5 * 60), icon: const Icon(Icons.add_rounded)),
            ]),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: nextStep, icon: const Icon(Icons.skip_next_rounded), label: const Text('Étape suivante'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))),
          ],
        ),
      ),
    );
  }
}

class AlarmSheet extends StatelessWidget {
  final String note;
  final ValueChanged<int> onMore;
  const AlarmSheet({super.key, required this.note, required this.onMore});
  Widget more(String label, int seconds) => TextButton(
    onPressed: () => onMore(seconds),
    child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
  );
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      decoration: const BoxDecoration(color: C.ink, borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_active_rounded, color: C.gold, size: 60),
          const SizedBox(height: 14),
          const Text('Temps écoulé', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(note.isEmpty ? 'Vérifie la cuisson maintenant.' : note, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF5EAD7), fontSize: 18, height: 1.35, fontWeight: FontWeight.w800)),
          const SizedBox(height: 22),
          FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: C.gold, foregroundColor: C.ink, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('J’ai vérifié', style: TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
            more('+30 sec', 30), more('+1 min', 60), more('+2 min', 120), more('+5 min', 300), more('+10 min', 600), more('+15 min', 900),
          ]),
        ]),
      ),
    );
  }
}

class ShoppingPage extends StatefulWidget {
  final Store store;
  final Recipe? recipe;
  const ShoppingPage({super.key, required this.store, this.recipe});
  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  String? selectedId;
  @override
  void initState() {
    super.initState();
    selectedId = widget.recipe?.id ?? (widget.store.recipes.isEmpty ? null : widget.store.recipes.first.id);
  }

  Recipe? get selected {
    if (selectedId == null) return null;
    return widget.store.byId(selectedId!) ?? (widget.store.recipes.isEmpty ? null : widget.store.recipes.first);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (_, __) {
        final r = selected;
        return Scaffold(
          appBar: AppBar(title: const Text('Liste de courses', style: TextStyle(fontWeight: FontWeight.w900))),
          body: r == null
              ? Center(child: premiumEmpty(Icons.shopping_basket_outlined, 'Aucune recette', 'Ajoute une recette avec ingrédients.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  children: [
                    DropdownButtonFormField<String>(
                      value: r.id,
                      items: widget.store.recipes.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => selectedId = v),
                      decoration: inputDecoration('Choisir une recette'),
                    ),
                    const SizedBox(height: 18),
                    premiumNote(Icons.checklist_rounded, 'Coche ce que tu as déjà', 'La liste exportée contient seulement les ingrédients manquants.'),
                    const SizedBox(height: 10),
                    if (r.ingredients.isEmpty) premiumEmpty(Icons.no_food_rounded, 'Aucun ingrédient', 'Ajoute des ingrédients dans Modifier recette.'),
                    ...r.ingredients.map((i) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: soft(radius: 22),
                          child: CheckboxListTile(
                            value: i.have,
                            activeColor: C.green,
                            title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                            subtitle: Text('${fmt(i.qty)} ${i.unit}'),
                            onChanged: (v) async {
                              setState(() => i.have = v ?? false);
                              await widget.store.save();
                            },
                          ),
                        )),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: r.ingredients.isEmpty ? null : () { for (final i in r.ingredients) i.have = true; widget.store.save(); }, icon: const Icon(Icons.done_all_rounded), label: const Text('Tout cocher'))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: r.ingredients.isEmpty ? null : () { for (final i in r.ingredients) i.have = false; widget.store.save(); }, icon: const Icon(Icons.refresh_rounded), label: const Text('Réinitialiser'))),
                    ]),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: r.ingredients.isEmpty ? null : () => exportMissing(context, r),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Exporter les ingrédients manquants'),
                      style: mainButtonStyle(),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class RecipeEditorPage extends StatefulWidget {
  final Store store;
  final Recipe? recipe;
  const RecipeEditorPage({super.key, required this.store, this.recipe});
  @override
  State<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends State<RecipeEditorPage> {
  late Recipe r;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final base = widget.recipe;
    r = base == null
        ? Recipe(id: DateTime.now().millisecondsSinceEpoch.toString(), title: '', category: 'Tajines')
        : Recipe.fromJson(base.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe == null ? 'Nouvelle recette' : 'Modifier recette', style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          RecipeImage(recipe: r, radius: 30, height: 190, onTap: pickImage),
          const SizedBox(height: 18),
          field('Nom de la recette', r.title, (v) => r.title = v),
          DropdownButtonFormField<String>(value: widget.store.categories.contains(r.category) ? r.category : widget.store.categories.first, items: widget.store.categories.map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setState(()=>r.category=v??r.category), decoration: inputDecoration('Catégorie')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: field('Temps', r.minutes.toString(), (v) => r.minutes = int.tryParse(v) ?? r.minutes, number: true)),
            const SizedBox(width: 10),
            Expanded(child: field('Personnes', r.servings.toString(), (v) => r.servings = int.tryParse(v) ?? r.servings, number: true)),
          ]),
          Row(children: [
            Expanded(child: field('Degrés °C', r.temp.toString(), (v) => r.temp = int.tryParse(v) ?? r.temp, number: true)),
            const SizedBox(width: 10),
            Expanded(child: field('Note /5', r.rating.toString(), (v) => r.rating = (int.tryParse(v) ?? r.rating).clamp(1, 5), number: true)),
          ]),
          field('Liquide / mesure', r.liquidNote, (v) => r.liquidNote = v),
          field('À décongeler / préparation veille', r.thawNote, (v) => r.thawNote = v),
          sectionHeader('Ingrédients', () => editIngredient()),
          ...r.ingredients.asMap().entries.map((e) => editorTile(e.value.name, '${fmt(e.value.qty)} ${e.value.unit}', () => editIngredient(index: e.key), () { setState(() => r.ingredients.removeAt(e.key)); if (widget.recipe != null) widget.store.upsert(r); })),
          sectionHeader('Étapes', () => editStep()),
          ...r.steps.asMap().entries.map((e) => stepEditorTile(e.key, e.value, () => editStep(index: e.key), () { setState(() => r.steps.removeAt(e.key)); if (widget.recipe != null) widget.store.upsert(r); }, e.key > 0 ? () { setState(() { final item = r.steps.removeAt(e.key); r.steps.insert(e.key - 1, item); }); if (widget.recipe != null) widget.store.upsert(r); } : null, e.key < r.steps.length - 1 ? () { setState(() { final item = r.steps.removeAt(e.key); r.steps.insert(e.key + 1, item); }); if (widget.recipe != null) widget.store.upsert(r); } : null)),
          sectionHeader('Liens vidéos', () => editVideo()),
          ...r.videos.asMap().entries.map((e) => editorTile('Vidéo ${e.key + 1}', e.value, () => editVideo(index: e.key), () { setState(() => r.videos.removeAt(e.key)); if (widget.recipe != null) widget.store.upsert(r); })),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('Enregistrer'), style: mainButtonStyle()),
        ],
      ),
    );
  }

  Widget field(String label, String value, ValueChanged<String> onChanged, {bool number = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          initialValue: value,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: inputDecoration(label),
        ),
      );

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked != null) setState(() => r.imagePath = picked.path);
  }

  void save() {
    if (r.title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoute un nom de recette')));
      return;
    }
    widget.store.upsert(r);
    Navigator.pop(context, true);
  }

  Future<void> editIngredient({int? index}) async {
    final current = index == null ? Ingredient(name: '', qty: 1, unit: 'g') : r.ingredients[index];
    final name = TextEditingController(text: current.name);
    final qty = TextEditingController(text: fmt(current.qty));
    String unit = current.unit.isEmpty ? 'g' : current.unit;
    String icon = current.icon.isEmpty ? guessIngredientIcon(current.name) : current.icon;
    final units = ['g','kg','ml','L','verre','cuillère à soupe','cuillère à café','pièce','pincée','pot'];
    final icons = ['restaurant','chicken','meat','fish','egg','milk','flour','sugar','oil','water','onion','tomato','potato','carrot','lemon','olive','spice'];
    bool needsThaw = current.needsThaw;
    final thawHours = TextEditingController(text: current.thawHours.toString());
    final result = await showDialog<Ingredient>(context: context, builder: (_) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      title: Text(index == null ? 'Ajouter ingrédient' : 'Modifier ingrédient'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: inputDecoration('Nom')),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: qty, keyboardType: TextInputType.number, decoration: inputDecoration('Quantité'))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<String>(value: units.contains(unit)?unit:'g', items: units.map((e)=>DropdownMenuItem(value:e, child: Row(children:[Icon(unitIcon(e), size:18), const SizedBox(width:6), Text(e)]))).toList(), onChanged: (v)=>setLocal(()=>unit=v??unit), decoration: inputDecoration('Unité')))]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: icons.contains(icon)?icon:'restaurant', items: icons.map((e)=>DropdownMenuItem(value:e, child: Row(children:[Icon(ingredientIcon(e), size:18), const SizedBox(width:8), Text(iconLabel(e))]))).toList(), onChanged: (v)=>setLocal(()=>icon=v??icon), decoration: inputDecoration('Icône ingrédient')),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: needsThaw, title: const Text('À décongeler'), subtitle: const Text('Inclure dans les rappels décongélation'), onChanged: (v)=>setLocal(()=>needsThaw=v)),
        if(needsThaw) TextField(controller: thawHours, keyboardType: TextInputType.number, decoration: inputDecoration('Heures avant repas')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, Ingredient(name: name.text.trim(), qty: double.tryParse(qty.text.replaceAll(',', '.')) ?? 1, unit: unit, icon: icon, have: current.have, imagePath: current.imagePath, needsThaw: needsThaw, thawHours: int.tryParse(thawHours.text) ?? 12)), child: const Text('OK'))],
    )));
    if (result != null && result.name.trim().isNotEmpty) {
      setState(() {
        if (index == null) { r.ingredients.add(result); } else { r.ingredients[index] = result; }
      });
      if (widget.recipe != null) widget.store.upsert(r);
    }
  }

  Future<void> editStep({int? index}) async {
    final current = index == null ? CookStep(title: '', minutes: 5, seconds: 0, temp: r.temp, note: '') : r.steps[index];
    final title = TextEditingController(text: current.title);
    final min = TextEditingController(text: current.minutes.toString());
    final sec = TextEditingController(text: current.seconds.toString());
    final temp = TextEditingController(text: current.temp.toString());
    final note = TextEditingController(text: current.note);
    final video = TextEditingController(text: current.videoUrl);
    String type = current.type;
    bool parallel = current.parallel;
    String stepImage = current.imagePath;
    final types = ['Couper','Éplucher','Mixer','Mariner','Repos','Cuisson','Four','Friture','Vapeur','Décongélation','Dressage'];
    final result = await showDialog<CookStep>(context: context, builder: (_) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      title: Text(index == null ? 'Ajouter étape' : 'Modifier étape'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: types.contains(type)?type:'Cuisson', items: types.map((e)=>DropdownMenuItem(value:e, child: Row(children:[Icon(stepTypeIcon(e), size:18), const SizedBox(width:8), Text(e)]))).toList(), onChanged: (v)=>setLocal(()=>type=v??type), decoration: inputDecoration('Type d’étape')),
        const SizedBox(height: 10),
        TextField(controller: title, decoration: inputDecoration('Titre étape')),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: min, keyboardType: TextInputType.number, decoration: inputDecoration('Minutes'))), const SizedBox(width: 8), Expanded(child: TextField(controller: sec, keyboardType: TextInputType.number, decoration: inputDecoration('Secondes')))]),
        const SizedBox(height: 10),
        TextField(controller: temp, keyboardType: TextInputType.number, decoration: inputDecoration('Température °C')),
        const SizedBox(height: 10),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: parallel, title: const Text('Peut tourner en parallèle'), subtitle: const Text('Ex: couper les légumes pendant la cuisson'), onChanged: (v)=>setLocal(()=>parallel=v)),
        TextField(controller: note, minLines: 2, maxLines: 4, decoration: inputDecoration('Note anti-brûlure / conseil')),
        const SizedBox(height: 10),
        TextField(controller: video, decoration: inputDecoration('Lien vidéo de cette étape')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () async { final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); if(picked!=null){ setLocal(()=>stepImage=picked.path); } }, icon: const Icon(Icons.image_rounded), label: Text(stepImage.isEmpty?'Ajouter image étape':'Image étape ajoutée')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, CookStep(title: title.text, type: type, minutes: int.tryParse(min.text) ?? 5, seconds: int.tryParse(sec.text) ?? 0, temp: int.tryParse(temp.text) ?? 0, note: note.text, videoUrl: video.text, parallel: parallel)), child: const Text('OK'))],
    )));
    if (result != null) {
      final clean = CookStep(
        title: result.title.trim().isEmpty ? result.type : result.title.trim(),
        type: result.type,
        minutes: result.minutes < 0 ? 0 : result.minutes,
        seconds: result.seconds.clamp(0, 59),
        temp: result.temp < 0 ? 0 : result.temp,
        note: result.note.trim(),
        videoUrl: result.videoUrl.trim(),
        imagePath: stepImage,
        parallel: result.parallel,
      );
      setState(() { if (index == null) { r.steps.add(clean); } else { r.steps[index] = clean; } });
      if (widget.recipe != null) widget.store.upsert(r);
    }
  }

  Future<void> editVideo({int? index}) async {
    final ctrl = TextEditingController(text: index == null ? '' : r.videos[index]);
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: Text(index == null ? 'Ajouter lien vidéo' : 'Modifier lien vidéo'),
      content: TextField(controller: ctrl, decoration: inputDecoration('YouTube, TikTok, Instagram...')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('OK'))],
    ));
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        if (index == null) {
          r.videos.add(result.trim());
        } else {
          r.videos[index] = result.trim();
        }
      });
      if (widget.recipe != null) widget.store.upsert(r);
    }
  }
}



class MultiTimerPage extends StatefulWidget {
  final Store store;
  final Recipe? recipe;
  const MultiTimerPage({super.key, required this.store, this.recipe});
  @override State<MultiTimerPage> createState()=>_MultiTimerPageState();
}
class _TimerItem { String title; int remaining; int total; Timer? timer; bool running=false; String type; _TimerItem(this.title,this.remaining,{this.type='Custom'}):total=remaining; }
class _MultiTimerPageState extends State<MultiTimerPage> {
  final items = <_TimerItem>[];
  @override void initState(){ super.initState(); final r=widget.recipe; if(r!=null){ for(final st in r.steps){ final sec=st.totalSeconds; if(sec>0){items.add(_TimerItem('${stepEmoji(st.type)} ${st.title}', sec, type: st.parallel?'Simultané':'Recette'));}} }}
  void addTimer(){ final title=TextEditingController(text:'Chauffer'); final min=TextEditingController(text:'5'); final sec=TextEditingController(text:'0'); String type='Custom'; final types=['Custom','Décongélation','Chauffer','Cuisson','Four','Repos']; showDialog(context: context, builder: (_)=>StatefulBuilder(builder:(context,setLocal)=>AlertDialog(title: const Text('Nouveau chrono'), content: SingleChildScrollView(child:Column(mainAxisSize: MainAxisSize.min, children:[DropdownButtonFormField<String>(value:type, items:types.map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setLocal(()=>type=v??type), decoration: inputDecoration('Type')), const SizedBox(height:8), TextField(controller:title, decoration: inputDecoration('Nom')), const SizedBox(height:8), Row(children:[Expanded(child:TextField(controller:min, keyboardType:TextInputType.number, decoration: inputDecoration('Min'))), const SizedBox(width:8), Expanded(child:TextField(controller:sec, keyboardType:TextInputType.number, decoration: inputDecoration('Sec')))])])), actions:[TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed:(){final total=(int.tryParse(min.text)??0)*60+(int.tryParse(sec.text)??0); if(total>0){setState(()=>items.add(_TimerItem(title.text,total,type:type)));} Navigator.pop(context);}, child: const Text('Ajouter'))]))); }
  void toggle(_TimerItem it){ if(it.running){it.timer?.cancel(); setState(()=>it.running=false); return;} setState(()=>it.running=true); it.timer=Timer.periodic(const Duration(seconds:1), (_){ if(it.remaining<=1){ it.timer?.cancel(); setState(()=>it.running=false); notifications.show(DateTime.now().millisecondsSinceEpoch%100000, 'Chrono terminé', it.title, const NotificationDetails(android: AndroidNotificationDetails('active_timers','Chronos actifs', importance: Importance.max, priority: Priority.high, fullScreenIntent: true))); } else { setState(()=>it.remaining--); }}); }
  @override void dispose(){ for(final it in items){it.timer?.cancel();} super.dispose(); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title: Text(widget.recipe==null?'Chronos actifs':'Chronos ${widget.recipe!.title}', style: const TextStyle(fontWeight:FontWeight.w900))), floatingActionButton: FloatingActionButton.extended(onPressed:addTimer, icon: const Icon(Icons.add), label: const Text('Chrono')), body: items.isEmpty?Center(child: premiumEmpty(Icons.timer_outlined,'Aucun chrono actif','Ajoute un chrono libre ou lance-les depuis une recette.')):ListView(padding: const EdgeInsets.fromLTRB(20,0,20,110), children:[premiumNote(Icons.timer_rounded,'Espace chronos actifs','Gère décongélation, cuisson, four, repos ou chauffage en même temps.'), ...items.map((it){final m=(it.remaining~/60).toString().padLeft(2,'0'); final sec=(it.remaining%60).toString().padLeft(2,'0'); final pct=it.total==0?0.0:it.remaining/it.total; return Container(margin: const EdgeInsets.only(bottom:12), padding: const EdgeInsets.all(16), decoration: soft(radius:24), child: Row(children:[CircularProgressIndicator(value:(pct.clamp(0.0,1.0) as double), color:C.gold, backgroundColor:C.blush), const SizedBox(width:14), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(it.title, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontWeight:FontWeight.w900)), Text(it.type, style: const TextStyle(color:C.muted, fontWeight:FontWeight.w700)), Text('$m:$sec', style: const TextStyle(fontSize:30, fontWeight:FontWeight.w900))])), IconButton.filledTonal(onPressed:()=>toggle(it), icon: Icon(it.running?Icons.pause_rounded:Icons.play_arrow_rounded)), IconButton(onPressed:()=>setState(()=>items.remove(it)), icon: const Icon(Icons.delete_outline_rounded))]));})]));
}

class CategoriesPage extends StatefulWidget { final Store store; const CategoriesPage({super.key, required this.store}); @override State<CategoriesPage> createState()=>_CategoriesPageState(); }
class _CategoriesPageState extends State<CategoriesPage>{
  void edit({String? old}){final c=TextEditingController(text:old??''); String icon=widget.store.categoryIcons[old]??categoryIconKey(old??'Autres'); final icons=['tagine','cake','dish','juice','bread','soup','salad','fish','meat','dessert','other']; showDialog(context:context,builder:(_)=>StatefulBuilder(builder:(context,setLocal)=>AlertDialog(title: Text(old==null?'Nouvelle catégorie':'Modifier catégorie'), content: Column(mainAxisSize:MainAxisSize.min, children:[TextField(controller:c, decoration: inputDecoration('Nom')), const SizedBox(height:10), DropdownButtonFormField<String>(value:icons.contains(icon)?icon:'other', items:icons.map((e)=>DropdownMenuItem(value:e, child:Row(children:[Icon(categoryIconFromKey(e), size:18), const SizedBox(width:8), Text(categoryIconLabel(e))]))).toList(), onChanged:(v)=>setLocal(()=>icon=v??icon), decoration: inputDecoration('Icône'))]), actions:[TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed:(){final v=c.text.trim(); if(v.isNotEmpty){setState((){ if(old!=null){ final i=widget.store.categories.indexOf(old); if(i!=-1) widget.store.categories[i]=v; widget.store.categoryIcons.remove(old); for(final r in widget.store.recipes){ if(r.category==old) r.category=v; } } else if(!widget.store.categories.contains(v)){ widget.store.categories.add(v); } widget.store.categoryIcons[v]=icon; widget.store.save();});} Navigator.pop(context);}, child: const Text('Enregistrer'))] ))); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title: const Text('Catégories', style: TextStyle(fontWeight:FontWeight.w900))), floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(), icon: const Icon(Icons.add), label: const Text('Catégorie')), body:ReorderableListView(padding: const EdgeInsets.fromLTRB(20,0,20,110), onReorder:(oldIndex,newIndex){setState((){if(newIndex>oldIndex)newIndex--; final item=widget.store.categories.removeAt(oldIndex); widget.store.categories.insert(newIndex,item); widget.store.save();});}, children:[for(final c in widget.store.categories) Container(key:ValueKey(c), margin: const EdgeInsets.only(bottom:10), decoration: soft(radius:22), child: ListTile(leading: Icon(categoryIconFromKey(widget.store.categoryIcons[c]??categoryIconKey(c)), color:C.green), title: Text(c, style: const TextStyle(fontWeight:FontWeight.w900)), subtitle: Text('${widget.store.recipes.where((r)=>r.category==c).length} recettes'), trailing: Wrap(children:[IconButton(icon: const Icon(Icons.edit_rounded), onPressed:()=>edit(old:c)), IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: widget.store.categories.length<=1?null:(){setState((){widget.store.categories.remove(c); widget.store.categoryIcons.remove(c); widget.store.save();});})])) )]));}

class MealPlannerPage extends StatefulWidget { final Store store; const MealPlannerPage({super.key, required this.store}); @override State<MealPlannerPage> createState()=>_MealPlannerPageState(); }
class _MealPlannerPageState extends State<MealPlannerPage>{ final days=['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche']; final meals=['Petit-déj','Déjeuner','Casse-croûte','Dîner']; @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title: const Text('Repas de la semaine', style: TextStyle(fontWeight:FontWeight.w900))), body:ListView(padding: const EdgeInsets.fromLTRB(20,0,20,110), children:[premiumNote(Icons.ac_unit_rounded,'Décongélation intelligente','Prévois les repas et note ce qu’il faut sortir du congélateur.'), for(final d in days) Container(margin: const EdgeInsets.only(bottom:12), padding: const EdgeInsets.all(14), decoration: soft(radius:24), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(d, style: const TextStyle(fontSize:18, fontWeight:FontWeight.w900)), for(final meal in meals) Padding(padding: const EdgeInsets.only(top:8), child: DropdownButtonFormField<String>(value: widget.store.mealPlan['$d-$meal'], items: [const DropdownMenuItem<String>(value:null, child:Text('Aucun')), ...widget.store.recipes.map((r)=>DropdownMenuItem(value:r.id, child:Text(r.title, overflow:TextOverflow.ellipsis)))], onChanged:(v){setState((){ if(v==null){widget.store.mealPlan.remove('$d-$meal');}else{widget.store.mealPlan['$d-$meal']=v;} widget.store.save();});}, decoration: inputDecoration(meal))), Builder(builder:(_){final ids=meals.map((m)=>widget.store.mealPlan['$d-$m']).whereType<String>(); final notes=ids.map((id)=>widget.store.byId(id)?.thawNote??'').where((e)=>e.isNotEmpty).toList(); return notes.isEmpty?const SizedBox.shrink():Padding(padding: const EdgeInsets.only(top:10), child: Text('À décongeler : ${notes.join(' • ')}', style: const TextStyle(color:C.terracotta, fontWeight:FontWeight.w800)));})]))])); }

class FavoritesPage extends StatelessWidget {
  final Store store;
  const FavoritesPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    final favs = store.recipes.where((e) => e.favorite).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris', style: TextStyle(fontWeight: FontWeight.w800))),
      body: favs.isEmpty
          ? Center(child: premiumEmpty(Icons.favorite_outline_rounded, 'Aucun favori', 'Ajoute tes recettes préférées ici.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 16, childAspectRatio: .70),
              itemCount: favs.length,
              itemBuilder: (_, i) => RecipeCard(store: store, recipe: favs[i]),
            ),
    );
  }
}

class MorePage extends StatelessWidget {
  final Store store;
  const MorePage({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
        premiumNote(Icons.card_giftcard_rounded, 'Cadeau premium', 'Recettes, alarmes, courses, conversions et sauvegarde dans une seule app.'),
        quickAction(context, Icons.insights_rounded, 'Dashboard', 'Statistiques et suivi cuisine', StatsPage(store: store)),
        quickAction(context, Icons.calendar_month_rounded, 'Repas de la semaine', 'Planning + rappels décongélation', MealPlannerPage(store: store)),
        quickAction(context, Icons.timer_rounded, 'Multi-compteurs', 'Plusieurs timers en même temps', MultiTimerPage(store: store)),
        quickAction(context, Icons.category_rounded, 'Catégories', 'Créer et organiser les rubriques', CategoriesPage(store: store)),
        quickAction(context, Icons.tune_rounded, 'Paramètres', 'Alarmes, écran allumé, unités et préférences', SettingsPage(store: store)),
        quickAction(context, Icons.straighten_rounded, 'Convertisseur mesures', 'Calculer verre, ml, litre, cuillères et farine', ConverterPage(store: store)),
        quickAction(context, Icons.backup_rounded, 'Sauvegarde', 'Exporter, importer ou restaurer les données', BackupInfoPage(store: store)),
      ]),
    );
  }
}

class ConverterPage extends StatefulWidget {
  final Store store;
  const ConverterPage({super.key, required this.store});
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final qty = TextEditingController(text: '1');
  String unit = 'verre';
  String ingredient = 'Liquide';
  String result = '';

  @override
  void initState() { super.initState(); calculate(); }

  void calculate() {
    final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
    final glass = widget.store.settings.glassMl.toDouble();
    double ml;
    switch (unit) {
      case 'litre': ml = q * 1000; break;
      case 'cuillère à soupe': ml = q * 15; break;
      case 'cuillère à café': ml = q * 5; break;
      case 'ml': ml = q; break;
      default: ml = q * glass;
    }
    if (ingredient == 'Farine') {
      final gramsLow = ml / glass * 120;
      final gramsHigh = ml / glass * 160;
      result = '≈ ${fmt(gramsLow)} à ${fmt(gramsHigh)} g de farine';
    } else if (ingredient == 'Sucre') {
      result = '≈ ${fmt(ml / glass * 180)} g de sucre';
    } else {
      result = '= ${fmt(ml)} ml = ${fmt(ml / 1000)} L = environ ${fmt(ml / glass)} verre(s)';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Convertisseur', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
          premiumNote(Icons.calculate_rounded, 'Calcul instantané', 'Le verre maison est réglé à ${widget.store.settings.glassMl} ml.'),
          TextField(controller: qty, keyboardType: TextInputType.number, onChanged: (_) => calculate(), decoration: inputDecoration('Quantité')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: unit, items: const ['verre','ml','litre','cuillère à soupe','cuillère à café'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged: (v){unit=v??unit;calculate();}, decoration: inputDecoration('Unité')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: ingredient, items: const ['Liquide','Farine','Sucre'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged: (v){ingredient=v??ingredient;calculate();}, decoration: inputDecoration('Type')),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(18), decoration: soft(radius: 26), child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: C.gold), const SizedBox(width: 12), Expanded(child: Text(result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))])),
          const SizedBox(height: 18),
          const SettingTile(icon: Icons.local_drink_rounded, title: 'Repères utiles', sub: '1 verre ≈ 200 ml par défaut · 1 L ≈ 5 verres · 1 càs ≈ 15 ml · 1 càc ≈ 5 ml'),
        ]),
      );
}

class BackupInfoPage extends StatelessWidget {
  final Store store;
  const BackupInfoPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sauvegarde', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
          SettingTile(icon: Icons.copy_all_rounded, title: 'Exporter en JSON', sub: 'Copie une sauvegarde complète dans le presse-papiers', onTap: () { Clipboard.setData(ClipboardData(text: store.exportJson())); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde copiée'))); }),
          SettingTile(icon: Icons.restore_page_rounded, title: 'Importer depuis JSON', sub: 'Coller une sauvegarde exportée auparavant', onTap: () => importBackupDialog(context, store)),
          SettingTile(icon: Icons.restart_alt_rounded, title: 'Restaurer les exemples', sub: 'Remettre les recettes de démonstration', onTap: () async { await store.resetSamples(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exemples restaurés'))); }),
          const SettingTile(icon: Icons.lock_rounded, title: 'Privé', sub: 'Les données restent dans ce téléphone pour cette version.'),
        ]),
      );
}

class StatsPage extends StatelessWidget {
  final Store store;
  const StatsPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    final total = store.recipes.length;
    final fav = store.recipes.where((e) => e.favorite).length;
    final steps = store.recipes.fold<int>(0, (a, b) => a + b.steps.length);
    final minutes = store.recipes.fold<int>(0, (a, b) => a + b.minutes);
    final ingredients = store.recipes.fold<int>(0, (a, b) => a + b.ingredients.length);
    final videos = store.recipes.fold<int>(0, (a, b) => a + b.videos.length);
    final sorted = [...store.recipes]..sort((a,b)=>b.rating.compareTo(a.rating));
    final top = sorted.isEmpty ? null : sorted.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
        Row(children: [statBox('Recettes', '$total', Icons.restaurant_rounded), statBox('Favoris', '$fav', Icons.favorite_rounded)]),
        Row(children: [statBox('Étapes', '$steps', Icons.checklist_rounded), statBox('Alarmes', '$steps', Icons.alarm_rounded)]),
        Row(children: [statBox('Minutes', '${minutes}m', Icons.schedule_rounded), statBox('Ingrédients', '$ingredients', Icons.kitchen_rounded)]),
        Row(children: [statBox('Vidéos', '$videos', Icons.play_circle_rounded), statBox('Moyenne', total==0?'0m':'${(minutes/total).round()}m', Icons.analytics_rounded)]),
        if (top != null) premiumNote(Icons.star_rounded, 'Top recette', '${top.title} · ${top.rating}/5 · ${top.minutes} min'),
        premiumNote(Icons.auto_awesome_rounded, 'Conseil premium', 'Ajoute une note anti-brûlure à chaque étape importante : remuer, baisser le feu, vérifier l’eau.'),
      ]),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Store store;
  const SettingsPage({super.key, required this.store});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> save() async { await widget.store.save(); if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) {
    final st = widget.store.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
        SwitchTile(icon: Icons.notifications_active_rounded, title: 'Alarmes anti-brûlure', sub: 'Notification et alerte après le timer', value: st.showFullScreen, onChanged: (v){st.showFullScreen=v;save();}),
        SwitchTile(icon: Icons.volume_up_rounded, title: 'Sonnerie', sub: 'Son actif pour éviter les oublis', value: st.alarmSound, onChanged: (v){st.alarmSound=v;save();}),
        SwitchTile(icon: Icons.vibration_rounded, title: 'Vibration', sub: 'Vibre quand le temps est terminé', value: st.vibration, onChanged: (v){st.vibration=v;save();}),
        SwitchTile(icon: Icons.phone_iphone_rounded, title: 'Écran allumé', sub: 'Le mode cuisson garde l’écran actif', value: st.keepAwake, onChanged: (v){st.keepAwake=v;save();}),
        SwitchTile(icon: Icons.repeat_rounded, title: 'Rappel alarme', sub: 'Répéter si la cuisson n’est pas confirmée', value: st.repeatAlarm, onChanged: (v){st.repeatAlarm=v;save();}),
        SwitchTile(icon: Icons.ac_unit_rounded, title: 'Rappels décongélation', sub: 'Prévenir quoi sortir du congélateur', value: st.thawNotifications, onChanged: (v){st.thawNotifications=v;save();}),
        SwitchTile(icon: Icons.backup_rounded, title: 'Sauvegarde auto', sub: 'Créer une sauvegarde locale après chaque modification', value: st.autoBackup, onChanged: (v){st.autoBackup=v;save();}),
        SwitchTile(icon: Icons.timer_rounded, title: 'Chronos custom', sub: 'Décongeler, chauffer, four, repos sans recette', value: st.enableCustomTimers, onChanged: (v){st.enableCustomTimers=v;save();}),
        SwitchTile(icon: Icons.restaurant_rounded, title: 'Chronos par repas', sub: 'Afficher les chronos actifs liés aux recettes', value: st.showMealTimers, onChanged: (v){st.showMealTimers=v;save();}),
        SettingTile(icon: Icons.local_drink_rounded, title: 'Taille du verre maison', sub: '${st.glassMl} ml', onTap: () => editGlassMl(context, widget.store, () => setState(() {}))),
        SettingTile(icon: Icons.add_alarm_rounded, title: 'Rallonge par défaut', sub: '+${st.defaultExtraMinutes} min', onTap: () => editDefaultExtra(context, widget.store, () => setState(() {}))),
        SettingTile(icon: Icons.music_note_rounded, title: 'Sonnerie alarme', sub: st.alarmTone, onTap: () => editAlarmTone(context, widget.store, () => setState(() {}))),
        SettingTile(icon: Icons.palette_rounded, title: 'Couleurs', sub: st.themeName, onTap: () => editThemeName(context, widget.store, () => setState(() {}))),
        SettingTile(icon: Icons.shopping_basket_rounded, title: 'Courses', sub: 'Exporter seulement les ingrédients manquants', onTap: () => infoDialog(context, 'Courses', 'Dans Liste de courses, coche ce que tu as déjà. L’export contient seulement le reste.')),
        SettingTile(icon: Icons.image_rounded, title: 'Images', sub: 'Sélection depuis la galerie du téléphone', onTap: () => infoDialog(context, 'Images', 'Utilise Modifier recette puis touche l’image pour choisir une photo.')),
      ]),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  const SettingTile({super.key, required this.icon, required this.title, required this.sub, this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: soft(radius: 24),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: C.green),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(sub),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        ),
      );
}

class SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SwitchTile({super.key, required this.icon, required this.title, required this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: soft(radius: 24),
        child: SwitchListTile(
          secondary: Icon(icon, color: C.green),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(sub),
          value: value,
          activeColor: C.green,
          onChanged: onChanged,
        ),
      );
}

Future<void> infoDialog(BuildContext context, String title, String message) async {
  await showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
}

Future<void> editGlassMl(BuildContext context, Store store, VoidCallback refresh) async {
  final ctrl = TextEditingController(text: store.settings.glassMl.toString());
  final v = await showDialog<int>(context: context, builder: (_) => AlertDialog(
    title: const Text('Taille du verre maison'),
    content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: inputDecoration('ml par verre')),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)), child: const Text('Enregistrer'))],
  ));
  if (v != null && v > 0) { store.settings.glassMl = v; await store.save(); refresh(); }
}


Future<void> editDefaultExtra(BuildContext context, Store store, VoidCallback refresh) async {
  final ctrl = TextEditingController(text: store.settings.defaultExtraMinutes.toString());
  final v = await showDialog<int>(context: context, builder: (_) => AlertDialog(
    title: const Text('Rallonge par défaut'),
    content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: inputDecoration('Minutes')),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)), child: const Text('Enregistrer'))],
  ));
  if (v != null && v >= 0) { store.settings.defaultExtraMinutes = v; await store.save(); refresh(); }
}

Future<void> importBackupDialog(BuildContext context, Store store) async {
  final ctrl = TextEditingController();
  final raw = await showDialog<String>(context: context, builder: (_) => AlertDialog(
    title: const Text('Importer sauvegarde'),
    content: TextField(controller: ctrl, minLines: 4, maxLines: 8, decoration: inputDecoration('Coller JSON ici')),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Importer'))],
  ));
  if (raw == null || raw.trim().isEmpty) return;
  try {
    final ok = await store.importJson(raw);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Sauvegarde importée' : 'Format invalide')));
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON invalide')));
  }
}

Widget quickAction(BuildContext context, IconData icon, String title, String sub, Widget page) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: soft(radius: 24),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: C.green)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );

Widget premiumEmpty(IconData icon, String title, String sub) => Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 82, height: 82, decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(28)), child: Icon(icon, size: 38, color: C.green)),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.ink)),
        const SizedBox(height: 8),
        Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
      ]),
    );

class RecipeImage extends StatelessWidget {
  final Recipe recipe;
  final double radius;
  final double? height;
  final VoidCallback? onTap;
  const RecipeImage({super.key, required this.recipe, this.radius = 28, this.height, this.onTap});
  @override
  Widget build(BuildContext context) {
    final has = recipe.imagePath.isNotEmpty && File(recipe.imagePath).existsSync();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), gradient: foodGradient(recipe.category)),
        clipBehavior: Clip.antiAlias,
        child: has
            ? Image.file(File(recipe.imagePath), fit: BoxFit.cover, width: double.infinity)
            : Stack(fit: StackFit.expand, children: [
                CustomPaint(painter: FoodArtPainter(category: recipe.category)),
                if (onTap != null) const Center(child: Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 44)),
              ]),
      ),
    );
  }
}

class FoodArtPainter extends CustomPainter {
  final String category;
  FoodArtPainter({required this.category});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(.20);
    canvas.drawCircle(Offset(size.width * .2, size.height * .2), 70, p);
    canvas.drawCircle(Offset(size.width * .84, size.height * .78), 90, p);
    final icon = category == 'Desserts' || category == 'Gâteaux' ? '🍰' : category == 'Jus' ? '🥤' : '🥘';
    final tp = TextPainter(text: TextSpan(text: icon, style: const TextStyle(fontSize: 54)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<bool?> openEditor(BuildContext context, Store store, {Recipe? recipe}) {
  return Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RecipeEditorPage(store: store, recipe: recipe)));
}


IconData unitIcon(String u){
  if(u.contains('verre')||u=='ml'||u=='L') return Icons.local_drink_rounded;
  if(u.contains('cuillère')) return Icons.soup_kitchen_rounded;
  if(u.contains('pinc')) return Icons.grain_rounded;
  if(u.contains('pièce')) return Icons.circle_outlined;
  if(u=='kg'||u=='g') return Icons.scale_rounded;
  return Icons.straighten_rounded;
}
IconData stepTypeIcon(String t){
  switch(t){
    case 'Couper': return Icons.content_cut_rounded;
    case 'Éplucher': return Icons.spa_rounded;
    case 'Mixer': return Icons.blender_rounded;
    case 'Mariner': return Icons.hourglass_bottom_rounded;
    case 'Repos': return Icons.hotel_rounded;
    case 'Four': return Icons.local_fire_department_rounded;
    case 'Friture': return Icons.oil_barrel_rounded;
    case 'Vapeur': return Icons.cloud_rounded;
    case 'Décongélation': return Icons.ac_unit_rounded;
    case 'Dressage': return Icons.restaurant_rounded;
    default: return Icons.timer_rounded;
  }
}
String guessIngredientIcon(String name){
  final n=name.toLowerCase();
  if(n.contains('poulet')) return 'chicken'; if(n.contains('viande')||n.contains('bœuf')||n.contains('boeuf')) return 'meat'; if(n.contains('poisson')) return 'fish'; if(n.contains('œuf')||n.contains('oeuf')) return 'egg'; if(n.contains('lait')) return 'milk'; if(n.contains('farine')) return 'flour'; if(n.contains('sucre')) return 'sugar'; if(n.contains('huile')) return 'oil'; if(n.contains('eau')) return 'water'; if(n.contains('oignon')) return 'onion'; if(n.contains('tomate')) return 'tomato'; if(n.contains('pomme')) return 'potato'; if(n.contains('carotte')) return 'carrot'; if(n.contains('citron')) return 'lemon'; if(n.contains('olive')) return 'olive'; if(n.contains('safran')||n.contains('épice')||n.contains('epice')) return 'spice';
  return 'restaurant';
}
IconData ingredientIcon(String key){
  switch(key){
    case 'chicken': return Icons.set_meal_rounded;
    case 'meat': return Icons.dining_rounded;
    case 'fish': return Icons.set_meal_rounded;
    case 'egg': return Icons.egg_alt_rounded;
    case 'milk': return Icons.local_drink_rounded;
    case 'flour': return Icons.grass_rounded;
    case 'sugar': return Icons.cake_rounded;
    case 'oil': return Icons.water_drop_rounded;
    case 'water': return Icons.opacity_rounded;
    case 'onion': return Icons.spa_rounded;
    case 'tomato': return Icons.circle_rounded;
    case 'potato': return Icons.agriculture_rounded;
    case 'carrot': return Icons.eco_rounded;
    case 'lemon': return Icons.circle_outlined;
    case 'olive': return Icons.scatter_plot_rounded;
    case 'spice': return Icons.auto_awesome_rounded;
    default: return Icons.restaurant_rounded;
  }
}
String iconLabel(String key)=>{
  'restaurant':'Général','chicken':'Poulet','meat':'Viande','fish':'Poisson','egg':'Œuf','milk':'Lait','flour':'Farine','sugar':'Sucre','oil':'Huile','water':'Eau','onion':'Oignon','tomato':'Tomate','potato':'Pomme de terre','carrot':'Carotte','lemon':'Citron','olive':'Olive','spice':'Épices'
}[key]??key;

IconData _catIcon(String c) {
  switch (c) {
    case 'Tajines': return Icons.soup_kitchen_rounded;
    case 'Desserts': return Icons.cake_rounded;
    case 'Gâteaux': return Icons.bakery_dining_rounded;
    case 'Jus': return Icons.local_drink_rounded;
    default: return Icons.restaurant_rounded;
  }
}

LinearGradient foodGradient(String c) {
  if (c == 'Desserts' || c == 'Gâteaux') return const LinearGradient(colors: [Color(0xFFF1C873), Color(0xFFDFA184)]);
  if (c == 'Jus') return const LinearGradient(colors: [Color(0xFFB7C8A9), Color(0xFFF0CF84)]);
  return const LinearGradient(colors: [Color(0xFF6D8069), Color(0xFFCDA27B)]);
}

BoxDecoration soft({double radius = 24}) => BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(radius), boxShadow: shadow());
List<BoxShadow> shadow() => [BoxShadow(color: Colors.black.withOpacity(.045), blurRadius: 24, offset: const Offset(0, 12))];

Widget miniPill(String text, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: C.green), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: C.ink))]),
    );

Widget infoTile(IconData icon, String label) => Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: soft(radius: 20),
        child: Column(children: [Icon(icon, color: C.green, size: 22), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))]),
      ),
    );

Widget premiumNote(IconData icon, String title, String sub) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.green.withOpacity(.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: C.green.withOpacity(.08))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: C.green), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: C.ink)), const SizedBox(height: 4), Text(sub, style: const TextStyle(color: C.muted, height: 1.3, fontWeight: FontWeight.w700))]))]),
    );

Widget ingredientRow(Ingredient i) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: soft(radius: 20),
      child: Row(children: [Icon(ingredientIcon(i.icon.isEmpty ? guessIngredientIcon(i.name) : i.icon), color: C.sage), const SizedBox(width: 10), Expanded(child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w900))), Icon(unitIcon(i.unit), size: 18, color: C.muted), const SizedBox(width: 5), Text('${fmt(i.qty)} ${i.unit}', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900))]),
    );

Widget stepRow(int index, CookStep s) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: soft(radius: 22),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: C.green, foregroundColor: Colors.white, radius: 16, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 6), Wrap(spacing: 7, runSpacing: 7, children: [miniPill(s.type, stepTypeIcon(s.type)), miniPill(s.seconds > 0 ? '${s.minutes}m ${s.seconds}s' : '${s.minutes} min', Icons.schedule_rounded), if (s.temp > 0) miniPill('${s.temp}°C', Icons.thermostat_rounded), if (s.parallel) miniPill('en parallèle', Icons.call_split_rounded)]), if (s.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.note, style: const TextStyle(color: C.terracotta, height: 1.3, fontWeight: FontWeight.w700)))])),
      ]),
    );

Widget sectionHeader(String title, VoidCallback onAdd) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))), IconButton.filledTonal(onPressed: onAdd, icon: const Icon(Icons.add_rounded))]),
    );

Widget editorTile(String title, String sub, VoidCallback edit, VoidCallback delete) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: soft(radius: 22),
      child: ListTile(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: edit, trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.red), onPressed: delete)),
    );


Widget stepEditorTile(int index, CookStep s, VoidCallback edit, VoidCallback delete, VoidCallback? up, VoidCallback? down) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: soft(radius: 22),
      child: ListTile(
        leading: Icon(stepTypeIcon(s.type), color: C.green),
        title: Text('Étape ${index + 1} · ${s.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${s.type} · ${s.seconds > 0 ? '${s.minutes}m ${s.seconds}s' : '${s.minutes} min'}${s.parallel ? ' · parallèle' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: edit,
        trailing: Wrap(spacing: 2, children: [
          IconButton(onPressed: up, icon: const Icon(Icons.keyboard_arrow_up_rounded)),
          IconButton(onPressed: down, icon: const Icon(Icons.keyboard_arrow_down_rounded)),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.red), onPressed: delete),
        ]),
      ),
    );

Widget statBox(String title, String value, IconData icon) => Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10, bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: soft(radius: 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: C.green), const SizedBox(height: 16), Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800))]),
      ),
    );

InputDecoration inputDecoration(String label) => InputDecoration(labelText: label, filled: true, fillColor: C.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: C.green, width: 1.4)));

ButtonStyle mainButtonStyle() => FilledButton.styleFrom(backgroundColor: C.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), textStyle: const TextStyle(fontWeight: FontWeight.w800));

String fmt(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

void exportMissing(BuildContext context, Recipe r) {
  final missing = r.ingredients.where((e) => !e.have).map((e) => '- ${e.name}: ${fmt(e.qty)} ${e.unit}').join('\n');
  final text = missing.isEmpty ? 'Rien ne manque ✅' : 'Liste de courses - ${r.title}\n\n$missing';
  Clipboard.setData(ClipboardData(text: text));
  showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Liste copiée'), content: Text(text), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
}


String categoryIconKey(String c){ final x=c.toLowerCase(); if(x.contains('taj')) return 'tagine'; if(x.contains('gâteau')||x.contains('dessert')) return 'cake'; if(x.contains('jus')) return 'juice'; if(x.contains('pain')) return 'bread'; if(x.contains('soupe')) return 'soup'; if(x.contains('salade')) return 'salad'; if(x.contains('poisson')) return 'fish'; if(x.contains('viande')) return 'meat'; if(x.contains('plat')) return 'dish'; return 'other'; }
IconData categoryIconFromKey(String k){ switch(k){case 'tagine': return Icons.soup_kitchen_rounded; case 'cake': return Icons.cake_rounded; case 'juice': return Icons.local_drink_rounded; case 'bread': return Icons.bakery_dining_rounded; case 'soup': return Icons.ramen_dining_rounded; case 'salad': return Icons.eco_rounded; case 'fish': return Icons.set_meal_rounded; case 'meat': return Icons.dinner_dining_rounded; case 'dish': return Icons.restaurant_rounded; default: return Icons.category_rounded;} }
String categoryIconLabel(String k){ switch(k){case 'tagine': return 'Tajine'; case 'cake': return 'Gâteau/Dessert'; case 'juice': return 'Jus'; case 'bread': return 'Pain'; case 'soup': return 'Soupe'; case 'salad': return 'Salade'; case 'fish': return 'Poisson'; case 'meat': return 'Viande'; case 'dish': return 'Plat'; default: return 'Autre';} }
String stepEmoji(String type){ switch(type){case 'Couper': return '🔪'; case 'Éplucher': return '🥕'; case 'Mixer': return '🌀'; case 'Mariner': return '🧂'; case 'Four': return '🔥'; case 'Friture': return '🍳'; case 'Décongélation': return '❄️'; case 'Repos': return '⏳'; default: return '⏱';} }
Future<void> editAlarmTone(BuildContext context, Store store, VoidCallback refresh) async { final tones=['Fort classique','Doux cuisine','Urgent anti-brûlure','Vibration seulement']; final choice=await showModalBottomSheet<String>(context: context, builder:(_)=>SafeArea(child: ListView(padding: const EdgeInsets.all(18), children:[const Text('Sonnerie alarme', style: TextStyle(fontSize:22,fontWeight:FontWeight.w900)), ...tones.map((t)=>ListTile(leading: Icon(t==store.settings.alarmTone?Icons.radio_button_checked:Icons.radio_button_off, color:C.green), title:Text(t), onTap:()=>Navigator.pop(context,t)))]))); if(choice!=null){store.settings.alarmTone=choice; await store.save(); refresh();}}
Future<void> editThemeName(BuildContext context, Store store, VoidCallback refresh) async { final themes=['Crème sauge','Crème terracotta','Olive doux','Doré cuisine','Clair minimal']; final choice=await showModalBottomSheet<String>(context: context, builder:(_)=>SafeArea(child: ListView(padding: const EdgeInsets.all(18), children:[const Text('Palette couleurs', style: TextStyle(fontSize:22,fontWeight:FontWeight.w900)), ...themes.map((t)=>ListTile(leading: Icon(t==store.settings.themeName?Icons.check_circle:Icons.palette_outlined, color:C.green), title:Text(t), subtitle: const Text('Appliquée aux prochaines versions UI'), onTap:()=>Navigator.pop(context,t)))]))); if(choice!=null){store.settings.themeName=choice; await store.save(); refresh();}}
