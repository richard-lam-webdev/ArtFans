package models

import (
	"time"

	"github.com/google/uuid"
)

// Report représente une signalisation faite par un utilisateur sur un Content
type Report struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	TargetContentID uuid.UUID `gorm:"not null"` // référence vers Content reporté
	ReporterID      uuid.UUID `gorm:"not null"` // référence vers l’utilisateur qui signale
	Reason          string    `gorm:"not null"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
}
