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

// ----- Modèles GORM -----

type Utilisateur struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	NomUtilisateur  string    `gorm:"column:nomutilisateur;unique;not null"`
	Email           string    `gorm:"unique;not null"`
	MotDePasseHache string    `gorm:"column:motdepassehaché;not null"`
	Role            string    `gorm:"type:role;not null"`
	DateCreation    time.Time `gorm:"column:datecréation;autoCreateTime"`
}

type Abonnement struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDCreateur uuid.UUID `gorm:"column:idcréateur;not null"`
	IDAbonne   uuid.UUID `gorm:"column:idabonné;not null"`
	DateDebut  time.Time `gorm:"column:datedébut;not null"`
	DateFin    time.Time `gorm:"column:datefin;not null"`
	IDPaiement uuid.UUID `gorm:"column:idpaiement;not null"`
}

type Paiement struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDAbonnement uuid.UUID `gorm:"column:idabonnement;not null"`
	Montant      float64   `gorm:"type:money;not null"`
	DatePaiement time.Time `gorm:"column:datepaiement;not null"`
	Statut       string    `gorm:"column:statut;type:statutpaiement;not null"`
}

type Contenu struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDCreateur   uuid.UUID `gorm:"column:idcréateur;not null"`
	Titre        string    `gorm:"not null"`
	Texte        string    `gorm:"not null"`
	DateCreation time.Time `gorm:"column:datecréation;autoCreateTime"`
	Prix         float64   `gorm:"type:money;not null"`
	EstFloute    bool      `gorm:"column:estflouté;default:false"`
}

type Commentaire struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDContenu    uuid.UUID `gorm:"column:idcontenu;not null"`
	IDAuteur     uuid.UUID `gorm:"column:idauteur;not null"`
	Texte        string    `gorm:"not null"`
	DateCreation time.Time `gorm:"column:datecréation;autoCreateTime"`
}

type Like struct {
	ID            uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDContenu     uuid.UUID `gorm:"column:idcontenu;not null"`
	IDUtilisateur uuid.UUID `gorm:"column:idutilisateur;not null"`
	DateCreation  time.Time `gorm:"column:datecréation;autoCreateTime"`
}

type Message struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDExpediteur   uuid.UUID `gorm:"column:idexpéditeur;not null"`
	IDDestinataire uuid.UUID `gorm:"column:iddestinataire;not null"`
	Texte          string    `gorm:"not null"`
	DateEnvoi      time.Time `gorm:"column:dateenvoi;autoCreateTime"`
}

type Rapport struct {
	ID             uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDContenuCible uuid.UUID `gorm:"column:idcontenucible;not null"`
	IDSignaliseur  uuid.UUID `gorm:"column:idsignaleur;not null"`
	Raison         string    `gorm:"not null"`
	DateCreation   time.Time `gorm:"column:datecréation;autoCreateTime"`
}

type StatistiquesTableauDeBord struct {
	ID                 uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	IDCreateur         uuid.UUID `gorm:"column:idcréateur;not null"`
	RevenusTotaux      float64   `gorm:"column:revenustotaux;type:money;default:0"`
	NombreAbonnes      int       `gorm:"column:nombreabonnés;default:0"`
	NombreLikes        int       `gorm:"column:nombrelikes;default:0"`
	NombreCommentaires int       `gorm:"column:nombrecommentaires;default:0"`
}

// ----- Main -----
func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("il faut définir la variable d'environnement DATABASE_URL")
	}

	// Ouvre GORM avec nommage en table singulier
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
		log.Fatalf("connexion GORM échouée : %v", err)
	}

	// Extensions et enums
	db.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`)
	db.Exec(`
	DO $$ BEGIN
	  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role') THEN
	    CREATE TYPE role AS ENUM ('CRÉATEUR','ABONNÉ','ADMIN');
	  END IF;
	END$$;`)
	db.Exec(`
	DO $$ BEGIN
	  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'statutpaiement') THEN
	    CREATE TYPE statutpaiement AS ENUM ('EN_ATTENTE','RÉUSSI','ÉCHOUÉ');
	  END IF;
	END$$;`)

	// Auto-migrate de tous les modèles
	if err := db.AutoMigrate(
		&Utilisateur{},
		&Abonnement{},
		&Paiement{},
		&Contenu{},
		&Commentaire{},
		&Like{},
		&Message{},
		&Rapport{},
		&StatistiquesTableauDeBord{},
	); err != nil {
		log.Fatalf("AutoMigrate échoué : %v", err)
	}

	log.Println("Base de données initialisée avec succès ✅")
}
