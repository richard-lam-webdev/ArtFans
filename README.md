# ArtFans - Plateforme de Contenu Créatif Premium

![ArtFans Logo]
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)

## 📖 Description

ArtFans est une plateforme innovante qui permet aux créateurs de contenu de monétiser leur communauté et leur savoir-faire. Elle offre un système d'abonnement premium permettant aux créateurs d'interagir avec leurs abonnés, de proposer des contenus exclusifs et de gérer des paiements sécurisés.

## 🎯 Objectifs du Projet

Ce projet simule le cycle complet du développement logiciel en environnement professionnel, en mettant l'accent sur :
- La gestion de projet en équipe
- L'architecture technique moderne
- Le développement full-stack avec Go et Flutter
- La mise en production avec CI/CD

## 🏗️ Architecture

```
ArtFans/
├── backend/          # API Go avec Gin Framework
├── frontend/         # Application Flutter (Mobile & Web)
├── monitoring/       # Stack Grafana/Prometheus/Loki
├── .github/          # Workflows CI/CD
└── docker-compose.yml
```

## 🚀 Technologies

### Backend
- **Go** avec Gin Framework
- **PostgreSQL** pour la base de données
- **JWT** pour l'authentification
- **Docker** pour la containerisation

### Frontend
- **Flutter** pour Mobile (Android) et Web
- **Go Router** pour la navigation
- **Provider** pour la gestion d'état
- Support responsive multi-plateforme

### DevOps & Monitoring
- **Docker Compose** pour l'orchestration
- **GitHub Actions** pour CI/CD
- **Grafana/Prometheus/Loki** pour le monitoring
- **Sentry** pour le tracking d'erreurs

## 📋 Fonctionnalités Principales

### ✅ Implémentées

#### 🔐 Authentification et Gestion des Profils
- [x] Inscription/Connexion sécurisée
- [x] Trois types d'utilisateurs : Créateurs, Abonnés, Administrateurs
- [x] Gestion des profils personnalisés
- [x] Système de rôles et permissions

#### 📱 Gestion de Contenu
- [x] CRUD complet des contenus
- [x] Upload de fichiers (images)
- [x] Visibilité publique/premium
- [x] Modération par les administrateurs
- [x] Système de prix personnalisables

#### 💰 Système d'Abonnement
- [x] Abonnements créateur
- [x] Gestion des paiements
- [x] Accès conditionnel au contenu premium

#### 💬 Interactions Sociales
- [x] Système de commentaires
- [x] Likes sur contenus et commentaires
- [x] Messages privés entre utilisateurs
- [x] Fils d'actualité personnalisés

#### 📊 Tableaux de Bord
- [x] Dashboard créateur avec statistiques
- [x] Dashboard administrateur
- [x] Métriques et KPIs avancés
- [x] Classements top/flop

### 🔄 Fonctionnalités Avancées
- [x] Feature flags pour activer/désactiver les fonctionnalités
- [x] Système de logs structurés
- [x] Tests unitaires et d'intégration
- [x] CI/CD automatisé
- [x] Monitoring temps réel

## 🛠️ Installation et Lancement

Consultez les fichiers spécialisés pour les instructions détaillées :
- [Installation](./docs/INSTALLATION.md)
- [Développement Local](./docs/DEVELOPMENT.md)
- [Déploiement](./docs/DEPLOYMENT.md)

## 👥 Équipe

Consultez [TEAM.md](./docs/TEAM.md) pour la répartition des tâches et les contributions de chaque membre.

## 📚 Documentation

- [Architecture](./docs/ARCHITECTURE.md)
- [API Documentation](./docs/API.md)
- [Base de Données](./docs/DATABASE.md)
- [Tests](./docs/TESTS.md)
- [Monitoring](./docs/MONITORING.md)

## 🏃‍♂️ Démarrage Rapide

```bash
# Cloner le repository
git clone https://github.com/richard-lam-webdev/ArtFans.git
cd ArtFans

# Lancer avec Docker Compose
docker-compose up -d

# L'application sera disponible sur :
# - Frontend Web: http://localhost:3000
# - API Backend: http://localhost:8080
# - Grafana: http://localhost:3001
```

## 📱 APK Android

Téléchargez l’APK Android signé ici :  
[releases/android/app-release.apk](releases/android/app-release.apk)

Pour l’installer sur un appareil connecté via ADB :

```bash
adb install releases/android/app-release.apk

## 📄 Licence

Ce projet est développé dans le cadre d'un PEC (Projet d'Étude de Cas) académique.

## 🔗 Liens Utiles

- [Repository GitHub](https://github.com/richard-lam-webdev/ArtFans)
- [Cahier des charges]
fichier dans la racine du projet.
- [Demo Live](#) (artfans.ddasilva.fr)
---

