// backend/internal/models/payment.go
package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

// PaymentStatus représente l'état d'un paiement.
// Sous Postgres, on veut l'ENUM "payment_status",
// sous SQLite, on utilise TEXT.
type PaymentStatus string

const (
	StatusPending   PaymentStatus = "pending"
	StatusSucceeded PaymentStatus = "succeeded"
	StatusFailed    PaymentStatus = "failed"
)

// GormDataType renvoie le type abstrait pour GORM (ici, une chaîne).
func (PaymentStatus) GormDataType() string {
	return "string"
}

// GormDBDataType choisit le type SQL selon le dialecte.
func (ps PaymentStatus) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	switch db.Dialector.Name() {
	case "sqlite":
		return "TEXT"
	default:
		return "payment_status"
	}
}

// Payment représente un paiement lié à une souscription.
type Payment struct {
	ID             uuid.UUID     `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	SubscriptionID uuid.UUID     `gorm:"column:subscription_id;not null"`
	Amount         int64         `gorm:"column:amount;not null"`
	PaidAt         time.Time     `gorm:"column:paid_at;not null"`
	Status         PaymentStatus `gorm:"column:status;type:payment_status;not null"`
}
