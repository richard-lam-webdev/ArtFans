package main

import (
	"log"
	"os"
	"time"

	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

// ----- GORM Models (all in English) -----

// User corresponds to a user account
type User struct {
	ID          uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	Username    string    `gorm:"column:username;unique;not null"`
	Email       string    `gorm:"unique;not null"`
	Password    string    `gorm:"column:hashed_password;not null"`
	Role        string    `gorm:"type:role;not null"`
	CreatedAt   time.Time `gorm:"column:created_at;autoCreateTime"`
	SIRET       string    `gorm:"size:14"`
	LegalStatus string
	LegalName   string
	Address     string
	Country     string
	VATNumber   string
	BirthDate   *time.Time
}

type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID    uuid.UUID `gorm:"column:creator_id;not null"`
	SubscriberID uuid.UUID `gorm:"column:subscriber_id;not null"`
	StartDate    time.Time `gorm:"column:start_date;not null"`
	EndDate      time.Time `gorm:"column:end_date;not null"`
	PaymentID    uuid.UUID `gorm:"column:payment_id;not null"`
}

// Payment corresponds to a payment record
type Payment struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID `gorm:"column:subscription_id;not null"`
	Amount         int64     `gorm:"column:amount;not null"`
	PaidAt         time.Time `gorm:"column:paid_at;not null"`
	Status         string    `gorm:"column:status;type:payment_status;not null"`
}

// Content corresponds to published content items
type Content struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID uuid.UUID `gorm:"column:creator_id;not null"`
	Title     string    `gorm:"not null"`
	Body      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
	Price     int64     `gorm:"column:price;not null"`
	IsBlurred bool      `gorm:"column:is_blurred;default:false"`
	FilePath  string    `gorm:"column:file_path;not null"`
}

// Comment corresponds to user comments
type Comment struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"column:content_id;not null"`
	AuthorID  uuid.UUID `gorm:"column:author_id;not null"`
	Text      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

// Like corresponds to a “like” on a content item
type Like struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"column:content_id;not null"`
	UserID    uuid.UUID `gorm:"column:user_id;not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

// Message corresponds to a private message between users
type Message struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SenderID   uuid.UUID `gorm:"column:sender_id;not null"`
	ReceiverID uuid.UUID `gorm:"column:receiver_id;not null"`
	Text       string    `gorm:"not null"`
	SentAt     time.Time `gorm:"column:sent_at;autoCreateTime"`
}

// Report corresponds to a content report/flag
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
				SingularTable: true, // keep singular table names
			},
			Logger: logger.Default.LogMode(logger.Info),
		},
	)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	// 1) Ensure uuid-ossp extension is enabled
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

	db.Migrator().DropTable(
		&Subscription{},
		&Payment{},
		&Content{},
	)

	if err := db.AutoMigrate(
		&User{},
		&Subscription{},
		&Payment{},
		&Content{},
		&Comment{},
		&User{},
		&Subscription{},
		&Payment{},
		&Content{},
		&Comment{},
		&Like{},
		&Message{},
		&Report{},
		&DashboardStats{},
	); err != nil {
		log.Fatalf("AutoMigrate failed: %v", err)
		log.Fatalf("AutoMigrate failed: %v", err)
	}

	log.Println("Database initialized successfully ✅")
}
