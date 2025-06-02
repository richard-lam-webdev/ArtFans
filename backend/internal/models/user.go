package models

import (
	"time"

	"github.com/google/uuid"
)

type Role string

const (
	RoleCreator    Role = "creator"
	RoleSubscriber Role = "subscriber"
	RoleAdmin      Role = "admin"
)

type User struct {
	ID        uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	Username  string    `gorm:"column:username;unique;not null"`
	Email     string    `gorm:"unique;not null"`
	Password  string    `gorm:"column:hashed_password;not null"`
	Role      Role      `gorm:"type:role;not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}
