# Recette Alarm V11 — Family Chef Premium

V11 transforme l'application en assistant de cuisine familial et professionnel : planning hebdomadaire, quantités calculées, panier intelligent, suivi d'achats, rappels et bibliothèque de recettes locale importable.

## Navigation principale

- Accueil : carnet personnel et Smart Kitchen.
- Semaine : planning des 7 jours avec petit-déjeuner, déjeuner, casse-croûte et dîner.
- Courses : agrégation automatique de tous les ingrédients planifiés.
- Bibliothèque : catalogue local multi-cuisines prêt à importer.
- Plus : favoris, dashboard, timers, réglages, sauvegarde et outils.

## Planning et quantités

Chaque repas planifié possède son propre nombre de personnes. Les ingrédients sont recalculés avec le ratio `portions planifiées / portions de la recette`, puis les produits portant le même nom et la même unité sont regroupés.

Exemple : deux repas utilisent des tomates. Les quantités sont additionnées dans une seule ligne de courses.

## Panier intelligent

- Quantité totale par produit.
- Indication du nombre de recettes concernées.
- Statut acheté / à acheter persistant.
- Progression globale en pourcentage.
- Filtres À acheter / Acheté / Tout.
- Regroupement visuel Fruits & légumes, Viandes & poisson, Produits frais, Épicerie, Boulangerie et Autres.
- Copie de la liste restante dans le presse-papiers.
- Réinitialisation des achats pour une nouvelle semaine sans effacer le planning.

## Notification hebdomadaire

Le bouton Rappel courses active une notification locale répétée chaque semaine. Le workflow Android V11 ajoute `RECEIVE_BOOT_COMPLETED` et les receivers nécessaires à `flutter_local_notifications` pour les notifications programmées.

## Bibliothèque locale

La V11 contient 29 recettes complètes issues de 16 univers culinaires : marocaine, française, italienne, espagnole, thaïlandaise, asiatique, japonaise, indienne, mexicaine, grecque, méditerranéenne, healthy, petit-déjeuner, turque, libanaise et américaine.

Chaque entrée contient : cuisine, catégorie, tags, temps, portions, difficulté, ingrédients avec quantités et étapes de préparation. Une recette peut être prévisualisée puis importée en un clic dans le carnet utilisateur.

La bibliothèque est volontairement séparée du carnet personnel et utilise des identifiants `lib_*`. Cela permet de remplacer ultérieurement `builtInRecipeLibrary()` par une source distante/API sans modifier le planning ou le carnet utilisateur.

## Version

`1.1.0+1100`

## APK GitHub Actions

Le workflow `.github/workflows/android.yml` génère l'artefact :

`recette-alarm-v11-family-chef-premium-apk`
