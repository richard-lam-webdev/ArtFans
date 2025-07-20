package models

import (
	"time"

	"github.com/google/uuid"
)

const (
	ContentStatusPending  = "pending"
	ContentStatusApproved = "approved"
	ContentStatusRejected = "rejected"
)

type Content struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	CreatorID uuid.UUID `gorm:"type:uuid;not null;index" json:"creator_id"`
	Creator   User      `gorm:"foreignKey:CreatorID"`
	Title     string    `gorm:"not null" json:"title"`
	Body      string    `gorm:"not null" json:"body"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	Price     int       `gorm:"not null" json:"price"`
	FilePath  string    `gorm:"not null" json:"file_path"`
	Status    string    `gorm:"type:content_status;default:'pending';not null" json:"status"`
}
