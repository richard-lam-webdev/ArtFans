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
	ID             uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	Username       string     `gorm:"column:username;unique;not null" json:"username"`
	Email          string     `gorm:"unique;not null" json:"-"`
	HashedPassword string     `gorm:"column:hashed_password;not null" json:"-"`
	Role           Role       `gorm:"type:role;not null" json:"role"`
	CreatedAt      time.Time  `gorm:"column:created_at;autoCreateTime" json:"created_at"`

	// Nouveaux champs pour le profil public
	Bio       string `gorm:"type:text" json:"bio"`
	AvatarURL string `gorm:"column:avatar_url" json:"avatar_url"`

	// Autres champs existants
	SIRET       string     `gorm:"size:14" json:"siret"`
	LegalStatus string     `json:"legal_status"`
	LegalName   string     `json:"legal_name"`
	Address     string     `json:"address"`
	Country     string     `json:"country"`
	VATNumber   string     `gorm:"column:vat_number" json:"vat_number"`
	BirthDate   *time.Time `json:"birth_date"`
}

// BeforeCreate est un hook GORM qui génère un UUID pour l'utilisateur si nécessaire,
// valable à la fois pour Postgres et SQLite.
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
