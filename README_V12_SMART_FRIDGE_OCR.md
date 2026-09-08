# Recette Alarm V12 — Smart Fridge OCR Premium

## Nouveautés

- Frigo intelligent avec inventaire des produits.
- Ajout rapide d’un produit par caméra.
- OCR local ML Kit pour lire les dates imprimées sur les emballages.
- Détection de formats JJ/MM/AAAA, JJ-MM-AA, JJ.MM.AAAA, AAAA-MM-JJ et dates avec mois en lettres.
- Validation manuelle systématiquement disponible si l’étiquette est difficile à lire.
- Alertes de péremption à J-3, J-1 et le jour de la date limite.
- Alerte immédiate lors de l’ajout d’un produit déjà expiré.
- Filtres Tous / Urgent / Expiré / OK.
- Quantité, unité et catégorie pour chaque produit.
- Sauvegarde/import/export du frigo avec le reste des données.
- UI premium cohérente avec Family Chef V11.

## Notes OCR
La lecture caméra est une aide : l’utilisateur doit toujours vérifier la date détectée avant enregistrement. Les impressions peu contrastées, courbes ou abîmées peuvent nécessiter une saisie manuelle.

## Build Android
Le workflow GitHub recrée le projet Android, ajoute la permission caméra, compileSdk/targetSdk 35 et génère l’artefact `recette-alarm-v12-smart-fridge-premium-apk`.
