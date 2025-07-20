package models

import (
	"time"

	"github.com/google/uuid"
)

type Report struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	TargetContentID uuid.UUID `gorm:"not null"`
	ReporterID      uuid.UUID `gorm:"not null"`
	Reason          string    `gorm:"not null"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
}
