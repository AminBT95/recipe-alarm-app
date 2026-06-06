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
  Ingredient({required this.name, required this.qty, required this.unit, this.have = false});
  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'unit': unit, 'have': have};
  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: j['name'] ?? '',
        qty: (j['qty'] as num? ?? 0).toDouble(),
        unit: j['unit'] ?? '',
        have: j['have'] ?? false,
      );
}

class CookStep {
  String title;
  int minutes;
  int temp;
  String note;
  CookStep({required this.title, required this.minutes, required this.temp, required this.note});
  Map<String, dynamic> toJson() => {'title': title, 'minutes': minutes, 'temp': temp, 'note': note};
  factory CookStep.fromJson(Map<String, dynamic> j) => CookStep(
        title: j['title'] ?? '',
        minutes: j['minutes'] ?? 0,
        temp: j['temp'] ?? 0,
        note: j['note'] ?? '',
      );
}

class Recipe {
  String id;
  String title;
  String category;
  String imagePath;
  String difficulty;
  String liquidNote;
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

class Store extends ChangeNotifier {
  List<Recipe> recipes = [];

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('recipes_v2');
    if (raw == null) {
      recipes = [sampleRecipe(), sampleDessert()];
      await save();
    } else {
      recipes = (jsonDecode(raw) as List).map((e) => Recipe.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('recipes_v2', jsonEncode(recipes.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void upsert(Recipe recipe) {
    final index = recipes.indexWhere((e) => e.id == recipe.id);
    if (index == -1) {
      recipes.insert(0, recipe);
    } else {
      recipes[index] = recipe;
    }
    save();
  }

  void remove(Recipe recipe) {
    recipes.removeWhere((e) => e.id == recipe.id);
    save();
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
  final cats = const ['Tous', 'Tajines', 'Desserts', 'Plats', 'Gâteaux', 'Jus'];

  @override
  Widget build(BuildContext context) {
    final list = widget.store.recipes.where((r) {
      final matchQuery = r.title.toLowerCase().contains(query.toLowerCase()) || r.category.toLowerCase().contains(query.toLowerCase());
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

class DetailPage extends StatelessWidget {
  final Store store;
  final Recipe recipe;
  const DetailPage({super.key, required this.store, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 310,
          pinned: true,
          backgroundColor: C.cream,
          actions: [
            IconButton.filledTonal(onPressed: () => openEditor(context, store, recipe: recipe), icon: const Icon(Icons.edit_rounded)),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(background: Padding(padding: const EdgeInsets.fromLTRB(16, 70, 16, 18), child: RecipeImage(recipe: recipe, radius: 34))),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
          sliver: SliverList.list(children: [
            Text(recipe.title, style: const TextStyle(fontSize: 26, height: 1.08, fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 9),
            Row(children: [
              const Icon(Icons.star_rounded, color: C.gold),
              Text(' ${recipe.rating}/5', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Text(recipe.category, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              infoTile(Icons.schedule_rounded, '${recipe.minutes} min'),
              infoTile(Icons.people_alt_rounded, '${recipe.servings} pers.'),
              infoTile(Icons.thermostat_rounded, '${recipe.temp}°C'),
              infoTile(Icons.signal_cellular_alt_rounded, recipe.difficulty),
            ]),
            const SizedBox(height: 18),
            if (recipe.liquidNote.isNotEmpty) premiumNote(Icons.water_drop_rounded, 'Liquide conseillé', recipe.liquidNote),
            _title('Ingrédients'),
            ...recipe.ingredients.map((i) => ingredientRow(i)),
            _title('Étapes de cuisson'),
            ...recipe.steps.asMap().entries.map((e) => stepRow(e.key, e.value)),
            if (recipe.videos.isNotEmpty) _title('Vidéos'),
            ...recipe.videos.map((v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_circle_fill_rounded, color: C.terracotta),
                  title: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () => launchUrl(Uri.parse(v), mode: LaunchMode.externalApplication),
                )),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: recipe.steps.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CookingPage(recipe: recipe))),
              icon: const Icon(Icons.local_fire_department_rounded),
              label: const Text('Commencer la cuisson'),
              style: FilledButton.styleFrom(backgroundColor: C.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShoppingPage(store: store, recipe: recipe))),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Liste de courses'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _title(String t) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 10), child: Text(t, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.ink)));
}

class CookingPage extends StatefulWidget {
  final Recipe recipe;
  const CookingPage({super.key, required this.recipe});
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
    total = (step.minutes <= 0 ? 1 : step.minutes * 60);
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
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 700, 300, 900, 300, 1000]);
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'burn_alarm',
        'Alarmes cuisson',
        channelDescription: 'Alarmes anti-brûlure pour les recettes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        fullScreenIntent: true,
      ),
    );
    await notifications.show(99, 'Temps écoulé', step.note.isEmpty ? 'Vérifie la cuisson maintenant.' : step.note, details);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AlarmSheet(note: step.note, onMore: () {
        Navigator.pop(context);
        setState(() {
          remaining = 5 * 60;
          total = 5 * 60;
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
                  miniPill('${step.minutes} min', Icons.schedule_rounded),
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
  final VoidCallback onMore;
  const AlarmSheet({super.key, required this.note, required this.onMore});
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
          TextButton(onPressed: onMore, child: const Text('+5 minutes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
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
  Recipe? selected;
  @override
  void initState() {
    super.initState();
    selected = widget.recipe ?? (widget.store.recipes.isEmpty ? null : widget.store.recipes.first);
  }

  @override
  Widget build(BuildContext context) {
    final r = selected;
    return Scaffold(
      appBar: AppBar(title: const Text('Liste de courses', style: TextStyle(fontWeight: FontWeight.w900))),
      body: r == null
          ? const Center(child: Text('Aucune recette'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              children: [
                DropdownButtonFormField<Recipe>(
                  value: r,
                  items: widget.store.recipes.map((e) => DropdownMenuItem(value: e, child: Text(e.title))).toList(),
                  onChanged: (v) => setState(() => selected = v),
                  decoration: inputDecoration('Choisir une recette'),
                ),
                const SizedBox(height: 18),
                premiumNote(Icons.checklist_rounded, 'Coche ce que tu as déjà', 'L’export contient seulement les ingrédients manquants.'),
                const SizedBox(height: 10),
                ...r.ingredients.map((i) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: soft(radius: 22),
                      child: CheckboxListTile(
                        value: i.have,
                        activeColor: C.green,
                        title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('${fmt(i.qty)} ${i.unit}'),
                        onChanged: (v) {
                          setState(() => i.have = v ?? false);
                          widget.store.save();
                        },
                      ),
                    )),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => exportMissing(context, r),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Exporter les ingrédients manquants'),
                  style: mainButtonStyle(),
                ),
              ],
            ),
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
          field('Catégorie', r.category, (v) => r.category = v),
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
          sectionHeader('Ingrédients', () => editIngredient()),
          ...r.ingredients.asMap().entries.map((e) => editorTile(e.value.name, '${fmt(e.value.qty)} ${e.value.unit}', () => editIngredient(index: e.key), () => setState(() => r.ingredients.removeAt(e.key)))),
          sectionHeader('Étapes', () => editStep()),
          ...r.steps.asMap().entries.map((e) => editorTile('Étape ${e.key + 1} · ${e.value.title}', '${e.value.minutes} min · ${e.value.temp}°C', () => editStep(index: e.key), () => setState(() => r.steps.removeAt(e.key)))),
          sectionHeader('Liens vidéos', () => editVideo()),
          ...r.videos.asMap().entries.map((e) => editorTile('Vidéo ${e.key + 1}', e.value, () => editVideo(index: e.key), () => setState(() => r.videos.removeAt(e.key)))),
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
    Navigator.pop(context);
  }

  Future<void> editIngredient({int? index}) async {
    final current = index == null ? Ingredient(name: '', qty: 1, unit: 'g') : r.ingredients[index];
    final name = TextEditingController(text: current.name);
    final qty = TextEditingController(text: fmt(current.qty));
    final unit = TextEditingController(text: current.unit);
    final result = await showDialog<Ingredient>(context: context, builder: (_) => AlertDialog(
      title: Text(index == null ? 'Ajouter ingrédient' : 'Modifier ingrédient'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: inputDecoration('Nom')),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: qty, keyboardType: TextInputType.number, decoration: inputDecoration('Quantité'))), const SizedBox(width: 8), Expanded(child: TextField(controller: unit, decoration: inputDecoration('Unité')))]),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, Ingredient(name: name.text, qty: double.tryParse(qty.text.replaceAll(',', '.')) ?? 1, unit: unit.text)), child: const Text('OK'))],
    ));
    if (result != null) {
      setState(() {
        if (index == null) {
          r.ingredients.add(result);
        } else {
          r.ingredients[index] = result;
        }
      });
      if (widget.recipe != null) widget.store.upsert(r);
    }
  }

  Future<void> editStep({int? index}) async {
    final current = index == null ? CookStep(title: '', minutes: 5, temp: r.temp, note: '') : r.steps[index];
    final title = TextEditingController(text: current.title);
    final min = TextEditingController(text: current.minutes.toString());
    final temp = TextEditingController(text: current.temp.toString());
    final note = TextEditingController(text: current.note);
    final result = await showDialog<CookStep>(context: context, builder: (_) => AlertDialog(
      title: Text(index == null ? 'Ajouter étape' : 'Modifier étape'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: inputDecoration('Titre étape')),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: min, keyboardType: TextInputType.number, decoration: inputDecoration('Minutes'))), const SizedBox(width: 8), Expanded(child: TextField(controller: temp, keyboardType: TextInputType.number, decoration: inputDecoration('°C')))]),
        const SizedBox(height: 10),
        TextField(controller: note, minLines: 2, maxLines: 4, decoration: inputDecoration('Note anti-brûlure')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, CookStep(title: title.text, minutes: int.tryParse(min.text) ?? 5, temp: int.tryParse(temp.text) ?? 0, note: note.text)), child: const Text('OK'))],
    ));
    if (result != null) {
      final clean = CookStep(
        title: result.title.trim().isEmpty ? 'Nouvelle étape' : result.title.trim(),
        minutes: result.minutes <= 0 ? 1 : result.minutes,
        temp: result.temp < 0 ? 0 : result.temp,
        note: result.note.trim(),
      );
      setState(() {
        if (index == null) {
          r.steps.add(clean);
        } else {
          r.steps[index] = clean;
        }
      });
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
        premiumNote(Icons.card_giftcard_rounded, 'Cadeau premium', 'Une app simple pour sauvegarder, cuisiner et éviter les oublis grâce aux alarmes.'),
        quickAction(context, Icons.insights_rounded, 'Dashboard', 'Recettes, favoris, étapes et alarmes', StatsPage(store: store)),
        quickAction(context, Icons.tune_rounded, 'Paramètres', 'Alarmes, mesures, sauvegarde et apparence', SettingsPage(store: store)),
        quickAction(context, Icons.straighten_rounded, 'Convertisseur mesures', 'Verre, litre, ml et cuillères', const ConverterPage()),
        quickAction(context, Icons.backup_rounded, 'Sauvegarde', 'Les données sont sauvegardées localement', const BackupInfoPage()),
      ]),
    );
  }
}

class ConverterPage extends StatelessWidget {
  const ConverterPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Convertisseur', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: const [
          SettingTile(icon: Icons.local_drink_rounded, title: '1 verre', sub: '≈ 200 ml selon le verre maison'),
          SettingTile(icon: Icons.water_drop_rounded, title: '1 litre', sub: '= 1000 ml = environ 5 verres'),
          SettingTile(icon: Icons.soup_kitchen_rounded, title: '1 cuillère à soupe', sub: '≈ 15 ml'),
          SettingTile(icon: Icons.coffee_rounded, title: '1 cuillère à café', sub: '≈ 5 ml'),
          SettingTile(icon: Icons.bakery_dining_rounded, title: 'Farine', sub: '1 verre ≈ 120 à 160 g selon densité'),
        ]),
      );
}

