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

type Role string

const (
	RoleCreator    Role = "creator"
	RoleSubscriber Role = "subscriber"
	RoleAdmin      Role = "admin"
)

type PaymentStatus string

const (
	StatusPending   PaymentStatus = "pending"
	StatusSucceeded PaymentStatus = "succeeded"
	StatusFailed    PaymentStatus = "failed"
)

type User struct {
	ID            uuid.UUID      `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	Username      string         `gorm:"unique;not null"`
	Email         string         `gorm:"unique;not null"`
	PasswordHash  string         `gorm:"not null"`
	Role          Role           `gorm:"type:role;not null"`
	CreatedAt     time.Time      `gorm:"autoCreateTime"`
	Subscriptions []Subscription `gorm:"foreignKey:SubscriberID"`
	Contents      []Content      `gorm:"foreignKey:CreatorID"`
}

type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID    uuid.UUID `gorm:"not null"`
	SubscriberID uuid.UUID `gorm:"not null"`
	StartDate    time.Time `gorm:"not null"`
	EndDate      time.Time
	PaymentID    uuid.UUID
}

type Payment struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID `gorm:"not null"`
	Amount         int       `gorm:"not null"`
	PaidAt         time.Time
	Status         PaymentStatus `gorm:"type:payment_status;not null"`
}

type Content struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID uuid.UUID `gorm:"not null"`
	Title     string    `gorm:"not null"`
	Body      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
	Price     int       `gorm:"not null"`
	FilePath  string    `gorm:"not null"`
}

type Comment struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"not null"`
	AuthorID  uuid.UUID `gorm:"not null"`
	Text      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
}

type Like struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"not null"`
	UserID    uuid.UUID `gorm:"not null"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
}

type Message struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SenderID   uuid.UUID `gorm:"not null"`
	ReceiverID uuid.UUID `gorm:"not null"`
	Text       string    `gorm:"not null"`
	SentAt     time.Time `gorm:"autoCreateTime"`
}

type Report struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	TargetContentID uuid.UUID `gorm:"not null"`
	ReporterID      uuid.UUID `gorm:"not null"`
	Reason          string    `gorm:"not null"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL environment variable is required")
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
		log.Fatalf("GORM connection failed: %v", err)
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

	// Auto-migrate
	if err := db.AutoMigrate(
		&User{},
		&Subscription{},
		&Payment{},
		&Content{},
		&Comment{},
		&Like{},
		&Message{},
		&Report{},
	); err != nil {
		log.Fatalf("AutoMigrate failed: %v", err)
	}

	log.Println("✅ Database schema is up-to-date!")
}
