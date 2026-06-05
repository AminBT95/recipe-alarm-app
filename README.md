# Recette Alarm

Application Android native pour gérer des recettes, ingrédients, étapes et alarmes de cuisson anti-brûlure.

## Fonctions incluses
- Ajout dynamique des recettes
- Ingrédients avec quantités et unités
- Étapes avec durée et note anti-brûlure
- Mode cuisine
- AlarmManager Android pour alarmes exactes
- Notification + écran plein écran + sonnerie + vibration
- Administration simple : export JSON, reset exemples
- Stockage local dans le téléphone via SharedPreferences

## Générer l'APK sans Android Studio
1. Crée un repository GitHub
2. Upload tous les fichiers de ce ZIP dans le repository
3. Va dans l'onglet Actions
4. Lance **Build Android APK**
5. Quand c'est terminé, télécharge l'artifact **RecetteAlarm-debug-apk**
6. Installe `app-debug.apk` sur Android

## Notes
Sur certains téléphones, il faut autoriser les notifications et les alarmes exactes dans les paramètres Android.
