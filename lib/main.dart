import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
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
  tzdata.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone));
  } catch (_) {}
  runApp(const RecetteAlarmApp());
}

class C {
  static const cream = Color(0xFFF7F4EE);
  static const card = Color(0xFFFFFDF9);
  static const ink = Color(0xFF17201C);
  static const muted = Color(0xFF756E65);
  static const green = Color(0xFF385B4A);
  static const greenDark = Color(0xFF213E32);
  static const sage = Color(0xFF9CB8A5);
  static const gold = Color(0xFFD6A84E);
  static const terracotta = Color(0xFFB96E4D);
  static const clay = Color(0xFFE8DED1);
  static const blush = Color(0xFFF2EAE0);
  static const red = Color(0xFFD95D59);
  static const line = Color(0xFFE8E2D9);
  static const warmWhite = Color(0xFFFFFAF3);
}

class PantryProduct {
  String id;
  String name;
  double qty;
  String unit;
  String category;
  DateTime expiryDate;
  DateTime addedAt;
  bool opened;

  PantryProduct({
    required this.id,
    required this.name,
    this.qty = 1,
    this.unit = 'pièce',
    this.category = 'Autres',
    required this.expiryDate,
    DateTime? addedAt,
    this.opened = false,
  }) : addedAt = addedAt ?? DateTime.now();

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  Map<String,dynamic> toJson()=>{
    'id':id,'name':name,'qty':qty,'unit':unit,'category':category,
    'expiryDate':expiryDate.toIso8601String(),'addedAt':addedAt.toIso8601String(),'opened':opened,
  };

  factory PantryProduct.fromJson(Map<String,dynamic> j)=>PantryProduct(
    id:j['id']??DateTime.now().microsecondsSinceEpoch.toString(),
    name:j['name']??'',
    qty:(j['qty'] as num? ?? 1).toDouble(),
    unit:j['unit']??'pièce',
    category:j['category']??'Autres',
    expiryDate:DateTime.tryParse(j['expiryDate']??'') ?? DateTime.now(),
    addedAt:DateTime.tryParse(j['addedAt']??''),
    opened:j['opened']??false,
  );
}

List<DateTime> extractExpiryDates(String text) {
  final out=<DateTime>[];
  final seen=<String>{};
  void add(int y,int m,int d){
    if(y<100) y += y < 70 ? 2000 : 1900;
    try {
      final dt=DateTime(y,m,d);
      if(dt.year==y && dt.month==m && dt.day==d && y>=DateTime.now().year-1 && y<=DateTime.now().year+12){
        final k='${dt.year}-${dt.month}-${dt.day}';
        if(seen.add(k)) out.add(dt);
      }
    } catch(_){}
  }
  for(final m in RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b').allMatches(text)){
    add(int.parse(m.group(3)!),int.parse(m.group(2)!),int.parse(m.group(1)!));
  }
  for(final m in RegExp(r'\b(20\d{2})[\/\-.](\d{1,2})[\/\-.](\d{1,2})\b').allMatches(text)){
    add(int.parse(m.group(1)!),int.parse(m.group(2)!),int.parse(m.group(3)!));
  }
  final months={
    'jan':1,'janv':1,'janvier':1,'feb':2,'fev':2,'févr':2,'fevrier':2,'février':2,
    'mar':3,'mars':3,'apr':4,'avr':4,'avril':4,'may':5,'mai':5,'jun':6,'juin':6,
    'jul':7,'juil':7,'juillet':7,'aug':8,'aou':8,'août':8,'sep':9,'sept':9,'septembre':9,
    'oct':10,'octobre':10,'nov':11,'novembre':11,'dec':12,'déc':12,'decembre':12,'décembre':12
  };
  final lower=text.toLowerCase();
  final mr=RegExp(r'\b(\d{1,2})\s+(jan(?:v(?:ier)?)?|f[eé]v(?:r(?:ier)?)?|mars?|avr(?:il)?|mai|juin|juil(?:let)?|ao[uû]t|sept(?:embre)?|oct(?:obre)?|nov(?:embre)?|d[eé]c(?:embre)?)\s+(\d{2,4})\b');
  for(final m in mr.allMatches(lower)){
    final raw=m.group(2)!;
    int? month;
    for(final e in months.entries){ if(raw.startsWith(e.key)){month=e.value;break;} }
    if(month!=null) add(int.parse(m.group(3)!),month,int.parse(m.group(1)!));
  }
  out.sort();
  return out;
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
  String cuisine;
  List<String> tags;
  bool importedFromLibrary;
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
    this.cuisine = 'Maison',
    List<String>? tags,
    this.importedFromLibrary = false,
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
  })  : tags = tags ?? [],
        videos = videos ?? [],
        ingredients = ingredients ?? [],
        steps = steps ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'cuisine': cuisine,
        'tags': tags,
        'importedFromLibrary': importedFromLibrary,
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
        cuisine: j['cuisine'] ?? 'Maison',
        tags: List<String>.from(j['tags'] ?? []),
        importedFromLibrary: j['importedFromLibrary'] ?? false,
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


