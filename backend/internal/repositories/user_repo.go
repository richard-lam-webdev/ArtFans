package repositories

import (
	"errors"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
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

func (r *UserRepository) Create(user *models.User) error {
	if err := r.db.Create(user).Error; err != nil {
		return err
	}
	return nil
}

// FindByID renvoie nil,nil si pas trouvé, ou l'erreur de GORM si autre.
func (r *UserRepository) FindByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	err := r.db.First(&user, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

// FindByUsername renvoie l'utilisateur correspondant au username, ou nil,nil si pas trouvé.
func (r *UserRepository) FindByUsername(username string) (*models.User, error) {
	var user models.User
	err := r.db.Where("username = ?", username).First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &user, err
}

// UpdateRole met à jour le rôle d’un utilisateur donné.
func (r *UserRepository) UpdateRole(userID uuid.UUID, newRole models.Role) error {
	res := r.db.Model(&models.User{}).
		Where("id = ?", userID).
		Update("role", newRole)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindAll récupère tous les utilisateurs.
func (r *UserRepository) FindAll() ([]models.User, error) {
	var users []models.User
	if err := r.db.Find(&users).Error; err != nil {
		return nil, err
	}
	return users, nil
}

// SetTestDB permet de remplacer la DB utilisée (pour les tests).
func SetTestDB(db *gorm.DB) {
	database.DB = db
}
