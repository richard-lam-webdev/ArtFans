package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

type Role string

const (
	RoleCreator    Role = "creator"
	RoleSubscriber Role = "subscriber"
	RoleAdmin      Role = "admin"
)

func (Role) GormDataType() string {
	return "string"
}

func (r Role) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	switch db.Dialector.Name() {
	case "sqlite":
		return "TEXT"
	default:
		return "role"
	}
}

type User struct {
	ID             uuid.UUID `gorm:"type:uuid;primaryKey"`
	Username       string    `gorm:"column:username;unique;not null"`
	Email          string    `gorm:"unique;not null"`
	HashedPassword string    `gorm:"column:hashed_password;not null"`
	Role           Role      `gorm:"type:role;not null"`
	CreatedAt      time.Time `gorm:"column:created_at;autoCreateTime"`
	SIRET          string    `gorm:"size:14"`
	LegalStatus    string
	LegalName      string
	Address        string
	Country        string
	VATNumber      string
	BirthDate      *time.Time
	Bio            string `gorm:"type:text" json:"bio"`
	AvatarURL      string `gorm:"column:avatar_url" json:"avatar_url"`
}

func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
