package models

import (
	"time"

	"github.com/google/uuid"
)

// Payment représente un paiement lié à une Subscription
type Payment struct {
	ID             uuid.UUID     `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID     `gorm:"not null"`
	Amount         int           `gorm:"not null"` // montant en centimes ou unité choisie
	PaidAt         time.Time     // date de paiement
	Status         PaymentStatus `gorm:"type:payment_status;not null"`
}

// PaymentStatus est un type enum pour le statut d’un paiement
type PaymentStatus string

const (
	StatusPending   PaymentStatus = "pending"
	StatusSucceeded PaymentStatus = "succeeded"
	StatusFailed    PaymentStatus = "failed"
)