class WeeklyShoppingEntry {
  final String key;
  final String name;
  double qty;
  final String unit;
  bool purchased;
  final Set<String> recipes;
  WeeklyShoppingEntry({required this.key, required this.name, required this.qty, required this.unit, required this.purchased, Set<String>? recipes}) : recipes = recipes ?? <String>{};
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
  Map<String, int> mealServings = {};
  Set<String> weeklyPurchased = <String>{};
  bool weeklyShoppingReminder = false;
  List<PantryProduct> pantryProducts = [];
  Map<String, String> categoryIcons = {};
  AppSettings settings = AppSettings();

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('recipes_v4') ?? sp.getString('recipes_v3');
    final oldRaw = sp.getString('recipes_v2');
    final settingsRaw = sp.getString('settings_v1');
    final catsRaw = sp.getString('categories_v1');
    final mealRaw = sp.getString('meal_plan_v1');
    final servingsRaw = sp.getString('meal_servings_v11');
    final purchasedRaw = sp.getString('weekly_purchased_v11');
    final reminderRaw = sp.getBool('weekly_shopping_reminder_v11');
    final pantryRaw = sp.getString('pantry_products_v12');
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
    if (servingsRaw != null) {
      final decoded = Map<String, dynamic>.from(jsonDecode(servingsRaw));
      mealServings = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    if (purchasedRaw != null) {
      weeklyPurchased = Set<String>.from(jsonDecode(purchasedRaw));
    }
    weeklyShoppingReminder = reminderRaw ?? false;
    if (pantryRaw != null) { pantryProducts = (jsonDecode(pantryRaw) as List).map((e)=>PantryProduct.fromJson(Map<String,dynamic>.from(e))).toList(); }
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
    await sp.setString('meal_servings_v11', jsonEncode(mealServings));
    await sp.setString('weekly_purchased_v11', jsonEncode(weeklyPurchased.toList()));
    await sp.setBool('weekly_shopping_reminder_v11', weeklyShoppingReminder);
    await sp.setString('pantry_products_v12', jsonEncode(pantryProducts.map((e)=>e.toJson()).toList()));
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
        'mealServings': mealServings,
        'weeklyPurchased': weeklyPurchased.toList(),
        'weeklyShoppingReminder': weeklyShoppingReminder,
        'pantryProducts': pantryProducts.map((e)=>e.toJson()).toList(),
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
      if (data['mealServings'] is Map) { final x=Map<String,dynamic>.from(data['mealServings']); mealServings=x.map((k,v)=>MapEntry(k,(v as num).toInt())); }
      if (data['weeklyPurchased'] is List) weeklyPurchased = Set<String>.from(data['weeklyPurchased']);
      if (data['weeklyShoppingReminder'] is bool) weeklyShoppingReminder = data['weeklyShoppingReminder'];
      if (data['pantryProducts'] is List) pantryProducts = (data['pantryProducts'] as List).map((e)=>PantryProduct.fromJson(Map<String,dynamic>.from(e))).toList();
      if (data['categoryIcons'] is Map) categoryIcons = Map<String, String>.from(data['categoryIcons']);
    } else if (data is List) {
      recipes = data.map((e) => Recipe.fromJson(e)).toList();
    } else {
      return false;
    }
    await save();
    return true;
  }

  List<WeeklyShoppingEntry> weeklyShoppingEntries() {
    final grouped = <String, WeeklyShoppingEntry>{};
    for (final entry in mealPlan.entries) {
      final recipe = byId(entry.value);
      if (recipe == null) continue;
      final servings = mealServings[entry.key] ?? recipe.servings;
      final factor = recipe.servings <= 0 ? 1.0 : servings / recipe.servings;
      for (final ingredient in recipe.ingredients) {
        final normalizedName = ingredient.name.trim().toLowerCase();
        final normalizedUnit = ingredient.unit.trim().toLowerCase();
        final key = '$normalizedName|$normalizedUnit';
        final existing = grouped[key];
        final qty = ingredient.qty * factor;
        if (existing == null) {
          grouped[key] = WeeklyShoppingEntry(
            key: key,
            name: ingredient.name,
            qty: qty,
            unit: ingredient.unit,
            purchased: weeklyPurchased.contains(key),
            recipes: <String>{recipe.title},
          );
        } else {
          existing.qty += qty;
          existing.recipes.add(recipe.title);
          existing.purchased = weeklyPurchased.contains(key);
        }
      }
    }
    final result = grouped.values.toList();
    result.sort((a,b) {
      if (a.purchased != b.purchased) return a.purchased ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<void> setWeeklyPurchased(String key, bool value) async {
    if (value) { weeklyPurchased.add(key); } else { weeklyPurchased.remove(key); }
    await save();
  }

  Future<void> resetWeeklyPurchased() async {
    weeklyPurchased.clear();
    await save();
  }

  Future<void> setWeeklyShoppingReminder(bool enabled) async {
    weeklyShoppingReminder = enabled;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_shopping',
        'Courses de la semaine',
        channelDescription: 'Rappel hebdomadaire pour préparer les courses des repas planifiés',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    if (enabled) {
      final remaining = weeklyShoppingEntries().where((e) => !e.purchased).length;
      await notifications.periodicallyShow(
        401,
        'Courses de la semaine 🛒',
        remaining == 0 ? 'Prépare le planning de la semaine et génère ta liste de courses.' : '$remaining produits sont à vérifier dans ta liste de courses.',
        RepeatInterval.weekly,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else {
      await notifications.cancel(401);
    }
    await save();
  }

  bool isLibraryRecipeImported(Recipe recipe) => recipes.any((r) => r.id == recipe.id || (r.title.toLowerCase() == recipe.title.toLowerCase() && r.cuisine == recipe.cuisine));

  Future<void> importLibraryRecipe(Recipe recipe) async {
    if (isLibraryRecipeImported(recipe)) return;
    final copy = Recipe.fromJson(recipe.toJson());
    copy.importedFromLibrary = true;
    recipes.insert(0, copy);
    if (!categories.contains(copy.category)) categories.add(copy.category);
    await save();
  }

  int _expiryNotificationBase(String id) => 5000 + (id.hashCode.abs() % 100000) * 10;

  Future<void> _cancelExpiryAlerts(PantryProduct p) async {
    final base=_expiryNotificationBase(p.id);
    for(final x in [0,1,2]) { await notifications.cancel(base+x); }
  }

  Future<void> scheduleExpiryAlerts(PantryProduct p) async {
    await _cancelExpiryAlerts(p);
    const details=NotificationDetails(android:AndroidNotificationDetails(
      'food_expiry_v12','Produits à consommer',
      channelDescription:'Alertes avant et le jour de péremption des produits du frigo',
      importance:Importance.high, priority:Priority.high,
    ));
    final now=tz.TZDateTime.now(tz.local);
    final targets=[
      (days:3,id:0,title:'À consommer bientôt 🥕',body:'${p.name} expire dans 3 jours.'),
      (days:1,id:1,title:'À consommer demain ⚠️',body:'${p.name} expire demain.'),
      (days:0,id:2,title:'Date limite aujourd’hui 🚨',body:'${p.name} arrive à expiration aujourd’hui.'),
    ];
    for(final t in targets){
      final when=tz.TZDateTime(tz.local,p.expiryDate.year,p.expiryDate.month,p.expiryDate.day,9).subtract(Duration(days:t.days));
      if(when.isAfter(now)){
        await notifications.zonedSchedule(_expiryNotificationBase(p.id)+t.id,t.title,t.body,when,details,androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle,uiLocalNotificationDateInterpretation:UILocalNotificationDateInterpretation.absoluteTime);
      }
    }
    if(p.daysLeft<0){
      await notifications.show(_expiryNotificationBase(p.id)+2,'Produit expiré 🚨','${p.name} est dépassé depuis ${p.daysLeft.abs()} jour(s).',details);
    }
  }

  Future<void> upsertPantryProduct(PantryProduct p) async {
    final i=pantryProducts.indexWhere((e)=>e.id==p.id);
    if(i<0) pantryProducts.add(p); else pantryProducts[i]=p;
    pantryProducts.sort((a,b)=>a.expiryDate.compareTo(b.expiryDate));
    await scheduleExpiryAlerts(p);
    await save();
  }

  Future<void> removePantryProduct(PantryProduct p) async {
    await _cancelExpiryAlerts(p);
    pantryProducts.removeWhere((e)=>e.id==p.id);
    await save();
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: C.green,
            primary: C.green,
            secondary: C.terracotta,
            tertiary: C.gold,
            surface: C.card,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(bodyColor: C.ink, displayColor: C.ink),
          appBarTheme: const AppBarTheme(
            backgroundColor: C.cream,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: C.ink,
            centerTitle: false,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: C.green.withOpacity(.10),
            labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w700,
              fontSize: 11,
              color: states.contains(WidgetState.selected) ? C.greenDark : C.muted,
            )),
            iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? C.green : C.muted,
            )),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: C.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: C.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: C.green, width: 1.4)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: C.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          cardTheme: CardTheme(
            color: C.card,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: const BorderSide(color: C.line)),
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
      MealPlannerPage(store: widget.store),
      ShoppingPage(store: widget.store),
      RecipeLibraryPage(store: widget.store),
      MorePage(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: C.line),
              boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 28, offset: Offset(0, 12))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NavigationBar(
                selectedIndex: index,
                height: 70,
                onDestinationSelected: (i) => setState(() => index = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Accueil'),
                  NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Semaine'),
                  NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: 'Courses'),
                  NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Bibliothèque'),
                  NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.dashboard_customize_rounded), label: 'Plus'),
                ],
              ),
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
      final matchQuery = q.isEmpty || r.title.toLowerCase().contains(q) || r.category.toLowerCase().contains(q) || r.cuisine.toLowerCase().contains(q) || r.tags.any((t)=>t.toLowerCase().contains(q)) || r.ingredients.any((i)=>i.name.toLowerCase().contains(q)) || r.steps.any((st)=>st.title.toLowerCase().contains(q) || st.type.toLowerCase().contains(q));
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
                const SizedBox(height: 16),
                _overviewRow(),
                const SizedBox(height: 14),
                _weekSnapshot(),
                const SizedBox(height: 24),
                _section('Mes recettes', '${list.length} disponibles'),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.green, C.greenDark]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x26385B4A), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: const Icon(Icons.local_dining_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BONJOUR 👋', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: C.muted, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Votre cuisine, mieux organisée.', style: TextStyle(fontSize: 21, height: 1.12, color: C.ink, fontWeight: FontWeight.w900)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: C.warmWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
            child: const Row(children: [Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18), SizedBox(width: 5), Text('PRO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))]),
          ),
        ],
      );

  Widget _search() => Container(
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.line),
          boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 16, offset: Offset(0, 7))],
        ),
        child: TextField(
          onChanged: (v) => setState(() => query = v),
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, color: C.green),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.tune_rounded, size: 20, color: C.greenDark),
            ),
            hintText: 'Recette, ingrédient, étape…',
            hintStyle: const TextStyle(color: C.muted, fontWeight: FontWeight.w600),
            contentPadding: const EdgeInsets.symmetric(vertical: 17),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.greenDark, C.green, Color(0xFF6D806B)]),
          boxShadow: const [BoxShadow(color: Color(0x2A213E32), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
              child: const Row(children: [Icon(Icons.auto_awesome_rounded, color: C.gold, size: 16), SizedBox(width: 6), Text('SMART KITCHEN', style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: .8, fontWeight: FontWeight.w900))]),
            ),
            const Spacer(),
            const Icon(Icons.restaurant_rounded, color: Colors.white54),
          ]),
          const SizedBox(height: 17),
          const Text('Cuisinez sans stress.', style: TextStyle(color: Colors.white, fontSize: 24, height: 1.05, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Portions, chronos, ingrédients disponibles et timeline de préparation réunis au même endroit.', style: TextStyle(color: Color(0xFFE7F0EA), height: 1.45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 17),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.greenDark),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SmartKitchenPage(store: widget.store))),
                icon: const Icon(Icons.auto_awesome_rounded, size: 19),
                label: const Text('Ouvrir Smart Kitchen'),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(17)),
              child: const Icon(Icons.timer_rounded, color: C.gold),
            ),
          ]),
        ]),
      );

  Widget _overviewRow() {
    final favorites = widget.store.recipes.where((r) => r.favorite).length;
    final planned = widget.store.mealPlan.values.where((id) => id.isNotEmpty).length;
    return Row(children: [
      Expanded(child: _metricCard(Icons.menu_book_rounded, '${widget.store.recipes.length}', 'Recettes')),
      const SizedBox(width: 10),
      Expanded(child: _metricCard(Icons.favorite_rounded, '$favorites', 'Favoris')),
      const SizedBox(width: 10),
      Expanded(child: _metricCard(Icons.calendar_month_rounded, '$planned', 'Planifiés')),
    ]);
  }

  Widget _weekSnapshot() {
    final items = widget.store.weeklyShoppingEntries();
    final bought = items.where((e) => e.purchased).length;
    final planned = widget.store.mealPlan.values.where((e) => e.isNotEmpty).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.line)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shopping_cart_checkout_rounded, color: C.green)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cette semaine', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 3),
          Text('$planned repas · $bought/${items.length} courses cochées', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: C.muted),
      ]),
    );
  }

  Widget _metricCard(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: C.green),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 20, height: 1, fontWeight: FontWeight.w900, color: C.ink)),
      const SizedBox(height: 4),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w800)),
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
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: C.line), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 9))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: RecipeImage(recipe: recipe, radius: 28)),
              Positioned(left: 10, top: 10, child: miniPill(recipe.category, _catIcon(recipe.category))),
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
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(r.title, style: const TextStyle(fontSize: 27, height: 1.06, fontWeight: FontWeight.w900, color: C.ink))),
                const SizedBox(width: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18)),
              ]),
              const SizedBox(height: 10),
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeSmartKitchenPage(store: widget.store, recipe: r))),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Smart Kitchen · portions & timeline'),
                style: FilledButton.styleFrom(backgroundColor: C.terracotta, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
              ),
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
                label: const Text('Courses de la semaine'),
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
  String filter = 'À acheter';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (_, __) {
        final all = widget.store.weeklyShoppingEntries();
        final bought = all.where((e) => e.purchased).length;
        final visible = filter == 'Tout' ? all : filter == 'Acheté' ? all.where((e) => e.purchased).toList() : all.where((e) => !e.purchased).toList();
        final progress = all.isEmpty ? 0.0 : bought / all.length;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Courses de la semaine', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                tooltip: 'Réinitialiser les achats',
                onPressed: all.isEmpty ? null : () => _confirmReset(context),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              _shoppingHero(all.length, bought, progress),
              const SizedBox(height: 14),
              _reminderCard(),
              const SizedBox(height: 16),
              if (widget.recipe != null)
                premiumNote(Icons.info_outline_rounded, 'Liste hebdomadaire', 'Cette version regroupe automatiquement tous les repas du planning. Ajoute ${widget.recipe!.title} à ta semaine pour inclure ses quantités.'),
              if (all.isEmpty)
                Container(
                  decoration: soft(radius: 28),
                  child: Column(children: [
                    premiumEmpty(Icons.shopping_cart_checkout_rounded, 'Ta liste est vide', 'Planifie les repas de la semaine : les ingrédients et quantités apparaîtront ici automatiquement.'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlannerPage(store: widget.store))),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Planifier ma semaine'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      ),
                    ),
                  ]),
                )
              else ...[
                _filterChips(),
                const SizedBox(height: 12),
                ..._shoppingSections(visible),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _copyWeeklyList(context, all.where((e) => !e.purchased).toList()),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Copier la liste restante'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlannerPage(store: widget.store))),
                  icon: const Icon(Icons.edit_calendar_rounded),
                  label: const Text('Modifier les repas / portions'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _shoppingHero(int total, int bought, double progress) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: C.greenDark,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 12))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shopping_basket_rounded, color: C.gold)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Panier intelligent', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          Text('Quantités cumulées de toute la semaine', style: TextStyle(color: Color(0xFFD9E4DD), fontWeight: FontWeight.w700)),
        ])),
      ]),
      const SizedBox(height: 18),
      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 10, color: C.gold, backgroundColor: Colors.white.withOpacity(.12))),
      const SizedBox(height: 10),
      Row(children: [
        Text('$bought / $total produits achetés', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text('${(progress * 100).round()}%', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w900)),
      ]),
    ]),
  );

  Widget _reminderCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.line)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.notifications_active_rounded, color: C.terracotta)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Rappel courses', style: TextStyle(fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Une notification hebdomadaire pour vérifier la liste.', style: TextStyle(color: C.muted, fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w700)),
      ])),
      Switch(value: widget.store.weeklyShoppingReminder, onChanged: (v) async {
        await widget.store.setWeeklyShoppingReminder(v);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v ? 'Rappel hebdomadaire activé' : 'Rappel désactivé')));
      }),
    ]),
  );

  Widget _filterChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: ['À acheter', 'Acheté', 'Tout'].map((x) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(x), selected: filter == x, onSelected: (_) => setState(() => filter = x)),
    )).toList()),
  );

  List<Widget> _shoppingSections(List<WeeklyShoppingEntry> items) {
    final groups = <String, List<WeeklyShoppingEntry>>{};
    for (final item in items) {
      groups.putIfAbsent(_groceryCategory(item.name), () => <WeeklyShoppingEntry>[]).add(item);
    }
    final order = ['Fruits & légumes','Viandes & poisson','Produits frais','Épicerie','Boulangerie','Autres'];
    final widgets = <Widget>[];
    for (final category in order) {
      final group = groups[category];
      if (group == null || group.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 9),
        child: Row(children: [Icon(_groceryIcon(category), size: 19, color: C.green), const SizedBox(width: 8), Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.ink)), const Spacer(), Text('${group.length}', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800))]),
      ));
      widgets.addAll(group.map(_shoppingItem));
    }
    return widgets;
  }

  String _groceryCategory(String name) {
    final n = name.toLowerCase();
    if (['poulet','viande','saumon','crevette','moule','lardon','guanciale'].any(n.contains)) return 'Viandes & poisson';
    if (['tomate','oignon','carotte','courgette','aubergine','poivron','citron','concombre','avocat','persil','coriandre','céleri','épinard','navet','potiron','ail','banane'].any(n.contains)) return 'Fruits & légumes';
    if (['œuf','oeuf','lait','yaourt','fromage','feta','mozzarella','parmesan','crème','beurre','mascarpone'].any(n.contains)) return 'Produits frais';
    if (['pain','tortilla','brick','pâte brisée'].any(n.contains)) return 'Boulangerie';
    if (['riz','farine','sucre','lentille','pois chiche','haricot','pâte','spaghetti','penne','semoule','huile','épice','cumin','paprika','curry','cannelle','miel','café','cacao','chocolat','avoine','quinoa','nouille','sauce','maïs'].any(n.contains)) return 'Épicerie';
    return 'Autres';
  }

  IconData _groceryIcon(String category) {
    switch (category) {
      case 'Fruits & légumes': return Icons.eco_rounded;
      case 'Viandes & poisson': return Icons.set_meal_rounded;
      case 'Produits frais': return Icons.egg_alt_rounded;
      case 'Épicerie': return Icons.inventory_2_rounded;
      case 'Boulangerie': return Icons.bakery_dining_rounded;
      default: return Icons.shopping_bag_rounded;
    }
  }

  Widget _shoppingItem(WeeklyShoppingEntry e) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: e.purchased ? C.green.withOpacity(.055) : C.card, borderRadius: BorderRadius.circular(23), border: Border.all(color: e.purchased ? C.green.withOpacity(.18) : C.line)),
    child: CheckboxListTile(
      value: e.purchased,
      activeColor: C.green,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.fromLTRB(12, 5, 14, 5),
      title: Text(e.name, style: TextStyle(fontWeight: FontWeight.w900, decoration: e.purchased ? TextDecoration.lineThrough : null, color: e.purchased ? C.muted : C.ink)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('${e.recipes.length} recette${e.recipes.length > 1 ? 's' : ''} · ${e.recipes.take(2).join(' + ')}${e.recipes.length > 2 ? '…' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
      ),
      secondary: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(14)),
        child: Text('${fmt(e.qty)} ${e.unit}', style: const TextStyle(color: C.greenDark, fontWeight: FontWeight.w900)),
      ),
      onChanged: (v) => widget.store.setWeeklyPurchased(e.key, v ?? false),
    ),
  );

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Nouvelle semaine ?'),
      content: const Text('Tous les produits repasseront en “à acheter”. Le planning reste inchangé.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Réinitialiser'))],
    ));
    if (ok == true) await widget.store.resetWeeklyPurchased();
  }

  void _copyWeeklyList(BuildContext context, List<WeeklyShoppingEntry> items) {
    final text = items.isEmpty
        ? 'Courses de la semaine : tout est acheté ✅'
        : 'Courses de la semaine\n\n${items.map((e) => '☐ ${e.name} — ${fmt(e.qty)} ${e.unit}').join('\n')}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liste de courses copiée')));
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
          field('Cuisine / origine', r.cuisine, (v) => r.cuisine = v.trim().isEmpty ? 'Maison' : v),
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

