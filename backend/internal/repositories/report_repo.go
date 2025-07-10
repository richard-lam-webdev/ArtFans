package repositories

import (
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

// ReportRepository gère les opérations CRUD sur les signalements.
type ReportRepository struct {
	db *gorm.DB
}

// NewReportRepository instancie un ReportRepository.
func NewReportRepository() *ReportRepository {
	return &ReportRepository{db: database.DB}
}

// Create ajoute un nouveau report en base.
func (r *ReportRepository) Create(report *models.Report) error {
	return r.db.Create(report).Error
}

// FindAll récupère tous les reports, triés par date décroissante.
func (r *ReportRepository) FindAll() ([]models.Report, error) {
	var reports []models.Report
	err := r.db.
		Order("created_at DESC").
		Find(&reports).
		Error
	return reports, err
}

func (r *ReportRepository) DeleteByContentID(contentID uuid.UUID) error {
	return r.db.
		Where("target_content_id = ?", contentID).
		Delete(&models.Report{}).
		Error
}
