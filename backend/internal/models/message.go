package models

import (
	"time"

	"github.com/google/uuid"
)

// Message représente un message privé échangé entre deux utilisateurs
type Message struct {
	ID         uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SenderID   uuid.UUID `gorm:"not null"`
	ReceiverID uuid.UUID `gorm:"not null"`
	Text       string    `gorm:"not null"`
	SentAt     time.Time `gorm:"autoCreateTime"`
}