class MealPlannerPage extends StatefulWidget {
  final Store store;
  const MealPlannerPage({super.key, required this.store});
  @override
  State<MealPlannerPage> createState()=>_MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  final days = const ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
  final meals = const ['Petit-déj','Déjeuner','Casse-croûte','Dîner'];
  String selectedDay = 'Lundi';

  @override
  Widget build(BuildContext context) {
    final planned = widget.store.mealPlan.values.where((id) => id.isNotEmpty).length;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Ma semaine', style: TextStyle(fontWeight: FontWeight.w900))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            _plannerHero(planned),
            const SizedBox(height: 16),
            _daySelector(),
            const SizedBox(height: 14),
            _dayCard(selectedDay),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShoppingPage(store: widget.store))),
              icon: const Icon(Icons.shopping_basket_rounded),
              label: const Text('Voir les courses calculées'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
            const SizedBox(height: 12),
            premiumNote(Icons.lightbulb_rounded, 'Quantités automatiques', 'Change le nombre de personnes pour chaque repas : les quantités de la liste de courses sont recalculées automatiquement.'),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeLibraryPage(store: widget.store))),
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('Trouver des idées dans la bibliothèque'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plannerHero(int planned) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(30)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Planifier sans stress', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Choisis les repas, les portions et laisse l’app préparer les courses.', style: TextStyle(color: Color(0xFFE9E1D6), height: 1.35, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14)), child: Text('$planned repas planifié${planned > 1 ? 's' : ''}', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w900))),
      ])),
      const SizedBox(width: 14),
      Container(width: 66, height: 66, decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.calendar_month_rounded, color: C.gold, size: 32)),
    ]),
  );

  Widget _daySelector() => SizedBox(
    height: 52,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final d = days[i];
        final active = d == selectedDay;
        return ChoiceChip(
          label: Text(d.substring(0, 3)),
          selected: active,
          onSelected: (_) => setState(() => selectedDay = d),
          avatar: active ? const Icon(Icons.check_rounded, size: 17) : null,
        );
      },
    ),
  );

  Widget _dayCard(String day) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: C.line), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 9))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.restaurant_rounded, color: C.green)),
        const SizedBox(width: 11),
        Text(day, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 10),
      for (final meal in meals) _mealSlot(day, meal),
      Builder(builder: (_) {
        final ids = meals.map((m) => widget.store.mealPlan['$day-$m']).whereType<String>();
        final notes = ids.map((id) => widget.store.byId(id)?.thawNote ?? '').where((e) => e.isNotEmpty).toList();
        return notes.isEmpty ? const SizedBox.shrink() : Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.terracotta.withOpacity(.08), borderRadius: BorderRadius.circular(18)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.ac_unit_rounded, color: C.terracotta), const SizedBox(width: 8), Expanded(child: Text('À préparer : ${notes.join(' • ')}', style: const TextStyle(color: C.terracotta, fontWeight: FontWeight.w800, height: 1.3)))]),
        );
      }),
    ]),
  );

  Widget _mealSlot(String day, String meal) {
    final key = '$day-$meal';
    final selectedId = widget.store.mealPlan[key];
    final selectedRecipe = selectedId == null ? null : widget.store.byId(selectedId);
    final servings = widget.store.mealServings[key] ?? selectedRecipe?.servings ?? 4;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.cream, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(meal, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: selectedId,
          isExpanded: true,
          items: [const DropdownMenuItem<String>(value: null, child: Text('Aucun repas')), ...widget.store.recipes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.title, overflow: TextOverflow.ellipsis)))],
          onChanged: (v) {
            if (v == null) {
              widget.store.mealPlan.remove(key);
              widget.store.mealServings.remove(key);
            } else {
              widget.store.mealPlan[key] = v;
              final r = widget.store.byId(v);
              widget.store.mealServings[key] = r?.servings ?? 4;
            }
            widget.store.save();
          },
          decoration: const InputDecoration(labelText: 'Recette', contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11)),
        ),
        if (selectedRecipe != null) ...[
          const SizedBox(height: 9),
          Row(children: [
            const Icon(Icons.people_alt_rounded, size: 18, color: C.green),
            const SizedBox(width: 7),
            const Text('Personnes', style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            _roundIcon(Icons.remove_rounded, servings <= 1 ? null : () { widget.store.mealServings[key] = servings - 1; widget.store.save(); }),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$servings', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
            _roundIcon(Icons.add_rounded, () { widget.store.mealServings[key] = servings + 1; widget.store.save(); }),
          ]),
        ],
      ]),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback? onTap) => IconButton.filledTonal(onPressed: onTap, icon: Icon(icon, size: 19), constraints: const BoxConstraints.tightFor(width: 38, height: 38), padding: EdgeInsets.zero);
}

