package services

import (
	"errors"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type ContentService struct {
	repo       *repositories.ContentRepository
	uploadPath string // ajoute le chemin d'upload (ex: depuis .env)
}

func NewContentService(repo *repositories.ContentRepository, uploadPath string) *ContentService {
	return &ContentService{repo: repo, uploadPath: uploadPath}
}

func (s *ContentService) CreateContent(creatorID uuid.UUID, username, title, body string, price int, fileHeader *multipart.FileHeader, role string) (*models.Content, error) {
	if role != "creator" {
		return nil, errors.New("seuls les créateurs peuvent ajouter du contenu")
	}
	if title == "" || body == "" || fileHeader == nil {
		return nil, errors.New("champs requis manquants")
	}

	// Crée le dossier utilisateur si besoin
	userDir := filepath.Join(s.uploadPath, username)
	if _, err := os.Stat(userDir); os.IsNotExist(err) {
		if err := os.MkdirAll(userDir, 0755); err != nil {
			return nil, err
		}
	}

	// Sauvegarde le fichier
	file, err := fileHeader.Open()
	if err != nil {
		return nil, err
	}
	defer file.Close()

	filename := uuid.New().String() + filepath.Ext(fileHeader.Filename)
	dstPath := filepath.Join(userDir, filename)

	dst, err := os.Create(dstPath)
	if err != nil {
		return nil, err
	}
	defer dst.Close()
	if _, err := io.Copy(dst, file); err != nil {
		return nil, err
	}

	content := &models.Content{
		CreatorID: creatorID,
		Title:     title,
		Body:      body,
		Price:     price,
		FilePath:  dstPath, // chemin absolu ou relatif selon ton besoin
	}

	if err := s.repo.Create(content); err != nil {
		return nil, err
	}
	return content, nil
}

func (s *ContentService) GetAllContents() ([]models.Content, error) {
	return s.repo.FindAll()
}
