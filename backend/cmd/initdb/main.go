package main

import (
	"log"
	"os"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

type User struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	Username       string    `gorm:"column:username;unique;not null"`
	Email          string    `gorm:"unique;not null"`
	HashedPassword string    `gorm:"column:hashed_password;not null"`
	Role           string    `gorm:"type:role;not null"`
	CreatedAt      time.Time `gorm:"column:created_at;autoCreateTime"`
	SIRET          string    `gorm:"size:14"`
	LegalStatus    string
	LegalName      string
	Address        string
	Country        string
	VATNumber      string
	BirthDate      *time.Time
}

// ✨ CORRIGÉ : Subscription avec les bons types et champs
type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID    uuid.UUID `gorm:"type:uuid;not null;index" json:"creator_id"`    // ✨ CORRIGÉ
	SubscriberID uuid.UUID `gorm:"type:uuid;not null;index" json:"subscriber_id"` // ✨ CORRIGÉ
	StartDate    time.Time `gorm:"column:start_date;not null"`
	EndDate      time.Time `gorm:"column:end_date;not null"`
	PaymentID    uuid.UUID `gorm:"type:uuid;not null"`
	Price        int       `gorm:"column:price;default:3000;not null" json:"price"`       // ✨ AJOUTÉ
	Status       string    `gorm:"column:status;default:'active';not null" json:"status"` // ✨ AJOUTÉ
	CreatedAt    time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`    // ✨ AJOUTÉ
}

type Payment struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID `gorm:"type:uuid;not null"` // ✨ CORRIGÉ
	Amount         int64     `gorm:"column:amount;not null"`
	PaidAt         time.Time `gorm:"column:paid_at;not null"`
	Status         string    `gorm:"column:status;type:payment_status;not null"`
}

// ✨ CORRIGÉ : Content avec le bon type pour creator_id
type Content struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID uuid.UUID `gorm:"type:uuid;not null;index" json:"creator_id"`
	CreatorID uuid.UUID `gorm:"type:uuid;not null;index" json:"creator_id"` // ✨ CORRIGÉ
	Title     string    `gorm:"not null"`
	Body      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
	Price     int64     `gorm:"column:price;not null"`
	IsBlurred bool      `gorm:"column:is_blurred;default:false"`
	FilePath  string    `gorm:"column:file_path;not null"`
	Status    string    `gorm:"type:content_status;default:'pending';not null" json:"status"` // ✨ AJOUTÉ si besoin
}

type Comment struct {
	ID        uuid.UUID  `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID  `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	AuthorID  uuid.UUID  `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	Text      string     `gorm:"not null"`
	CreatedAt time.Time  `gorm:"column:created_at;autoCreateTime"`
	ParentID  *uuid.UUID `gorm:"type:uuid;index"`
}

type CommentLike struct {
	UserID    uuid.UUID `gorm:"column:user_id;type:uuid;not null;primaryKey"`
	CommentID uuid.UUID `gorm:"column:comment_id;type:uuid;not null;primaryKey"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

type Like struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	UserID    uuid.UUID `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

type Message struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SenderID   uuid.UUID `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	ReceiverID uuid.UUID `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	Text       string    `gorm:"not null"`
	SentAt     time.Time `gorm:"column:sent_at;autoCreateTime"`
}

