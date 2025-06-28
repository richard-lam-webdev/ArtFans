package services

import (
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type ContentService struct {
	repo       *repositories.ContentRepository
	uploadPath string
}

func NewContentService(repo *repositories.ContentRepository, uploadPath string) *ContentService {
	return &ContentService{repo: repo, uploadPath: uploadPath}
}

func (s *ContentService) CreateContent(
	creatorID uuid.UUID,
	username, title, body string,
	price int,
	fileHeader *multipart.FileHeader,
	role string,
) (*models.Content, error) {

	if role != "creator" && role != "admin" {
		return nil, fmt.Errorf("seuls les créateurs peuvent ajouter du contenu")
	}
	if title == "" || body == "" || price <= 0 || fileHeader == nil {
		return nil, fmt.Errorf("champs requis manquants ou invalides")
	}

	userDir := filepath.Join(s.uploadPath, username)
	if err := os.MkdirAll(userDir, 0o755); err != nil {
		return nil, fmt.Errorf("mkdir: %w", err)
	}

	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true}
	if !allowed[ext] {
		return nil, fmt.Errorf("format de fichier non autorisé")
	}

	filename := uuid.NewString() + ext
	dstPath := filepath.Join(userDir, filename)

	src, err := fileHeader.Open()
	if err != nil {
		return nil, err
	}
	defer src.Close()

	dst, err := os.Create(dstPath)
	if err != nil {
		return nil, err
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		return nil, err
	}

	relativePath := filepath.Join(username, filename)
	content := &models.Content{
		CreatorID: creatorID,
		Title:     title,
		Body:      body,
		Price:     price,
		FilePath:  relativePath,
		Status:    "pending",
	}

	if err := s.repo.Create(content); err != nil {
		return nil, err
	}

	return content, nil
}

func (s *ContentService) GetAllContents() ([]models.Content, error) {
	return s.repo.FindAll()
}

func (s *ContentService) GetContentByID(id uuid.UUID) (*models.Content, error) {
	return s.repo.FindByID(id)
}

func (s *ContentService) UpdateContent(content *models.Content) error {
	return s.repo.Update(content)
}

func (s *ContentService) DeleteContent(id uuid.UUID) error {
	return s.repo.Delete(id)
}
