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

// Register crée un nouvel utilisateur ou renvoie une erreur si l'email existe.
func (s *AuthService) Register(username, email, plainPassword string, role models.Role) (*models.User, error) {
	// 1. Vérifier email unique
	existing, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("utilisateur déjà existant")
	}

	// 2. Hasher le mot de passe
	hashed, err := bcrypt.GenerateFromPassword([]byte(plainPassword), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &models.User{
		Username: username,
		Email:    email,
		Password: string(hashed),
		Role:     role,
	}
	// 3. Insérer en base
	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	// 4. Ne jamais renvoyer le hash au client
	user.Password = ""
	return user, nil
}

// Login vérifie les identifiants et retourne un token JWT.
func (s *AuthService) Login(email, plainPassword string) (string, error) {
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return "", err
	}
	if user == nil {
		return "", errors.New("identifiants invalides")
	}

	// Comparer le mot de passe
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(plainPassword)); err != nil {
		return "", errors.New("identifiants invalides")
	}

	// Générer le JWT
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