type Report struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	TargetContentID uuid.UUID `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	ReporterID      uuid.UUID `gorm:"type:uuid;not null;index"` // ✨ CORRIGÉ
	Reason          string    `gorm:"not null"`
	CreatedAt       time.Time `gorm:"column:created_at;autoCreateTime"`
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL must be defined")
	}

	db, err := gorm.Open(
		postgres.Open(dsn),
		&gorm.Config{
			NamingStrategy: schema.NamingStrategy{
				SingularTable: true,
			},
			Logger:                                   logger.Default.LogMode(logger.Info),
			DisableForeignKeyConstraintWhenMigrating: true, // ✨ AJOUTÉ pour éviter les conflits
		},
	)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	log.Println("🔧 Création des extensions et types...")
	db.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`)

	db.Exec(`
		DO $$ BEGIN
		  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role') THEN
		    CREATE TYPE role AS ENUM ('creator','subscriber','admin');
		  END IF;
		END$$;`)

	db.Exec(`
		DO $$ BEGIN
		  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
		    CREATE TYPE payment_status AS ENUM ('pending','succeeded','failed');
		  END IF;
		END$$;`)

	// ✨ AJOUTÉ : Types pour content_status et subscription_status
	db.Exec(`
		DO $$ BEGIN
		  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_status') THEN
		    CREATE TYPE content_status AS ENUM ('pending','approved','rejected');
		  END IF;
		END$$;`)

	db.Exec(`
		DO $$ BEGIN
		  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status') THEN
		    CREATE TYPE subscription_status AS ENUM ('active','expired','canceled');
		  END IF;
		END$$;`)

	// ✨ NOUVEAU : Nettoyage des contraintes problématiques AVANT migration
	log.Println("🧹 Nettoyage des contraintes problématiques...")

	db.Exec(`ALTER TABLE content DROP CONSTRAINT IF EXISTS fk_content_creator;`)
	db.Exec(`ALTER TABLE subscription DROP CONSTRAINT IF EXISTS fk_subscription_creator;`)
	db.Exec(`ALTER TABLE subscription DROP CONSTRAINT IF EXISTS fk_subscription_subscriber;`)
	db.Exec(`ALTER TABLE comment DROP CONSTRAINT IF EXISTS fk_comment_content;`)
	db.Exec(`ALTER TABLE comment DROP CONSTRAINT IF EXISTS fk_comment_author;`)
	db.Exec(`ALTER TABLE "like" DROP CONSTRAINT IF EXISTS fk_like_content;`)
	db.Exec(`ALTER TABLE "like" DROP CONSTRAINT IF EXISTS fk_like_user;`)

	// ✨ MODIFIÉ : Ajouter les colonnes subscription AVANT AutoMigrate
	log.Println("🔧 Préparation de la table subscription...")
	db.Exec(`
		ALTER TABLE subscription ADD COLUMN IF NOT EXISTS price INTEGER DEFAULT 3000;
		ALTER TABLE subscription ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';
		ALTER TABLE subscription ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
	`)

	log.Println("🔄 Migration des tables...")
	db.Exec(`
		DO $$
		BEGIN
			IF NOT EXISTS (
			SELECT 1 FROM pg_constraint
			WHERE conname = 'fk_content_creator'
				AND conrelid = 'content'::regclass
			) THEN
			ALTER TABLE content DROP CONSTRAINT IF EXISTS fk_content_creator;
			ALTER TABLE content ALTER COLUMN creator_id TYPE uuid USING creator_id::uuid;
			ALTER TABLE content
				ADD CONSTRAINT fk_content_creator
				FOREIGN KEY (creator_id) REFERENCES users(id)
				ON UPDATE CASCADE ON DELETE CASCADE;
			END IF;
		END
		$$;
		`)

	if err := db.AutoMigrate(
		&User{},         // D'abord les utilisateurs
		&Content{},      // Puis les contenus
		&Subscription{}, // Puis les abonnements
		&Payment{},      // Puis les paiements
		&Comment{},      // Puis les commentaires
		&CommentLike{},  // Puis les likes de commentaires
		&Like{},         // Puis les likes
		&Message{},      // Puis les messages
		&Report{},       // Enfin les reports
	); err != nil {
		log.Fatalf("AutoMigrate failed: %v", err)
	}

	// ✨ NOUVEAU : Recréation des contraintes APRÈS migration
	log.Println("🔗 Recréation des contraintes de clé étrangère...")

	// Content -> User
	db.Exec(`
		ALTER TABLE content 
		ADD CONSTRAINT IF NOT EXISTS fk_content_creator 
		FOREIGN KEY (creator_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// Subscription -> User (creator)
	db.Exec(`
		ALTER TABLE subscription 
		ADD CONSTRAINT IF NOT EXISTS fk_subscription_creator 
		FOREIGN KEY (creator_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// Subscription -> User (subscriber)
	db.Exec(`
		ALTER TABLE subscription 
		ADD CONSTRAINT IF NOT EXISTS fk_subscription_subscriber 
		FOREIGN KEY (subscriber_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// Comment -> Content
	db.Exec(`
		ALTER TABLE comment 
		ADD CONSTRAINT IF NOT EXISTS fk_comment_content 
		FOREIGN KEY (content_id) REFERENCES content(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// Comment -> User
	db.Exec(`
		ALTER TABLE comment 
		ADD CONSTRAINT IF NOT EXISTS fk_comment_author 
		FOREIGN KEY (author_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// Like -> Content
	db.Exec(`
		ALTER TABLE "like" 
		ADD CONSTRAINT IF NOT EXISTS fk_like_content 
		FOREIGN KEY (content_id) REFERENCES content(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// Like -> User
	db.Exec(`
		ALTER TABLE "like" 
		ADD CONSTRAINT IF NOT EXISTS fk_like_user 
		FOREIGN KEY (user_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	// ✨ Mise à jour des abonnements existants
	log.Println("🔄 Mise à jour des données existantes...")
	db.Exec(`
		UPDATE subscription SET
			price = 3000,
			status = 'active',
			created_at = COALESCE(created_at, start_date)
		WHERE price IS NULL OR status IS NULL;
	`)

	// Rendre les nouveaux champs obligatoires
	db.Exec(`
		ALTER TABLE subscription ALTER COLUMN price SET NOT NULL;
		ALTER TABLE subscription ALTER COLUMN status SET NOT NULL;
	`)

	// ✨ Index pour la performance
	log.Println("📊 Création des index...")
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscription_status ON subscription(status);`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscription_dates ON subscription(start_date, end_date);`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscription_active ON subscription(subscriber_id, creator_id, status) WHERE status = 'active';`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_content_creator_id ON content(creator_id);`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_content_status ON content(status);`)

	// 🔑 Seed admin
	log.Println("👤 Vérification du compte admin...")
	var count int64
	if err := db.Model(&User{}).Where("role = ?", "admin").Count(&count).Error; err != nil {
		log.Fatalf("❌ Erreur lors du comptage des admins : %v", err)
	}

	if count == 0 {
		log.Println("⏳ Aucun admin trouvé, création du compte admin…")
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte("admin1234"), bcrypt.DefaultCost)
		if err != nil {
			log.Fatalf("❌ Échec du hash du mot de passe admin : %v", err)
		}

		admin := User{
			Username:       "admin",
			Email:          "admin@example.com",
			HashedPassword: string(hashedPassword),
			Role:           "admin",
		}

		if err := db.Create(&admin).Error; err != nil {
			log.Fatalf("❌ Échec de la création du compte admin : %v", err)
		}

		log.Printf("🔑 Admin seedé avec succès : %s\n", admin.Email)
	} else {
		log.Println("ℹ️ Un compte admin existe déjà, pas de seed nécessaire.")
	}

	log.Println("✅ Database initialized successfully!")
}
