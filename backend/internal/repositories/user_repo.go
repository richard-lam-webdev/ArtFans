package repositories

import (
	"errors"

	"your_module_path/backend/internal/database"
	"your_module_path/backend/internal/models"

	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository() *UserRepository {
	return &UserRepository{db: database.DB}
}

// FindByEmail renvoie nil,nil si pas trouvé, ou l'erreur de GORM si autre.
func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var u models.User
	err := r.db.Where("email = ?", email).First(&u).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &u, err
}

func (r *UserRepository) Create(u *models.User) error {
	return r.db.Create(u).Error
}

func SetTestDB(db *gorm.DB) {
	database.DB = db
}