class RecipeLibraryPage extends StatefulWidget {
  final Store store;
  const RecipeLibraryPage({super.key, required this.store});
  @override
  State<RecipeLibraryPage> createState() => _RecipeLibraryPageState();
}

class _RecipeLibraryPageState extends State<RecipeLibraryPage> {
  String query = '';
  String cuisine = 'Toutes';

  @override
  Widget build(BuildContext context) {
    final catalog = builtInRecipeLibrary();
    final cuisines = ['Toutes', ...{for (final r in catalog) r.cuisine}];
    final filtered = catalog.where((r) {
      final q = query.trim().toLowerCase();
      final matchQ = q.isEmpty || r.title.toLowerCase().contains(q) || r.cuisine.toLowerCase().contains(q) || r.tags.any((t) => t.toLowerCase().contains(q)) || r.ingredients.any((i) => i.name.toLowerCase().contains(q));
      return matchQ && (cuisine == 'Toutes' || r.cuisine == cuisine);
    }).toList();
    final imported = catalog.where(widget.store.isLibraryRecipeImported).length;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Bibliothèque recettes', style: TextStyle(fontWeight: FontWeight.w900))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            _libraryHero(catalog.length, imported),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: inputDecoration('Chercher plat, ingrédient ou cuisine').copyWith(prefixIcon: const Icon(Icons.search_rounded)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cuisines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final x = cuisines[i];
                  return ChoiceChip(label: Text(x), selected: cuisine == x, onSelected: (_) => setState(() => cuisine = x));
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text('${filtered.length} recettes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              Text('$imported importée${imported > 1 ? 's' : ''}', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            ...filtered.map(_libraryCard),
          ],
        ),
      ),
    );
  }

  Widget _libraryHero(int count, int imported) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [C.greenDark, C.green], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 28, offset: Offset(0, 12))],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.auto_stories_rounded, color: C.gold), SizedBox(width: 8), Text('Kitchen Library', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 9),
        const Text('Des recettes complètes prêtes à importer dans ton carnet, avec ingrédients, quantités et étapes.', style: TextStyle(color: Color(0xFFE5EFE9), height: 1.4, fontWeight: FontWeight.w700)),
        const SizedBox(height: 13),
        Text('$count recettes · $imported dans ton carnet', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(width: 12),
      Container(width: 66, height: 66, decoration: BoxDecoration(color: Colors.white.withOpacity(.11), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 32)),
    ]),
  );

  Widget _libraryCard(Recipe r) {
    final done = widget.store.isLibraryRecipeImported(r);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: done ? C.green.withOpacity(.24) : C.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryRecipePreviewPage(store: widget.store, recipe: r))),
        child: Row(children: [
          SizedBox(width: 112, height: 132, child: RecipeImage(recipe: r, radius: 0)),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [miniPill(r.cuisine, Icons.public_rounded), const Spacer(), if (done) const Icon(Icons.check_circle_rounded, color: C.green, size: 20)]),
              const SizedBox(height: 8),
              Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text('${r.minutes} min · ${r.difficulty} · ${r.servings} pers.', style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              SizedBox(
                height: 34,
                child: done
                    ? OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.done_rounded, size: 17), label: const Text('Déjà importée'))
                    : FilledButton.icon(onPressed: () => _import(r), icon: const Icon(Icons.download_rounded, size: 17), label: const Text('Importer'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12))),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Future<void> _import(Recipe r) async {
    await widget.store.importLibraryRecipe(r);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.title} ajoutée à tes recettes ✅')));
  }
}

