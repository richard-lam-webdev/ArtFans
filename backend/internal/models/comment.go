package models

import (
	"time"

	"github.com/google/uuid"
)

// Comment représente un commentaire posté par un utilisateur sur un Content
type Comment struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"not null"`
	AuthorID  uuid.UUID `gorm:"not null"`
	Text      string    `gorm:"not null"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
}
