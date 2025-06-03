package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

type PaymentStatus string

const (
	StatusPending   PaymentStatus = "pending"
	StatusSucceeded PaymentStatus = "succeeded"
	StatusFailed    PaymentStatus = "failed"
)

func (PaymentStatus) GormDataType() string {
	return "string"
}

func (ps PaymentStatus) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	if db.Dialector.Name() == "sqlite" {
		return "TEXT"
	}
	return "payment_status"
}

type Payment struct {
	ID             uuid.UUID     `gorm:"type:uuid;primaryKey"`
	SubscriptionID uuid.UUID     `gorm:"column:subscription_id;not null"`
	Amount         int64         `gorm:"column:amount;not null"`
	PaidAt         time.Time     `gorm:"column:paid_at;not null"`
	Status         PaymentStatus `gorm:"column:status;type:payment_status;not null"`
}

func (p *Payment) BeforeCreate(tx *gorm.DB) (err error) {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}