class LibraryRecipePreviewPage extends StatelessWidget {
  final Store store;
  final Recipe recipe;
  const LibraryRecipePreviewPage({super.key, required this.store, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final imported = store.isLibraryRecipeImported(recipe);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 285,
          pinned: true,
          backgroundColor: C.cream,
          flexibleSpace: FlexibleSpaceBar(background: Padding(padding: const EdgeInsets.fromLTRB(16, 68, 16, 18), child: RecipeImage(recipe: recipe, radius: 32))),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          sliver: SliverList.list(children: [
            Wrap(spacing: 8, runSpacing: 8, children: [miniPill(recipe.cuisine, Icons.public_rounded), miniPill(recipe.category, Icons.category_rounded), miniPill('${recipe.minutes} min', Icons.schedule_rounded)]),
            const SizedBox(height: 12),
            Text(recipe.title, style: const TextStyle(fontSize: 28, height: 1.08, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(children: [infoTile(Icons.people_alt_rounded, '${recipe.servings} pers.'), infoTile(Icons.signal_cellular_alt_rounded, recipe.difficulty), infoTile(Icons.star_rounded, '${recipe.rating}/5')]),
            const SizedBox(height: 20),
            const Text('Ingrédients', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...recipe.ingredients.map(ingredientRow),
            const SizedBox(height: 16),
            const Text('Préparation', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...recipe.steps.asMap().entries.map((e) => stepRow(e.key, e.value)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: imported ? null : () async { await store.importLibraryRecipe(recipe); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recette ajoutée au carnet ✅'))); },
              icon: Icon(imported ? Icons.done_all_rounded : Icons.download_rounded),
              label: Text(imported ? 'Déjà dans mes recettes' : 'Importer dans mes recettes'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ]),
        ),
      ]),
    );
  }
}

Ingredient _bi(String name, num qty, String unit) => Ingredient(name: name, qty: qty.toDouble(), unit: unit);
CookStep _bs(String title, int minutes, {int temp = 0, String note = '', String type = 'Préparation'}) => CookStep(title: title, minutes: minutes, temp: temp, note: note, type: type);
Recipe _br(String id, String title, String cuisine, String category, int minutes, int servings, List<Ingredient> ingredients, List<CookStep> steps, {String difficulty = 'Facile', int rating = 5, int temp = 0, List<String> tags = const []}) => Recipe(id: id, title: title, cuisine: cuisine, category: category, minutes: minutes, servings: servings, ingredients: ingredients, steps: steps, difficulty: difficulty, rating: rating, temp: temp, tags: tags);

List<Recipe> builtInRecipeLibrary() => [
  _br('lib_ma_tajine_kefta','Tajine de kefta aux œufs','Marocaine','Tajines',45,4,[ _bi('Viande hachée',500,'g'),_bi('Tomates',5,'pièces'),_bi('Oignon',1,'pièce'),_bi('Œufs',4,'pièces'),_bi('Persil',0.5,'bouquet'),_bi('Cumin',1,'cuillère'),_bi('Paprika',1,'cuillère'),_bi('Huile d’olive',2,'cuillères')],[ _bs('Préparer la sauce tomate avec oignon et épices',15,type:'Cuisson'),_bs('Former les boulettes de kefta et les ajouter',18,type:'Cuisson'),_bs('Casser les œufs sur le dessus et terminer à couvert',10,type:'Cuisson')],difficulty:'Facile',tags:['familial','tajine','viande']),
  _br('lib_ma_harira','Harira marocaine','Marocaine','Soupes',75,6,[ _bi('Tomates',6,'pièces'),_bi('Pois chiches',200,'g'),_bi('Lentilles',150,'g'),_bi('Céleri',0.5,'bouquet'),_bi('Coriandre',0.5,'bouquet'),_bi('Viande',300,'g'),_bi('Vermicelles',80,'g'),_bi('Farine',60,'g')],[ _bs('Mixer tomates, céleri et herbes',10,type:'Mixer'),_bs('Cuire viande, pois chiches, lentilles et base tomate',45,type:'Cuisson'),_bs('Lier avec farine diluée puis ajouter vermicelles',15,type:'Cuisson')],difficulty:'Moyen',tags:['ramadan','soupe','tradition']),
  _br('lib_ma_couscous','Couscous aux 7 légumes','Marocaine','Plats',110,6,[ _bi('Semoule couscous',750,'g'),_bi('Viande',700,'g'),_bi('Carottes',4,'pièces'),_bi('Courgettes',3,'pièces'),_bi('Navets',3,'pièces'),_bi('Potiron',500,'g'),_bi('Pois chiches',200,'g'),_bi('Oignons',2,'pièces')],[ _bs('Préparer le bouillon avec viande et oignons',25,type:'Cuisson'),_bs('Ajouter les légumes selon leur temps de cuisson',40,type:'Cuisson'),_bs('Cuire et égrainer la semoule à la vapeur',35,type:'Cuisson'),_bs('Dresser semoule, légumes et bouillon',10)],difficulty:'Moyen',tags:['dimanche','famille','tradition']),
  _br('lib_ma_briouates','Briouates poulet amandes','Marocaine','Plats',60,6,[ _bi('Feuilles de brick',12,'pièces'),_bi('Poulet',500,'g'),_bi('Oignons',2,'pièces'),_bi('Amandes',120,'g'),_bi('Œufs',3,'pièces'),_bi('Cannelle',1,'cuillère'),_bi('Miel',2,'cuillères')],[ _bs('Cuire puis effilocher le poulet avec les oignons',25,type:'Cuisson'),_bs('Ajouter œufs et amandes concassées',8,type:'Cuisson'),_bs('Plier les briouates et dorer au four',20,temp:190,type:'Four')],difficulty:'Moyen',tags:['entrée','ramadan','brick']),
  _br('lib_fr_quiche','Quiche lorraine','Française','Plats',50,6,[ _bi('Pâte brisée',1,'pièce'),_bi('Lardons',200,'g'),_bi('Œufs',3,'pièces'),_bi('Crème fraîche',250,'ml'),_bi('Lait',100,'ml'),_bi('Fromage râpé',100,'g')],[ _bs('Faire revenir les lardons',7,type:'Cuisson'),_bs('Mélanger œufs, crème et lait',5),_bs('Garnir la pâte et cuire au four',35,temp:180,type:'Four')],tags:['four','rapide','famille']),
  _br('lib_fr_rat','Ratatouille provençale','Française','Plats',50,4,[ _bi('Aubergines',2,'pièces'),_bi('Courgettes',2,'pièces'),_bi('Poivrons',2,'pièces'),_bi('Tomates',4,'pièces'),_bi('Oignon',1,'pièce'),_bi('Huile d’olive',3,'cuillères')],[ _bs('Découper tous les légumes',12,type:'Couper'),_bs('Faire revenir oignon, aubergines et poivrons',15,type:'Cuisson'),_bs('Ajouter tomates et courgettes puis mijoter',20,type:'Cuisson')],tags:['légumes','végétarien','été']),
  _br('lib_fr_crepes','Crêpes maison','Française','Desserts',30,6,[ _bi('Farine',250,'g'),_bi('Œufs',4,'pièces'),_bi('Lait',500,'ml'),_bi('Beurre',40,'g'),_bi('Sucre',30,'g')],[ _bs('Mélanger farine, œufs et lait progressivement',8),_bs('Laisser reposer la pâte',10,type:'Repos'),_bs('Cuire les crêpes une par une',12,type:'Cuisson')],tags:['goûter','enfants','facile']),
  _br('lib_it_carbonara','Spaghetti carbonara','Italienne','Plats',25,4,[ _bi('Spaghetti',400,'g'),_bi('Guanciale ou lardons',180,'g'),_bi('Œufs',4,'pièces'),_bi('Parmesan',100,'g'),_bi('Poivre noir',1,'cuillère')],[ _bs('Cuire les pâtes al dente',10,type:'Cuisson'),_bs('Dorer le guanciale',7,type:'Cuisson'),_bs('Mélanger hors feu avec œufs, fromage et eau de cuisson',5)],tags:['pâtes','rapide','italie']),
  _br('lib_it_lasagne','Lasagnes bolognaises','Italienne','Plats',90,6,[ _bi('Feuilles lasagnes',12,'pièces'),_bi('Viande hachée',600,'g'),_bi('Tomates concassées',800,'g'),_bi('Oignon',1,'pièce'),_bi('Béchamel',600,'ml'),_bi('Mozzarella',250,'g')],[ _bs('Préparer la sauce bolognaise',35,type:'Cuisson'),_bs('Monter les couches lasagne, sauce et béchamel',15),_bs('Cuire au four',35,temp:190,type:'Four')],difficulty:'Moyen',tags:['four','famille','pâtes']),
  _br('lib_it_pesto','Penne au pesto','Italienne','Plats',20,4,[ _bi('Penne',400,'g'),_bi('Basilic',1,'bouquet'),_bi('Parmesan',80,'g'),_bi('Pignons',40,'g'),_bi('Huile d’olive',100,'ml'),_bi('Ail',1,'gousse')],[ _bs('Cuire les penne',11,type:'Cuisson'),_bs('Mixer basilic, parmesan, pignons, ail et huile',5,type:'Mixer'),_bs('Mélanger le pesto aux pâtes chaudes',2)],tags:['rapide','végétarien','pâtes']),
  _br('lib_es_paella','Paella poulet et fruits de mer','Espagnole','Plats',60,6,[ _bi('Riz rond',500,'g'),_bi('Poulet',500,'g'),_bi('Crevettes',300,'g'),_bi('Moules',500,'g'),_bi('Poivron rouge',1,'pièce'),_bi('Petits pois',150,'g'),_bi('Bouillon',1.2,'L')],[ _bs('Dorer le poulet et le poivron',15,type:'Cuisson'),_bs('Ajouter riz et bouillon puis cuire sans remuer',25,type:'Cuisson'),_bs('Ajouter fruits de mer et petits pois',12,type:'Cuisson')],difficulty:'Moyen',tags:['riz','mer','convivial']),
  _br('lib_es_tortilla','Tortilla espagnole','Espagnole','Plats',40,4,[ _bi('Pommes de terre',700,'g'),_bi('Œufs',6,'pièces'),_bi('Oignon',1,'pièce'),_bi('Huile d’olive',120,'ml')],[ _bs('Cuire doucement pommes de terre et oignon',22,type:'Cuisson'),_bs('Mélanger avec les œufs battus',4),_bs('Cuire la tortilla des deux côtés',10,type:'Cuisson')],tags:['œufs','économique','famille']),
  _br('lib_as_padthai','Pad thaï poulet','Thaïlandaise','Plats',30,4,[ _bi('Nouilles de riz',350,'g'),_bi('Poulet',350,'g'),_bi('Œufs',2,'pièces'),_bi('Pousses de soja',150,'g'),_bi('Cacahuètes',60,'g'),_bi('Sauce soja',3,'cuillères'),_bi('Citron vert',2,'pièces')],[ _bs('Réhydrater les nouilles et préparer les ingrédients',8),_bs('Saisir poulet puis œufs',8,type:'Cuisson'),_bs('Ajouter nouilles, sauce et pousses de soja',8,type:'Cuisson'),_bs('Servir avec cacahuètes et citron vert',3)],tags:['wok','nouilles','rapide']),
  _br('lib_as_friedrice','Riz sauté aux légumes','Asiatique','Plats',25,4,[ _bi('Riz cuit',600,'g'),_bi('Œufs',3,'pièces'),_bi('Carotte',1,'pièce'),_bi('Petits pois',150,'g'),_bi('Oignons verts',3,'pièces'),_bi('Sauce soja',3,'cuillères')],[ _bs('Préparer les légumes et battre les œufs',6,type:'Couper'),_bs('Cuire les œufs puis les légumes au wok',7,type:'Cuisson'),_bs('Ajouter le riz froid et la sauce soja',8,type:'Cuisson')],tags:['anti-gaspi','riz','rapide']),
  _br('lib_jp_teriyaki','Poulet teriyaki','Japonaise','Plats',30,4,[ _bi('Poulet',600,'g'),_bi('Sauce soja',60,'ml'),_bi('Miel',2,'cuillères'),_bi('Gingembre',1,'cuillère'),_bi('Ail',2,'gousses'),_bi('Riz',300,'g')],[ _bs('Cuire le riz',15,type:'Cuisson'),_bs('Saisir le poulet',8,type:'Cuisson'),_bs('Ajouter sauce soja, miel, gingembre et ail puis glacer',6,type:'Cuisson')],tags:['poulet','riz','sucré-salé']),
  _br('lib_in_dhal','Dhal de lentilles corail','Indienne','Plats',35,4,[ _bi('Lentilles corail',300,'g'),_bi('Tomates concassées',400,'g'),_bi('Lait de coco',300,'ml'),_bi('Oignon',1,'pièce'),_bi('Curry',2,'cuillères'),_bi('Épinards',150,'g')],[ _bs('Faire revenir oignon et épices',7,type:'Cuisson'),_bs('Ajouter lentilles, tomates et lait de coco',22,type:'Cuisson'),_bs('Incorporer les épinards',4,type:'Cuisson')],tags:['végétarien','lentilles','batch cooking']),
  _br('lib_in_tikka','Poulet tikka masala','Indienne','Plats',55,4,[ _bi('Poulet',600,'g'),_bi('Yaourt nature',150,'g'),_bi('Tomates concassées',500,'g'),_bi('Crème',120,'ml'),_bi('Oignon',1,'pièce'),_bi('Garam masala',2,'cuillères'),_bi('Riz basmati',300,'g')],[ _bs('Mariner le poulet au yaourt et épices',15,type:'Mariner'),_bs('Dorer le poulet',10,type:'Cuisson'),_bs('Préparer la sauce tomate épicée puis ajouter crème et poulet',20,type:'Cuisson')],difficulty:'Moyen',tags:['poulet','épices','riz']),
  _br('lib_mx_fajitas','Fajitas de poulet','Mexicaine','Plats',30,4,[ _bi('Tortillas',8,'pièces'),_bi('Poulet',500,'g'),_bi('Poivrons',3,'pièces'),_bi('Oignon',1,'pièce'),_bi('Avocat',2,'pièces'),_bi('Citron vert',1,'pièce')],[ _bs('Émincer poulet, poivrons et oignon',8,type:'Couper'),_bs('Saisir le tout avec les épices',12,type:'Cuisson'),_bs('Réchauffer les tortillas et garnir',6,type:'Cuisson')],tags:['rapide','famille','à partager']),
  _br('lib_mx_chili','Chili con carne','Mexicaine','Plats',50,6,[ _bi('Viande hachée',600,'g'),_bi('Haricots rouges',500,'g'),_bi('Tomates concassées',800,'g'),_bi('Maïs',200,'g'),_bi('Oignons',2,'pièces'),_bi('Cumin',2,'cuillères')],[ _bs('Faire revenir viande et oignons',12,type:'Cuisson'),_bs('Ajouter tomates, haricots, maïs et épices',30,type:'Cuisson'),_bs('Rectifier l’assaisonnement et servir',3)],tags:['batch cooking','familial','économique']),
  _br('lib_gr_salad','Salade grecque','Grecque','Salades',15,4,[ _bi('Tomates',4,'pièces'),_bi('Concombre',1,'pièce'),_bi('Feta',200,'g'),_bi('Olives noires',100,'g'),_bi('Oignon rouge',1,'pièce'),_bi('Huile d’olive',3,'cuillères')],[ _bs('Couper tomates, concombre et oignon',8,type:'Couper'),_bs('Ajouter feta, olives et huile d’olive',4)],tags:['frais','été','végétarien']),
  _br('lib_med_salmon','Saumon citron au four','Méditerranéenne','Plats',35,4,[ _bi('Pavés de saumon',4,'pièces'),_bi('Citron',2,'pièces'),_bi('Pommes de terre',700,'g'),_bi('Courgettes',2,'pièces'),_bi('Huile d’olive',3,'cuillères')],[ _bs('Découper et assaisonner les légumes',8,type:'Couper'),_bs('Précuire pommes de terre et courgettes',12,temp:200,type:'Four'),_bs('Ajouter saumon et citron puis terminer la cuisson',12,temp:200,type:'Four')],tags:['poisson','four','healthy']),
  _br('lib_healthy_bowl','Bowl poulet quinoa avocat','Healthy','Salades',30,4,[ _bi('Quinoa',250,'g'),_bi('Poulet',450,'g'),_bi('Avocats',2,'pièces'),_bi('Tomates cerises',250,'g'),_bi('Concombre',1,'pièce'),_bi('Yaourt nature',120,'g')],[ _bs('Cuire le quinoa',15,type:'Cuisson'),_bs('Griller le poulet',10,type:'Cuisson'),_bs('Assembler les légumes, quinoa, poulet et sauce yaourt',5)],tags:['protéiné','meal prep','healthy']),
  _br('lib_breakfast_oats','Overnight oats banane','Petit-déjeuner','Petit-déj',8,2,[ _bi('Flocons d’avoine',120,'g'),_bi('Lait',250,'ml'),_bi('Yaourt',120,'g'),_bi('Banane',1,'pièce'),_bi('Graines de chia',2,'cuillères')],[ _bs('Mélanger avoine, lait, yaourt et chia',4),_bs('Réfrigérer toute la nuit',1,type:'Repos'),_bs('Ajouter la banane avant de servir',3)],tags:['matin','sans cuisson','meal prep']),
  _br('lib_breakfast_omelette','Omelette légumes fromage','Petit-déjeuner','Petit-déj',15,2,[ _bi('Œufs',4,'pièces'),_bi('Poivron',0.5,'pièce'),_bi('Tomate',1,'pièce'),_bi('Fromage râpé',60,'g'),_bi('Persil',0.25,'bouquet')],[ _bs('Couper les légumes',4,type:'Couper'),_bs('Battre les œufs et ajouter les légumes',3),_bs('Cuire l’omelette puis ajouter le fromage',7,type:'Cuisson')],tags:['matin','protéiné','rapide']),
  _br('lib_dess_tiramisu','Tiramisu classique','Italienne','Desserts',30,8,[ _bi('Mascarpone',500,'g'),_bi('Œufs',4,'pièces'),_bi('Sucre',100,'g'),_bi('Biscuits cuillère',250,'g'),_bi('Café',300,'ml'),_bi('Cacao',20,'g')],[ _bs('Préparer la crème mascarpone',12),_bs('Tremper rapidement les biscuits dans le café',5),_bs('Monter les couches et saupoudrer de cacao',8),_bs('Réfrigérer au moins 4 heures',1,type:'Repos')],difficulty:'Moyen',tags:['dessert','café','sans four']),
  _br('lib_dess_brownie','Brownie chocolat','Américaine','Desserts',40,8,[ _bi('Chocolat noir',200,'g'),_bi('Beurre',150,'g'),_bi('Sucre',180,'g'),_bi('Œufs',3,'pièces'),_bi('Farine',90,'g'),_bi('Noix',80,'g')],[ _bs('Faire fondre chocolat et beurre',5,type:'Cuisson'),_bs('Incorporer sucre, œufs, farine et noix',8),_bs('Cuire au four',24,temp:175,type:'Four')],tags:['chocolat','goûter','four']),
  _br('lib_turk_lentil','Soupe de lentilles turque','Turque','Soupes',40,5,[ _bi('Lentilles corail',300,'g'),_bi('Carotte',1,'pièce'),_bi('Pomme de terre',1,'pièce'),_bi('Oignon',1,'pièce'),_bi('Concentré de tomate',1,'cuillère'),_bi('Bouillon',1,'L')],[ _bs('Faire revenir oignon et légumes',8,type:'Cuisson'),_bs('Ajouter lentilles et bouillon puis cuire',25,type:'Cuisson'),_bs('Mixer finement et rectifier l’assaisonnement',5,type:'Mixer')],tags:['soupe','économique','lentilles']),
  _br('lib_leban_hummus','Houmous maison','Libanaise','Entrées',15,6,[ _bi('Pois chiches cuits',500,'g'),_bi('Tahini',80,'g'),_bi('Citron',2,'pièces'),_bi('Ail',1,'gousse'),_bi('Huile d’olive',3,'cuillères')],[ _bs('Mixer pois chiches, tahini, citron et ail',8,type:'Mixer'),_bs('Ajuster la texture avec un peu d’eau puis servir avec huile',4)],tags:['végétarien','apéritif','rapide']),
  _br('lib_us_pancakes','Pancakes moelleux','Américaine','Petit-déj',25,4,[ _bi('Farine',250,'g'),_bi('Lait',300,'ml'),_bi('Œufs',2,'pièces'),_bi('Sucre',30,'g'),_bi('Levure chimique',10,'g'),_bi('Beurre',30,'g')],[ _bs('Mélanger les ingrédients secs puis liquides',7),_bs('Laisser reposer la pâte',5,type:'Repos'),_bs('Cuire les pancakes à la poêle',12,type:'Cuisson')],tags:['brunch','enfants','goûter']),
];

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
        premiumNote(Icons.workspace_premium_rounded, 'Kitchen Assistant V12', 'Planning familial, courses automatiques, bibliothèque multi-cuisines et cuisson guidée dans une expérience simple.'),
        quickAction(context, Icons.auto_awesome_rounded, 'Smart Kitchen', 'Portions, timeline, recettes faisables et lancement cuisson', SmartKitchenPage(store: store)),
        quickAction(context, Icons.menu_book_rounded, 'Bibliothèque recettes', 'Recettes multi-cuisines prêtes à importer', RecipeLibraryPage(store: store)),
        quickAction(context, Icons.favorite_rounded, 'Favoris', 'Tes recettes préférées', FavoritesPage(store: store)),
        quickAction(context, Icons.kitchen_rounded, 'Frigo & péremptions', 'Scanner les dates, suivre les produits et recevoir des alertes', PantryExpiryPage(store: store)),
        quickAction(context, Icons.shopping_basket_rounded, 'Courses de la semaine', 'Quantités cumulées + suivi des achats', ShoppingPage(store: store)),
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


class PantryExpiryPage extends StatefulWidget {
  final Store store;
  const PantryExpiryPage({super.key, required this.store});
  @override State<PantryExpiryPage> createState()=>_PantryExpiryPageState();
}

class _PantryExpiryPageState extends State<PantryExpiryPage> {
  String filter='Tous';
  @override Widget build(BuildContext context){
    final items=[...widget.store.pantryProducts]..sort((a,b)=>a.expiryDate.compareTo(b.expiryDate));
    final visible=items.where((p)=>filter=='Tous'||(filter=='Urgent'&&p.daysLeft<=3)||(filter=='Expiré'&&p.daysLeft<0)||(filter=='OK'&&p.daysLeft>3)).toList();
    final urgent=items.where((p)=>p.daysLeft>=0&&p.daysLeft<=3).length;
    final expired=items.where((p)=>p.daysLeft<0).length;
    return Scaffold(
      appBar:AppBar(title:const Text('Frigo intelligent',style:TextStyle(fontWeight:FontWeight.w900))),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_openAdd(),backgroundColor:C.green,foregroundColor:Colors.white,icon:const Icon(Icons.document_scanner_rounded),label:const Text('Scanner produit')),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,4,20,110),children:[
        Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:C.ink,borderRadius:BorderRadius.circular(30)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(Icons.kitchen_rounded,color:C.gold,size:27),SizedBox(width:10),Expanded(child:Text('Rien ne se perd.',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)))]),
          const SizedBox(height:8),const Text('Scanne la date du produit. L’app te prévient 3 jours avant, la veille et le jour limite.',style:TextStyle(color:Color(0xFFF2E9DA),height:1.4,fontWeight:FontWeight.w700)),
          const SizedBox(height:18),Row(children:[_metric('${items.length}','Produits'),const SizedBox(width:10),_metric('$urgent','Urgents'),const SizedBox(width:10),_metric('$expired','Expirés')])
        ])),
        const SizedBox(height:18),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['Tous','Urgent','Expiré','OK'].map((x)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x)))).toList())),
        const SizedBox(height:14),
        if(visible.isEmpty) premiumEmpty(Icons.inventory_2_outlined,'Ton frigo est à jour','Ajoute un produit avec la caméra ou manuellement pour suivre sa date de péremption.'),
        ...visible.map(_productCard),
      ])
    );
  }

  Widget _metric(String n,String label)=>Expanded(child:Container(padding:const EdgeInsets.symmetric(vertical:12),decoration:BoxDecoration(color:Colors.white.withOpacity(.08),borderRadius:BorderRadius.circular(18)),child:Column(children:[Text(n,style:const TextStyle(color:C.gold,fontSize:22,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700))])));

  Widget _productCard(PantryProduct p){
    final d=p.daysLeft;
    final urgent=d<=3;
    final status=d<0?'Expiré ${d.abs()}j':d==0?'Aujourd’hui':d==1?'Demain':'Dans $d jours';
    final statusColor=d<0?C.red:urgent?C.terracotta:C.green;
    return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:C.card,borderRadius:BorderRadius.circular(24),border:Border.all(color:urgent?statusColor.withOpacity(.35):C.line)),child:Row(children:[
      Container(width:52,height:52,decoration:BoxDecoration(color:statusColor.withOpacity(.10),borderRadius:BorderRadius.circular(17)),child:Icon(urgent?Icons.warning_amber_rounded:Icons.eco_rounded,color:statusColor)),
      const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text('${fmt(p.qty)} ${p.unit} · ${p.category}',style:const TextStyle(color:C.muted,fontWeight:FontWeight.w700,fontSize:12)),const SizedBox(height:6),Row(children:[Icon(Icons.event_rounded,size:15,color:statusColor),const SizedBox(width:5),Text('${_date(p.expiryDate)} · $status',style:TextStyle(color:statusColor,fontWeight:FontWeight.w900,fontSize:12))])])),
      PopupMenuButton<String>(onSelected:(v){if(v=='edit')_openAdd(edit:p);if(v=='delete')widget.store.removePantryProduct(p).then((_)=>setState((){}));},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Modifier')),PopupMenuItem(value:'delete',child:Text('Supprimer'))])
    ]));
  }

  String _date(DateTime d)=>'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  Future<void> _openAdd({PantryProduct? edit}) async {
    final result=await Navigator.push<PantryProduct>(context,MaterialPageRoute(builder:(_)=>PantryProductEditor(existing:edit)));
    if(result!=null){await widget.store.upsertPantryProduct(result);if(mounted)setState((){});}
  }
}

