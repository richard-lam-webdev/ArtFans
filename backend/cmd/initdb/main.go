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

type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID    uuid.UUID `gorm:"type:uuid;not null;index" json:"creator_id"`
	SubscriberID uuid.UUID `gorm:"type:uuid;not null;index" json:"subscriber_id"`
	StartDate    time.Time `gorm:"column:start_date;not null"`
	EndDate      time.Time `gorm:"column:end_date;not null"`
	PaymentID    uuid.UUID `gorm:"type:uuid;not null"`
	Price        int       `gorm:"column:price;default:3000;not null" json:"price"`
	Status       string    `gorm:"column:status;default:'active';not null" json:"status"`
	CreatedAt    time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

type Payment struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID `gorm:"type:uuid;not null"`
	Amount         int64     `gorm:"column:amount;not null"`
	PaidAt         time.Time `gorm:"column:paid_at;not null"`
	Status         string    `gorm:"column:status;type:payment_status;not null"`
}

type Content struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID uuid.UUID `gorm:"type:uuid;not null;index" json:"creator_id"`
	Title     string    `gorm:"not null"`
	Body      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
	Price     int64     `gorm:"column:price;not null"`
	IsBlurred bool      `gorm:"column:is_blurred;default:false"`
	FilePath  string    `gorm:"column:file_path;not null"`
	Status    string    `gorm:"type:content_status;default:'pending';not null" json:"status"`
}

type Comment struct {
	ID        uuid.UUID  `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID  `gorm:"type:uuid;not null;index"`
	AuthorID  uuid.UUID  `gorm:"type:uuid;not null;index"`
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
	ContentID uuid.UUID `gorm:"type:uuid;not null;index"`
	UserID    uuid.UUID `gorm:"type:uuid;not null;index"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

type Message struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SenderID   uuid.UUID `gorm:"type:uuid;not null;index"`
	ReceiverID uuid.UUID `gorm:"type:uuid;not null;index"`
	Text       string    `gorm:"not null"`
	SentAt     time.Time `gorm:"column:sent_at;autoCreateTime"`
}

type Report struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	TargetContentID uuid.UUID `gorm:"type:uuid;not null;index"`
	ReporterID      uuid.UUID `gorm:"type:uuid;not null;index"`
	Reason          string    `gorm:"not null"`
	CreatedAt       time.Time `gorm:"column:created_at;autoCreateTime"`
}

type Feature struct {
	Key         string    `gorm:"type:varchar(255);primaryKey"`
	Description string    `gorm:"type:text;not null"`
	Enabled     bool      `gorm:"not null;default:false"`
	CreatedAt   time.Time `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt   time.Time `gorm:"column:updated_at;autoUpdateTime"`
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
			DisableForeignKeyConstraintWhenMigrating: true,
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

	log.Println("🧹 Nettoyage des contraintes problématiques...")

	db.Exec(`ALTER TABLE content DROP CONSTRAINT IF EXISTS fk_content_creator;`)
	db.Exec(`ALTER TABLE subscription DROP CONSTRAINT IF EXISTS fk_subscription_creator;`)
	db.Exec(`ALTER TABLE subscription DROP CONSTRAINT IF EXISTS fk_subscription_subscriber;`)
	db.Exec(`ALTER TABLE comment DROP CONSTRAINT IF EXISTS fk_comment_content;`)
	db.Exec(`ALTER TABLE comment DROP CONSTRAINT IF EXISTS fk_comment_author;`)
	db.Exec(`ALTER TABLE "like" DROP CONSTRAINT IF EXISTS fk_like_content;`)
	db.Exec(`ALTER TABLE "like" DROP CONSTRAINT IF EXISTS fk_like_user;`)

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

	log.Println("🔗 Recréation des contraintes de clé étrangère...")

	db.Exec(`
		ALTER TABLE content 
		ADD CONSTRAINT IF NOT EXISTS fk_content_creator 
		FOREIGN KEY (creator_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	db.Exec(`
		ALTER TABLE subscription 
		ADD CONSTRAINT IF NOT EXISTS fk_subscription_creator 
		FOREIGN KEY (creator_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	db.Exec(`
		ALTER TABLE subscription 
		ADD CONSTRAINT IF NOT EXISTS fk_subscription_subscriber 
		FOREIGN KEY (subscriber_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	db.Exec(`
		ALTER TABLE comment 
		ADD CONSTRAINT IF NOT EXISTS fk_comment_content 
		FOREIGN KEY (content_id) REFERENCES content(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	db.Exec(`
		ALTER TABLE comment 
		ADD CONSTRAINT IF NOT EXISTS fk_comment_author 
		FOREIGN KEY (author_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	db.Exec(`
		ALTER TABLE "like" 
		ADD CONSTRAINT IF NOT EXISTS fk_like_content 
		FOREIGN KEY (content_id) REFERENCES content(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	db.Exec(`
		ALTER TABLE "like" 
		ADD CONSTRAINT IF NOT EXISTS fk_like_user 
		FOREIGN KEY (user_id) REFERENCES "user"(id) 
		ON UPDATE CASCADE ON DELETE CASCADE;`)

	log.Println("🔄 Mise à jour des données existantes...")
	db.Exec(`
		UPDATE subscription SET
			price = 3000,
			status = 'active',
			created_at = COALESCE(created_at, start_date)
		WHERE price IS NULL OR status IS NULL;
	`)

	db.Exec(`
		ALTER TABLE subscription ALTER COLUMN price SET NOT NULL;
		ALTER TABLE subscription ALTER COLUMN status SET NOT NULL;
	`)

	log.Println("📊 Création des index...")
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscription_status ON subscription(status);`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscription_dates ON subscription(start_date, end_date);`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_subscription_active ON subscription(subscriber_id, creator_id, status) WHERE status = 'active';`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_content_creator_id ON content(creator_id);`)
	db.Exec(`CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_content_status ON content(status);`)

	if err := db.AutoMigrate(
		&User{},
		&Content{},
		&Subscription{},
		&Payment{},
		&Comment{},
		&CommentLike{},
		&Like{},
		&Message{},
		&Report{},
		&Feature{},
	); err != nil {
		log.Fatalf("AutoMigrate failed: %v", err)
	}
	var featureCount int64
	db.Model(&Feature{}).Count(&featureCount)
	const (
		featureChat     = "MESSAGERIE"
		featureComments = "COMMENTAIRES"
		featureSearch   = "RECHERCHE"
	)
	if featureCount == 0 {
		seeds := []Feature{
			{Key: featureChat, Description: "Activer ou désactiver la messagerie entre utilisateurs"},
			{Key: featureComments, Description: "Activer ou désactiver les commentaires sur les contenus"},
			{Key: featureSearch, Description: "Activer ou désactiver la recherche"},
		}
		for _, f := range seeds {
			if err := db.Create(&f).Error; err != nil {
				log.Fatalf("Seed feature '%s' failed: %v", f.Key, err)
			}
		}
		log.Printf("✅ Seeded %d feature-flags\n", len(seeds))
	}

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
