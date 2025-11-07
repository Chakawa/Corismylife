# Instructions pour créer flex_emprunteur_data.json

## Structure du fichier JSON

Le fichier `flex_emprunteur_data.json` doit avoir la structure suivante :

```json
{
  "tarifsPretAmortissable": {
    "18_12": 0.150,
    "18_24": 0.295,
    "18_36": 0.446,
    ...
  },
  "tarifsPretDecouvert": {
    "18_12": 0.272,
    "18_24": 0.562,
    "18_36": 0.831,
    ...
  },
  "tarifsPerteEmploi": {
    "1": 19.20,
    "2": 38.40,
    "3": 57.60,
    "4": 76.80,
    "5": 96.00,
    "6": 115.20
  }
}
```

## Format des données

### tarifsPretAmortissable et tarifsPretDecouvert
- **Clé**: Format `"age_dureeMois"` (ex: `"18_12"`, `"25_60"`)
  - `age`: Âge de l'emprunteur (18 à 65 ans)
  - `dureeMois`: Durée du prêt en mois (12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132, 144, 156, 168, 180)
- **Valeur**: Taux en pourcentage (ex: `0.150` = 0.15%)

### tarifsPerteEmploi
- **Clé**: Durée en années (string: `"1"`, `"2"`, `"3"`, `"4"`, `"5"`, `"6"`)
- **Valeur**: Montant fixe (ex: `19.20`, `38.40`, etc.)

## Source des données

Les données doivent être extraites du fichier :
`mycorislife-master/lib/features/simulation/presentation/screens/flex_emprunteur_page.dart`

Les Maps suivantes contiennent les données :
- `tarifsPretAmortissable` (lignes ~35-273)
- `tarifsPretDecouvert` (lignes ~276-514)
- `tarifsPerteEmploi` (lignes ~517-524)

## Note importante

Le script de migration échouera si ce fichier n'existe pas. Créez-le manuellement en extrayant les données du code Dart, ou utilisez un script d'extraction automatique.