class PantryProductEditor extends StatefulWidget {
  final PantryProduct? existing;
  const PantryProductEditor({super.key,this.existing});
  @override State<PantryProductEditor> createState()=>_PantryProductEditorState();
}

class _PantryProductEditorState extends State<PantryProductEditor>{
  late final TextEditingController name;
  late final TextEditingController qty;
  String unit='pièce',category='Autres';
  DateTime? expiry;
  bool scanning=false;
  String scanMessage='';
  final picker=ImagePicker();
  final units=['pièce','g','kg','ml','L','boîte','pot','sachet'];
  final cats=['Fruits & légumes','Viande & poisson','Produits frais','Produits laitiers','Épicerie','Surgelé','Boissons','Autres'];
  @override void initState(){super.initState();final p=widget.existing;name=TextEditingController(text:p?.name??'');qty=TextEditingController(text:p==null?'1':fmt(p.qty));unit=p?.unit??'pièce';category=p?.category??'Autres';expiry=p?.expiryDate;}
  @override void dispose(){name.dispose();qty.dispose();super.dispose();}

  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.existing==null?'Ajouter au frigo':'Modifier le produit',style:const TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,110),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[C.greenDark,C.green]),borderRadius:BorderRadius.circular(28)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Scanner la date',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:7),const Text('Cadre bien la mention EXP / DLC / DDM ou la date imprimée.',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w700)),const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:scanning?null:_scan,icon:scanning?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.camera_alt_rounded),label:Text(scanning?'Lecture en cours…':'Ouvrir la caméra'),style:FilledButton.styleFrom(backgroundColor:C.gold,foregroundColor:C.ink,padding:const EdgeInsets.symmetric(vertical:15)))) ,if(scanMessage.isNotEmpty)...[const SizedBox(height:10),Text(scanMessage,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:12))]])),
    const SizedBox(height:18),TextField(controller:name,decoration:inputDecoration('Nom du produit').copyWith(prefixIcon:const Icon(Icons.inventory_2_outlined))),const SizedBox(height:12),
    Row(children:[Expanded(child:TextField(controller:qty,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:inputDecoration('Quantité'))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(value:unit,items:units.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>unit=v!),decoration:inputDecoration('Unité')))]),const SizedBox(height:12),
    DropdownButtonFormField<String>(value:cats.contains(category)?category:'Autres',items:cats.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>category=v!),decoration:inputDecoration('Catégorie')),const SizedBox(height:12),
    InkWell(onTap:_pickDate,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:C.card,borderRadius:BorderRadius.circular(20),border:Border.all(color:C.line)),child:Row(children:[const Icon(Icons.event_available_rounded,color:C.green),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Date d’expiration',style:TextStyle(fontSize:12,color:C.muted,fontWeight:FontWeight.w700)),Text(expiry==null?'Choisir une date':_date(expiry!),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))])),const Icon(Icons.chevron_right_rounded)]))),
    const SizedBox(height:22),FilledButton.icon(onPressed:_save,icon:const Icon(Icons.notifications_active_rounded),label:const Text('Enregistrer + activer les alertes'),style:FilledButton.styleFrom(backgroundColor:C.green,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:17))),
  ]));

  String _date(DateTime d)=>'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  Future<void> _pickDate() async{final d=await showDatePicker(context:context,initialDate:expiry??DateTime.now().add(const Duration(days:7)),firstDate:DateTime.now().subtract(const Duration(days:365)),lastDate:DateTime.now().add(const Duration(days:3650)));if(d!=null)setState(()=>expiry=d);}

  Future<void> _scan() async{
    final x=await picker.pickImage(source:ImageSource.camera,imageQuality:92,maxWidth:2200);
    if(x==null)return;
    setState((){scanning=true;scanMessage='Analyse de l’étiquette…';});
    final recognizer=TextRecognizer(script:TextRecognitionScript.latin);
    try{
      final result=await recognizer.processImage(InputImage.fromFilePath(x.path));
      final dates=extractExpiryDates(result.text);
      if(dates.isEmpty){setState(()=>scanMessage='Aucune date fiable détectée. Tu peux la choisir manuellement.');return;}
      final now=DateTime.now();
      dates.sort((a,b)=>a.compareTo(b));
      final future=dates.where((d)=>!d.isBefore(DateTime(now.year,now.month,now.day).subtract(const Duration(days:1)))).toList();
      final candidate=(future.isNotEmpty?future.first:dates.last);
      if(mounted)setState((){expiry=candidate;scanMessage='Date détectée : ${_date(candidate)} ✓ Vérifie puis enregistre.';});
    } catch(_){if(mounted)setState(()=>scanMessage='Lecture impossible sur cette photo. Reprends-la de plus près ou saisis la date.');}
    finally{await recognizer.close();if(mounted)setState(()=>scanning=false);}
  }

  void _save(){
    if(name.text.trim().isEmpty||expiry==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Ajoute le nom du produit et sa date.')));return;}
    final q=double.tryParse(qty.text.replaceAll(',','.'))??1;
    Navigator.pop(context,PantryProduct(id:widget.existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),qty:q,unit:unit,category:category,expiryDate:expiry!,addedAt:widget.existing?.addedAt,opened:widget.existing?.opened??false));
  }
}

