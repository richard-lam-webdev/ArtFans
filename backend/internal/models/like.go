package models

import (
	"time"

	"github.com/google/uuid"
)

type Like struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	ContentID uuid.UUID `gorm:"not null"`
	UserID    uuid.UUID `gorm:"not null"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
}