class BackupInfoPage extends StatelessWidget {
  const BackupInfoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sauvegarde', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: const [
          SettingTile(icon: Icons.phone_android_rounded, title: 'Sauvegarde locale', sub: 'Les recettes restent dans ce téléphone.'),
          SettingTile(icon: Icons.lock_rounded, title: 'Privé', sub: 'Aucun compte obligatoire pour cette version.'),
          SettingTile(icon: Icons.cloud_queue_rounded, title: 'Cloud plus tard', sub: 'On pourra ajouter Google Drive/Firebase ensuite.'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: [
        Row(children: [statBox('Recettes', '$total', Icons.restaurant_rounded), statBox('Favoris', '$fav', Icons.favorite_rounded)]),
        Row(children: [statBox('Étapes', '$steps', Icons.checklist_rounded), statBox('Alarmes', '$steps', Icons.alarm_rounded)]),
        premiumNote(Icons.auto_awesome_rounded, 'Conseil premium', 'Ajoute une note anti-brûlure à chaque étape importante : remuer, baisser le feu, vérifier l’eau.'),
      ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final Store store;
  const SettingsPage({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), children: const [
        SettingTile(icon: Icons.notifications_active_rounded, title: 'Alarmes anti-brûlure', sub: 'Sonnerie, vibration, plein écran et rappel +5 minutes'),
        SettingTile(icon: Icons.volume_up_rounded, title: 'Sonnerie', sub: 'Son fort par défaut pour éviter les oublis'),
        SettingTile(icon: Icons.phone_iphone_rounded, title: 'Écran allumé', sub: 'Le mode cuisson garde l’écran actif'),
        SettingTile(icon: Icons.palette_rounded, title: 'Couleurs', sub: 'Crème, sauge, terracotta et doré doux'),
        SettingTile(icon: Icons.straighten_rounded, title: 'Unités', sub: 'g, kg, ml, L, verre, cuillère, pièce, pincée'),
        SettingTile(icon: Icons.shopping_basket_rounded, title: 'Courses', sub: 'Exporter seulement les ingrédients manquants'),
        SettingTile(icon: Icons.image_rounded, title: 'Images', sub: 'Sélection depuis la galerie du téléphone'),
        SettingTile(icon: Icons.backup_rounded, title: 'Sauvegarde locale', sub: 'Les recettes restent dans le téléphone'),
      ]),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const SettingTile({super.key, required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: soft(radius: 24),
        child: ListTile(leading: Icon(icon, color: C.green), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right_rounded)),
      );
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

void openEditor(BuildContext context, Store store, {Recipe? recipe}) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeEditorPage(store: store, recipe: recipe)));
}

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
      child: Row(children: [const Icon(Icons.check_circle_outline_rounded, color: C.sage), const SizedBox(width: 10), Expanded(child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w900))), Text('${fmt(i.qty)} ${i.unit}', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900))]),
    );

Widget stepRow(int index, CookStep s) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: soft(radius: 22),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: C.green, foregroundColor: Colors.white, radius: 16, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 6), Text('${s.minutes} min${s.temp > 0 ? ' · ${s.temp}°C' : ''}', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800)), if (s.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s.note, style: const TextStyle(color: C.terracotta, height: 1.3, fontWeight: FontWeight.w700)))])),
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
