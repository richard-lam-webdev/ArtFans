package models

import (
	"time"

	"github.com/google/uuid"
)

// Subscription représente un abonnement d’un abonné à un créateur
type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreatorID    uuid.UUID `gorm:"not null"`
	SubscriberID uuid.UUID `gorm:"not null"`
	StartDate    time.Time `gorm:"not null"`
	EndDate      time.Time `gorm:"not null"`
	PaymentID    uuid.UUID `gorm:"type:uuid;not null"`
}