class SmartKitchenPage extends StatefulWidget {
  final Store store;
  const SmartKitchenPage({super.key, required this.store});
  @override
  State<SmartKitchenPage> createState() => _SmartKitchenPageState();
}

class _SmartKitchenPageState extends State<SmartKitchenPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final recipes = widget.store.recipes.where((r) => r.title.toLowerCase().contains(query.toLowerCase())).toList();
    final ready = [...recipes]..sort((a,b) => pantryScore(b).compareTo(pantryScore(a)));
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Kitchen V11', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(30)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children:[Icon(Icons.auto_awesome_rounded,color:C.gold),SizedBox(width:10),Text('Assistant cuisine',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900))]),
              SizedBox(height:10),
              Text('Choisis une recette, adapte les portions, fixe l’heure de service et suis une timeline calculée automatiquement.', style: TextStyle(color: Color(0xFFF3EBDD), height: 1.4, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(onChanged:(v)=>setState(()=>query=v), decoration: inputDecoration('Rechercher une recette').copyWith(prefixIcon: const Icon(Icons.search_rounded))),
          const SizedBox(height: 16),
          premiumNote(Icons.kitchen_rounded, 'Recettes faisables maintenant', 'Le score utilise les ingrédients marqués comme déjà disponibles dans ta cuisine.'),
          ...ready.map((r) {
            final score = pantryScore(r);
            final missing = r.ingredients.where((i)=>!i.have).length;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: soft(radius:24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap:()=>Navigator.push(context, MaterialPageRoute(builder:(_)=>RecipeSmartKitchenPage(store:widget.store,recipe:r))),
                child: Row(children:[
                  Container(width:54,height:54,decoration:BoxDecoration(color:C.green.withOpacity(.10),borderRadius:BorderRadius.circular(18)),child:Center(child:Text('${(score*100).round()}%',style:const TextStyle(fontWeight:FontWeight.w900,color:C.green)))),
                  const SizedBox(width:12),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r.title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text(missing==0?'Tout est disponible':'$missing ingrédient(s) manquant(s)',style:TextStyle(color:missing==0?C.green:C.terracotta,fontWeight:FontWeight.w700))])),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
  double pantryScore(Recipe r) {
    if (r.ingredients.isEmpty) return 0;
    return r.ingredients.where((i)=>i.have).length / r.ingredients.length;
  }
}

class RecipeSmartKitchenPage extends StatefulWidget {
  final Store store;
  final Recipe recipe;
  const RecipeSmartKitchenPage({super.key, required this.store, required this.recipe});
  @override
  State<RecipeSmartKitchenPage> createState() => _RecipeSmartKitchenPageState();
}

class _RecipeSmartKitchenPageState extends State<RecipeSmartKitchenPage> {
  late int servings;
  late TimeOfDay serveAt;
  @override
  void initState(){
    super.initState();
    servings = widget.recipe.servings <= 0 ? 1 : widget.recipe.servings;
    final now=DateTime.now().add(Duration(minutes: widget.recipe.minutes + 30));
    serveAt=TimeOfDay(hour:now.hour,minute:now.minute);
  }
  double get factor => servings / (widget.recipe.servings <= 0 ? 1 : widget.recipe.servings);
  Future<void> chooseTime() async {
    final t=await showTimePicker(context:context,initialTime:serveAt);
    if(t!=null)setState(()=>serveAt=t);
  }
  DateTime targetDateTime(){
    final now=DateTime.now();
    var target=DateTime(now.year,now.month,now.day,serveAt.hour,serveAt.minute);
    if(target.isBefore(now)) target=target.add(const Duration(days:1));
    return target;
  }
  List<_KitchenTimelineItem> timeline(){
    final steps=widget.recipe.steps;
    var cursor=targetDateTime();
    final out=<_KitchenTimelineItem>[];
    for(final st in steps.reversed){
      final duration=Duration(seconds:st.totalSeconds);
      final start=cursor.subtract(duration);
      out.add(_KitchenTimelineItem(step:st,start:start,end:cursor));
      cursor=start;
    }
    return out.reversed.toList();
  }
  String clock(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  @override
  Widget build(BuildContext context){
    final r=widget.recipe;
    final items=timeline();
    final start=items.isEmpty?targetDateTime():items.first.start;
    final now=DateTime.now();
    final until=start.difference(now);
    return Scaffold(
      appBar:AppBar(title:Text(r.title,style:const TextStyle(fontWeight:FontWeight.w900))),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,0,20,110),children:[
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:C.ink,borderRadius:BorderRadius.circular(30)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('SMART KITCHEN',style:TextStyle(color:C.gold,fontWeight:FontWeight.w900,letterSpacing:1.2)),
          const SizedBox(height:8),
          Text('Prêt à ${serveAt.format(context)}',style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),
          const SizedBox(height:6),
          Text(until.inMinutes>0?'Commence dans environ ${until.inMinutes} min':'Tu peux commencer maintenant',style:const TextStyle(color:Color(0xFFF1E8D9),fontWeight:FontWeight.w700)),
        ])),
        const SizedBox(height:16),
        Row(children:[
          Expanded(child:Container(padding:const EdgeInsets.all(14),decoration:soft(radius:22),child:Column(children:[const Text('PORTIONS',style:TextStyle(color:C.muted,fontWeight:FontWeight.w800)),const SizedBox(height:8),Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton.filledTonal(onPressed:servings<=1?null:()=>setState(()=>servings--),icon:const Icon(Icons.remove)),Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Text('$servings',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900))),IconButton.filledTonal(onPressed:()=>setState(()=>servings++),icon:const Icon(Icons.add))])]))),
          const SizedBox(width:10),
          Expanded(child:InkWell(onTap:chooseTime,borderRadius:BorderRadius.circular(22),child:Container(padding:const EdgeInsets.all(14),decoration:soft(radius:22),child:Column(children:[const Text('SERVICE',style:TextStyle(color:C.muted,fontWeight:FontWeight.w800)),const SizedBox(height:12),Text(serveAt.format(context),style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const Text('modifier',style:TextStyle(color:C.green,fontWeight:FontWeight.w700))])))),
        ]),
        const SizedBox(height:18),
        Text('Ingrédients pour $servings personne(s)',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        ...r.ingredients.map((i)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),decoration:soft(radius:18),child:Row(children:[Icon(i.have?Icons.check_circle_rounded:Icons.circle_outlined,color:i.have?C.green:C.muted),const SizedBox(width:10),Expanded(child:Text(i.name,style:const TextStyle(fontWeight:FontWeight.w800))),Text('${fmt(i.qty*factor)} ${i.unit}',style:const TextStyle(fontWeight:FontWeight.w900,color:C.terracotta))]))),
        const SizedBox(height:18),
        Row(children:[const Expanded(child:Text('Timeline calculée',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))),Text('Prêt ${serveAt.format(context)}',style:const TextStyle(color:C.green,fontWeight:FontWeight.w800))]),
        const SizedBox(height:10),
        if(items.isEmpty) premiumNote(Icons.info_outline_rounded,'Aucune étape','Ajoute des étapes de préparation pour générer la timeline.'),
        ...items.asMap().entries.map((e){ final it=e.value; return Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),decoration:soft(radius:20),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:62,padding:const EdgeInsets.symmetric(vertical:8),decoration:BoxDecoration(color:C.green.withOpacity(.10),borderRadius:BorderRadius.circular(14)),child:Text(clock(it.start),textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w900,color:C.green))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${e.key+1}. ${it.step.title}',style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:4),Text('${it.step.minutes} min${it.step.temp>0?' · ${it.step.temp}°C':''}${it.step.type.isNotEmpty?' · ${it.step.type}':''}',style:const TextStyle(color:C.muted,fontWeight:FontWeight.w700)),if(it.step.note.isNotEmpty)Padding(padding:const EdgeInsets.only(top:5),child:Text(it.step.note,style:const TextStyle(color:C.terracotta,fontWeight:FontWeight.w700)))]))]));}),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:r.steps.isEmpty?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CookingPage(recipe:r,store:widget.store))),icon:const Icon(Icons.local_fire_department_rounded),label:const Text('Lancer la cuisson guidée'),style:mainButtonStyle()),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ShoppingPage(store:widget.store,recipe:r))),icon:const Icon(Icons.shopping_bag_outlined),label:const Text('Voir les ingrédients manquants'),style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)))),
      ]),
    );
  }
}

class _KitchenTimelineItem {
  final CookStep step;
  final DateTime start;
  final DateTime end;
  const _KitchenTimelineItem({required this.step,required this.start,required this.end});
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

BoxDecoration soft({double radius = 24}) => BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(radius), border: Border.all(color: C.line), boxShadow: shadow());
List<BoxShadow> shadow() => [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 24, offset: const Offset(0, 10))];

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
