package models

import (
	"time"

	"github.com/google/uuid"
)

const (
	SubscriptionPriceEuros   = 30
	SubscriptionPriceCents   = 3000
	SubscriptionDurationDays = 30
)

type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	CreatorID    uuid.UUID `gorm:"not null" json:"creator_id"`
	SubscriberID uuid.UUID `gorm:"not null" json:"subscriber_id"`
	StartDate    time.Time `gorm:"not null" json:"start_date"`
	EndDate      time.Time `gorm:"not null" json:"end_date"`
	PaymentID    uuid.UUID `gorm:"type:uuid;not null" json:"payment_id"`
	Price        int       `gorm:"column:price;default:3000;not null" json:"price"`
	Status       string    `gorm:"column:status;default:'active';not null" json:"status"`
	CreatedAt    time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

const (
	SubscriptionStatusActive   = "active"
	SubscriptionStatusExpired  = "expired"
	SubscriptionStatusCanceled = "canceled"
)

func (s *Subscription) IsActive() bool {
	now := time.Now()
	return s.Status == SubscriptionStatusActive &&
		s.StartDate.Before(now) &&
		s.EndDate.After(now)
}

func (s *Subscription) DaysRemaining() int {
	if !s.IsActive() {
		return 0
	}
	duration := time.Until(s.EndDate)
	days := int(duration.Hours() / 24)
	if days < 0 {
		return 0
	}
	return days
}
