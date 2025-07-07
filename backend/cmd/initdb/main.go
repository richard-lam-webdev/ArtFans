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
	CreatorID    uuid.UUID `gorm:"column:creator_id;not null"`
	SubscriberID uuid.UUID `gorm:"column:subscriber_id;not null"`
	StartDate    time.Time `gorm:"column:start_date;not null"`
	EndDate      time.Time `gorm:"column:end_date;not null"`
	PaymentID    uuid.UUID `gorm:"column:payment_id;not null"`
}

type Payment struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID `gorm:"column:subscription_id;not null"`
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
}

type Comment struct {
	ID        uuid.UUID  `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID  `gorm:"column:content_id;not null"`
	AuthorID  uuid.UUID  `gorm:"column:author_id;not null"`
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
	ContentID uuid.UUID `gorm:"column:content_id;not null"`
	UserID    uuid.UUID `gorm:"column:user_id;not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

type Message struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SenderID   uuid.UUID `gorm:"column:sender_id;not null"`
	ReceiverID uuid.UUID `gorm:"column:receiver_id;not null"`
	Text       string    `gorm:"not null"`
	SentAt     time.Time `gorm:"column:sent_at;autoCreateTime"`
}

type Report struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	TargetContentID uuid.UUID `gorm:"column:target_content_id;not null"`
	ReporterID      uuid.UUID `gorm:"column:reporter_id;not null"`
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
			Logger: logger.Default.LogMode(logger.Info),
		},
	)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

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
		&User{},
		&Subscription{},
		&Payment{},
		&Content{},
		&Comment{},
		&CommentLike{},
		&Like{},
		&Message{},
		&Report{},
	); err != nil {
		log.Fatalf("AutoMigrate failed: %v", err)
	}

	// 🔑 Seed admin
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

	log.Println("Database initialized successfully ✅")
}
