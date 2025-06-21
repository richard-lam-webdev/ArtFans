package services

import (
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

// AdminService expose les opérations réservées aux admins.
type AdminService struct {
	userRepo *repositories.UserRepository
}

// NewAdminService instancie le service admin.
func NewAdminService(userRepo *repositories.UserRepository) *AdminService {
	return &AdminService{userRepo: userRepo}
}

// ListUsers renvoie la liste de tous les users.
func (s *AdminService) ListUsers() ([]models.User, error) {
	return s.userRepo.FindAll()
}
