// chemin : backend/internal/models/user.go

package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

// Role représente les rôles d'un utilisateur.
// Sous Postgres, on souhaite un ENUM "role", sous SQLite on se rabat sur TEXT.
type Role string

const (
	RoleCreator    Role = "creator"
	RoleSubscriber Role = "subscriber"
	RoleAdmin      Role = "admin"
)

// GormDataType renvoie le type abstrait pour GORM.
func (Role) GormDataType() string {
	return "string"
}

// GormDBDataType indique à GORM quel type SQL utiliser selon le dialecte.
func (r Role) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	switch db.Dialector.Name() {
	case "sqlite":
		return "TEXT"
	default:
		return "role"
	}
}

// User représente un utilisateur de l’application.
// Pour Postgres, on laisse le type "uuid" (sans DEFAULT) et on gère l'UUID côté Go.
type User struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey"`
	Username    string    `gorm:"column:username;unique;not null"`
	Email       string    `gorm:"unique;not null"`
	Password    string    `gorm:"column:password;not null"`
	Role        Role      `gorm:"type:role;not null"`
	CreatedAt   time.Time `gorm:"column:created_at;autoCreateTime"`
	SIRET       string    `gorm:"size:14"`
	LegalStatus string
	LegalName   string
	Address     string
	Country     string
	VATNumber   string
	BirthDate   *time.Time
}

// BeforeCreate est un hook GORM qui génère un UUID pour l'utilisateur si nécessaire,
// valable à la fois pour Postgres et SQLite.
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
