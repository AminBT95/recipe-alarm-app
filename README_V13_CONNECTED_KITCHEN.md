# Recette Alarm V13 — Connected Kitchen Premium

Version: 1.3.0+1300

## V13
- Correction du bouton Accueil > Cette semaine : ouvre désormais directement l'onglet Semaine.
- Navigation basse persistante grâce à un Navigator indépendant par onglet. Retaper un onglet revient à sa racine.
- OCR péremption amélioré : caméra + galerie, résolution supérieure, formats DD/MM/YYYY, YYYY-MM-DD, dates compactes, mois en lettres, mois/année après EXP/DLC/DDM, chiffres arabes/persans normalisés, priorité aux lignes EXP/DLC/DDM et choix utilisateur si plusieurs dates sont détectées.
- Courses intelligentes V13 : quantités planifiées cumulées puis stock non expiré du frigo déduit quand produit/unité correspondent.
- Bibliothèque locale enrichie à 46 recettes de cuisines variées.
- Photos de plats pour les recettes de bibliothèque via images réseau, avec fallback local premium si hors connexion.
- Convertisseur Pro : g/kg/ml/L/verre/tasse/càs/càc et densités alimentaires (eau, farine, sucre, sucre glace, riz, huile, lait, miel, beurre, cacao).
- Nouveau module Anti-gaspi : produits à consommer sous 5 jours + recettes qui utilisent ces produits.
- UI/UX : hiérarchie plus directe, actions accessibles depuis les onglets permanents, réduction des retours arrière.

## Build Android
Workflow: `.github/workflows/android.yml`
Flutter: 3.24.5
Artifact: `recette-alarm-v13-connected-kitchen-premium-apk`

Le workflow recrée le dossier Android, applique compile/target SDK 35, minSdk 23, Java 17/desugaring, permissions caméra/notifications/internet et construit l'APK debug.
