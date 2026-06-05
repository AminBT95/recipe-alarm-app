# Recette Alarm Pro

Application Android native Java pour enregistrer des recettes, ingrédients, étapes, mode cuisine et alarmes anti-brûlure.

## Fonctions incluses
- Recettes dynamiques sauvegardées en SQLite local
- Ingrédients avec quantités et unités
- Étapes avec durée et note sécurité
- Mode cuisine avec écran toujours allumé
- Alarmes Android exactes, vibration, sonnerie et notification plein écran
- Rappel +5 minutes
- Admin simple: ajouter/modifier recettes, ingrédients, étapes
- Liste de courses automatique à partager

## Générer APK avec GitHub
1. Uploader tout le contenu dans le repository.
2. Créer aussi `.github/workflows/android.yml` si GitHub ne l'a pas uploadé.
3. Aller dans **Actions**.
4. Lancer **Build Android APK**.
5. Télécharger l'artifact `RecetteAlarm-debug-apk`.
