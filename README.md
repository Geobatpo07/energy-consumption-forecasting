# 📊 Prédiction de la Consommation d'Énergie avec des RNN
## 🔍 Description du projet
Ce projet vise à prédire la consommation d’énergie électrique en utilisant des Réseaux de Neurones Récurrents (RNN), notamment des LSTM et GRU, en langage R. Les données utilisées proviennent de sources open-source telles que ENTSO-E ou RTE Open Data.

## 📁 Structure du projet
```
📂 energy-consumption-forecasting
│── 📂 data/                # Données brutes et prétraitées
│   ├── raw/               # Données brutes téléchargées (ex: .csv, .json)
│   ├── processed/         # Données transformées et prêtes pour l'entraînement
│── 📂 notebooks/           # Scripts d'exploration et d'analyse
│   ├── 01_exploration.Rmd # Analyse exploratoire des données
│   ├── 02_preprocessing.R # Prétraitement et feature engineering
│   ├── 03_modeling.R      # Implémentation des RNN (LSTM/GRU)
│   ├── 04_evaluation.R    # Évaluation du modèle
│── 📂 models/              # Modèles entraînés et checkpoints
│   ├── lstm_model.h5      # Modèle LSTM sauvegardé
│   ├── gru_model.h5       # Modèle GRU sauvegardé
│── 📂 scripts/             # Scripts réutilisables
│   ├── fetch_data.R       # Script pour télécharger les données
│   ├── train_model.R      # Script pour entraîner le modèle
│   ├── predict.R          # Script pour faire des prédictions
│── 📂 app/                 # Application Shiny pour visualiser les prévisions
│   ├── ui.R               # Interface utilisateur Shiny
│   ├── server.R           # Logique backend Shiny
│── 📂 reports/             # Rapports et visualisations
│   ├── results.md         # Analyse des performances
│   ├── figures/           # Graphiques et visualisations
│── 📂 api/                 # API pour servir les prédictions (Plumber)
│   ├── plumber.R          # Endpoint API
│── .gitignore             # Fichiers à ignorer (ex: .Rdata, .h5, .csv volumineux)
│── README.md              # Présentation du projet
│── requirements.txt       # Packages R nécessaires (via `renv` ou `pak`)
│── LICENSE                # Licence du projet
```

## 🚀 Technologies utilisées
- R : Langage principal
- Keras & TensorFlow : Implémentation des RNN (LSTM, GRU)
- tidyverse : Manipulation et visualisation des données
- tsibble & lubridate : Gestion des séries temporelles
- Plumber : Déploiement d'une API pour servir les prédictions
- Shiny : Application interactive pour visualiser les prévisions

## 📊 Données utilisées
Les données proviennent de :

- ENTSO-E Transparency Platform : https://transparency.entsoe.eu/
- RTE Open Data : https://data.rte-france.com/
- Données météorologiques via API OpenWeather ou Météo-France

## 🔧 Installation

### 1. Cloner ce dépôt GitHub

```r
git clone https://github.com/ton-utilisateur/energy-consumption-forecasting.git 
cd energy-consumption-forecasting
```

### 2. Installer les dépendances

Dans R :

```r
install.packages(c("tidyverse", "keras", "tensorflow", "tsibble", "lubridate", "shiny", "plumber"))
```

Ou avec `renv` :

```r
renv::restore()
```

## 📈 Résultats attendus
Le modèle prédit la consommation d’électricité avec une bonne précision et permet d’analyser les tendances à court et long terme. L’application Shiny permet de visualiser les prévisions.

## Auteurs
- **Geovany Batista Polo LAGUERRE** - Data Science & Analytics Engineer

## Licence
Ce projet est sous licence MIT.

