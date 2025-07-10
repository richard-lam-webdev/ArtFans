package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

// ReportContentHandler POST /api/contents/:id/report
func ReportContentHandler(c *gin.Context) {
	// 1) Récupérer l'ID de l'utilisateur courant dans le contexte
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Utilisateur non authentifié"})
		return
	}
	userIDStr, ok := userRaw.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ID utilisateur invalide"})
		return
	}
	reporterID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur mal formé"})
		return
	}

	// 2) Parser l'ID du contenu
	idStr := c.Param("id")
	contentID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de contenu invalide"})
		return
	}

	// 3) Lire le JSON (raison optionnelle)
	var payload struct {
		Reason string `json:"reason"`
	}
	_ = c.ShouldBindJSON(&payload)

	// 4) Construire et sauvegarder le report
	report := &models.Report{
		TargetContentID: contentID,
		ReporterID:      reporterID,
		Reason:          payload.Reason,
		CreatedAt:       time.Now().UTC(),
	}
	if err := repositories.NewReportRepository().Create(report); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de créer le report"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "report created"})
}

// ListReportsHandler GET /api/admin/reports
// Middleware: JWTAuth + AdminMiddleware
func ListReportsHandler(c *gin.Context) {
	repo := repositories.NewReportRepository()
	reports, err := repo.FindAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les reports"})
		return
	}

	// Formater la réponse
	var out []gin.H
	for _, r := range reports {
		out = append(out, gin.H{
			"id":                r.ID,
			"target_content_id": r.TargetContentID,
			"reporter_id":       r.ReporterID,
			"reason":            r.Reason,
			"created_at":        r.CreatedAt.Format(time.RFC3339),
		})
	}

	c.JSON(http.StatusOK, gin.H{"reports": out})
}
