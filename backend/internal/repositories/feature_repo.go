package repositories

import (
	"context"
	"errors"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"

	"gorm.io/gorm"
)

// FeatureRepository gère la persistance des Feature Flags.
type FeatureRepository struct {
	db *gorm.DB
}

// NewFeatureRepository crée une instance de FeatureRepository.
func NewFeatureRepository(db *gorm.DB) *FeatureRepository {
	return &FeatureRepository{db}
}

// List renvoie la liste de toutes les features (clé, description, état).
func (r *FeatureRepository) List(ctx context.Context) ([]models.Feature, error) {
	var features []models.Feature
	if err := r.db.WithContext(ctx).Find(&features).Error; err != nil {
		return nil, err
	}
	return features, nil
}

// Update modifie l’état (enabled) d’une feature identifiée par sa clé.
func (r *FeatureRepository) Update(ctx context.Context, key string, enabled bool) error {
	res := r.db.WithContext(ctx).
		Model(&models.Feature{}).
		Where("key = ?", key).
		Update("enabled", enabled)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return errors.New("feature not found")
	}
	return nil
}
