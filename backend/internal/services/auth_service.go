package services

import (
	"errors"
	"time"

	"github.com/dgrijalva/jwt-go"
	"golang.org/x/crypto/bcrypt"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type AuthService struct {
	userRepo *repositories.UserRepository
	jwtKey   []byte
}

func NewAuthService(repo *repositories.UserRepository) *AuthService {
	return &AuthService{
		userRepo: repo,
		jwtKey:   []byte(config.C.JwtSecret),
	}
}

// Register crée un nouvel utilisateur avec un mot de passe hashé
func (s *AuthService) Register(username, email, password string, role models.Role) (*models.User, error) {
	// 1. Vérifier si l'utilisateur existe déjà
	existing, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("un utilisateur avec cet email existe déjà")
	}

	// 2. Hasher le mot de passe
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("échec du hash du mot de passe")
	}

	// 3. Créer le nouvel utilisateur
	user := &models.User{
		Username:       username,
		Email:          email,
		HashedPassword: string(hashed),
		Role:           role,
	}

	// 4. Sauvegarde en base
	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	// 5. Ne pas renvoyer le hash au client
	user.HashedPassword = ""
	return user, nil
}

// Login vérifie les identifiants et retourne un token JWT
func (s *AuthService) Login(email, password string) (string, error) {
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return "", err
	}
	if user == nil {
		return "", errors.New("identifiants invalides")
	}

	// 1. Vérification du mot de passe hashé
	if err := bcrypt.CompareHashAndPassword([]byte(user.HashedPassword), []byte(password)); err != nil {
		return "", errors.New("identifiants invalides")
	}

	// 2. Génération du token JWT
	expirationTime := time.Now().Add(72 * time.Hour)
	claims := &jwt.StandardClaims{
		Subject:   user.ID.String(),
		ExpiresAt: expirationTime.Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedToken, err := token.SignedString(s.jwtKey)
	if err != nil {
		return "", err
	}

	return signedToken, nil
}
