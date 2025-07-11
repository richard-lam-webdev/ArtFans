# 🛠️ Guide d'Installation - ArtFans

## Prérequis

### Système
- **Git** (pour cloner le repository)
- **Docker** et **Docker Compose** (recommandé)
- **Make** (optionnel, pour les commandes simplifiées)

### Pour le développement local (sans Docker)
- **Go 1.21+** 
- **Flutter 3.16+**
- **PostgreSQL 15+**
- **Node.js 18+** (pour certains outils de build)

## 🚀 Installation Rapide avec Docker

### 1. Cloner le Repository

```bash
git clone https://github.com/richard-lam-webdev/ArtFans.git
cd ArtFans
```

### 2. Configuration des Variables d'Environnement

Créer les fichiers de configuration :

```bash
# Backend
cp backend/.env.example backend/.env
# Frontend
cp frontend/.env.example frontend/.env
```

### 3. Configuration Backend (.env)

```env
# Base de données
DATABASE_URL=postgres://artfans_user:artfans_password@db:5432/artfans_db
POSTGRES_USER=artfans_user
POSTGRES_PASSWORD=artfans_password
POSTGRES_DB=artfans_db
POSTGRES_PORT=5432

# JWT
JWT_SECRET=your_super_secret_jwt_key_here_minimum_32_chars

# Upload
UPLOAD_PATH=/uploads

# Serveur
PORT=8080
GIN_MODE=release

# Monitoring (optionnel)
SENTRY_DSN=your_sentry_dsn_here
```

### 4. Configuration Frontend (.env)

```env
# API Backend
FLUTTER_WEB_API_URL=http://localhost:8080
ANDROID_API_URL=http://10.0.2.2:8080

# Configuration build
FLUTTER_WEB_RENDERER=html
```

### 5. Lancement des Services

```bash
# Lancement complet avec monitoring
docker-compose up -d

# Ou sans monitoring (plus léger)
docker-compose up -d db api app
```

### 6. Initialisation de la Base de Données

```bash
# Exécuter les migrations
docker-compose run --rm api go run ./cmd/initdb/main.go
```

## 🔧 Installation pour le Développement

### 1. Installation Backend (Go)

```bash
cd backend

# Installation des dépendances
go mod download

# Configuration de la base de données locale
createdb artfans_db
psql -d artfans_db -f database/migrations/init.sql

# Variables d'environnement pour dev local
export DATABASE_URL="postgres://username:password@localhost:5432/artfans_db"
export JWT_SECRET="dev_secret_key_minimum_32_characters"
export UPLOAD_PATH="./uploads"
export PORT="8080"

# Lancement en mode développement
go run cmd/server/main.go
```

### 2. Installation Frontend (Flutter)

```bash
cd frontend

# Installation des dépendances Flutter
flutter pub get

# Génération des fichiers (si nécessaire)
flutter packages pub run build_runner build

# Pour le développement Web
flutter run -d chrome --web-port 3000

# Pour le développement Mobile (avec émulateur Android)
flutter run

# Build de production
flutter build web
flutter build apk
```

## 🐳 Commandes Docker Utiles

### Gestion des Services

```bash
# Voir les logs
docker-compose logs -f api
docker-compose logs -f app

# Rebuild après modifications
docker-compose build api
docker-compose build app

# Redémarrer un service
docker-compose restart api

# Entrer dans un conteneur
docker-compose exec api bash
docker-compose exec app sh
```

### Nettoyage

```bash
# Arrêter tous les services
docker-compose down

# Supprimer les volumes (⚠️ perte de données)
docker-compose down -v

# Nettoyer les images
docker system prune -f
```

## 📊 Vérification de l'Installation

### URLs de Vérification

Après installation, vérifiez que ces URLs fonctionnent :

- **Frontend Web** : http://localhost:3000
- **API Backend** : http://localhost:8080/health
- **API Swagger** : http://localhost:8080/docs (si activé)
- **Grafana** : http://localhost:3001 (admin/admin)
- **Prometheus** : http://localhost:9090

### Tests de Base

```bash
# Test de l'API
curl http://localhost:8080/health

# Test de connexion DB
docker-compose exec api go run ./cmd/healthcheck/main.go

# Test frontend
curl http://localhost:3000
```

## 🔍 Résolution de Problèmes

### Problèmes Courants

#### 1. Erreur de Port Occupé
```bash
# Vérifier les ports utilisés
netstat -tlnp | grep :8080
netstat -tlnp | grep :3000

# Modifier les ports dans docker-compose.yml si nécessaire
```

#### 2. Problème de Permissions Upload
```bash
# Créer le dossier uploads avec bonnes permissions
mkdir -p uploads
chmod 755 uploads
```

#### 3. Erreur Base de Données
```bash
# Vérifier la connexion PostgreSQL
docker-compose logs db

# Reset de la base
docker-compose down -v
docker-compose up -d db
```

#### 4. Problème Flutter Web
```bash
# Nettoyer le cache Flutter
flutter clean
flutter pub get

# Rebuild complet
flutter build web --release
```

### Logs de Debug

```bash
# Logs détaillés backend
docker-compose logs -f --tail=100 api

# Logs détaillés frontend
docker-compose logs -f --tail=100 app

# Logs de la base de données
docker-compose logs -f --tail=50 db
```

## 📱 Build Mobile (Android)

### Prérequis Android
- Android Studio avec SDK
- Java 11+
- Variables d'environnement Android configurées

### Build APK

```bash
cd frontend

# Build debug
flutter build apk --debug

# Build release
flutter build apk --release

# APK générés dans : build/app/outputs/flutter-apk/
```

### Configuration de Signature (Production)

```bash
# Créer le keystore
keytool -genkey -v -keystore android/app/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias artfans

# Configurer android/app/build.gradle pour la signature
```

## ⚡ Mode Développement Rapide

Pour un développement rapide sans Docker :

```bash
# Terminal 1 - Backend
cd backend && go run cmd/server/main.go

# Terminal 2 - Frontend
cd frontend && flutter run -d chrome --web-port 3000

# Terminal 3 - Base de données (Docker uniquement)
docker-compose up -d db
```

---

✅ **Installation terminée !** Consultez [DEVELOPMENT.md](./DEVELOPMENT.md) pour les workflows de développement.