package models

import "time"

// Feature représente un feature-flag géré depuis le back-office
type Feature struct {
	Key         string    `gorm:"type:varchar(255);primaryKey" json:"key"`
	Description string    `gorm:"type:text;not null" json:"description"`
	Enabled     bool      `gorm:"not null;default:false" json:"enabled"`
	CreatedAt   time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}
