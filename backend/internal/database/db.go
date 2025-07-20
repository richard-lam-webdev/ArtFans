package database

import (
	"fmt"
	"log"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

var DB *gorm.DB

func Init() {
	var err error
	dsn := config.C.DatabaseURL
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			SingularTable: true,
		},
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("❌ Échec de connexion à la base de données : %v", err)
	}

	if err := DB.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`).Error; err != nil {
		log.Fatalf("❌ Impossible de créer extension uuid-ossp : %v", err)
	}
	if err := DB.Exec(`
      DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role') THEN
          CREATE TYPE role AS ENUM ('creator','subscriber','admin');
        END IF;
      END$$;`).Error; err != nil {
		log.Fatalf("❌ Impossible de créer enum role : %v", err)
	}
	if err := DB.Exec(`
      DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
          CREATE TYPE payment_status AS ENUM ('pending','succeeded','failed');
        END IF;
      END$$;`).Error; err != nil {
		log.Fatalf("❌ Impossible de créer enum payment_status : %v", err)
	}
	if err := DB.Exec(`
      DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_status') THEN
          CREATE TYPE content_status AS ENUM ('pending','approved','rejected');
        END IF;
      END$$;`).Error; err != nil {
		log.Fatalf("❌ Impossible de créer enum content_status : %v", err)
	}

	if err := DB.AutoMigrate(
		&models.User{},
		&models.Subscription{},
		&models.Payment{},
		&models.Content{},
		&models.Comment{},
		&models.Like{},
		&models.Message{},
		&models.Report{},
	); err != nil {
		log.Fatalf("❌ AutoMigrate a échoué : %v", err)
	}

	fmt.Println("✅ Base de données prête.")
}
