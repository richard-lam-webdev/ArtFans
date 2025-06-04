package services

import (
	"errors"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type ContentService struct {
	repo *repositories.ContentRepository
}

func NewContentService(repo *repositories.ContentRepository) *ContentService {
	return &ContentService{repo: repo}
}

// Ajout d’un contenu
func (s *ContentService) CreateContent(creatorID uuid.UUID, title, body, filePath string, price int) (*models.Content, error) {
	if title == "" || body == "" || filePath == "" {
		return nil, errors.New("champs requis manquants")
	}
	content := &models.Content{
		CreatorID: creatorID,
		Title:     title,
		Body:      body,
		Price:     price,
		FilePath:  filePath,
	}
	if err := s.repo.Create(content); err != nil {
		return nil, err
	}
	return content, nil
}
