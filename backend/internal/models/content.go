package models

import (
	"time"

	"github.com/google/uuid"
)

// Content représente un contenu qu’un créateur met en vente
type Content struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID uuid.UUID `gorm:"not null"`
	Title     string    `gorm:"not null"`
	Body      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
	Price     int       `gorm:"not null"`
	FilePath  string    `gorm:"not null"`
}
