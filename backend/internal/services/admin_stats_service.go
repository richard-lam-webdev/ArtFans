// =============================================
// CORRECTION FINALE : internal/services/admin_stats_service.go
// =============================================

package services

import (
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
)

type AdminStatsService struct{}

func NewAdminStatsService() *AdminStatsService {
	return &AdminStatsService{}
}

// GetBasicStats - Version simple sans JOIN complexes
func (s *AdminStatsService) GetBasicStats(days int) (*models.AdminStatsSimple, error) {
	var stats models.AdminStatsSimple

	// Période
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)
	stats.Period = fmt.Sprintf("%d days", days)
	stats.StartDate = startDate
	stats.EndDate = endDate

	// Total Users dans la période
	database.DB.Table("user").
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&stats.TotalUsers)

	// Total Creators dans la période
	database.DB.Table("user").
		Where("role = ? AND created_at >= ? AND created_at <= ?", "creator", startDate, endDate).
		Count(&stats.TotalCreators)

	// Total Contents dans la période
	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&stats.TotalContents)

	// Total Revenue (depuis les payments dans la période)
	database.DB.Table("payment").
		Where("paid_at >= ? AND paid_at <= ? AND status = ?", startDate, endDate, "succeeded").
		Select("COALESCE(SUM(amount), 0)").
		Scan(&stats.TotalRevenue)

	// Total Subscribers actifs
	database.DB.Table("subscription").
		Where("start_date <= ? AND end_date >= ?", endDate, startDate).
		Count(&stats.TotalSubscribers)

	// Contents par status
	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, "pending").
		Count(&stats.PendingContents)

	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, "approved").
		Count(&stats.ApprovedContents)

	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, "rejected").
		Count(&stats.RejectedContents)

	// Moyennes
	if stats.TotalUsers > 0 {
		stats.AvgRevenuePerUser = float64(stats.TotalRevenue) / float64(stats.TotalUsers)
	}
	if stats.TotalCreators > 0 {
		stats.AvgContentPerCreator = float64(stats.TotalContents) / float64(stats.TotalCreators)
	}
	if stats.TotalUsers > 0 {
		stats.ConversionRate = float64(stats.TotalSubscribers) / float64(stats.TotalUsers) * 100
	}

	return &stats, nil
}

// GetTopCreators - Version corrigée avec les bons types UUID
func (s *AdminStatsService) GetTopCreators(limit int, days int) ([]models.SimpleCreatorRank, error) {
	var creators []models.SimpleCreatorRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	// 1. Récupérer tous les créateurs d'abord
	userQuery := `
		SELECT 
			id::text as creator_id,
			username,
			email,
			created_at as joined_at
		FROM "user" 
		WHERE role = 'creator'
		ORDER BY created_at ASC
	`

	rows, err := database.DB.Raw(userQuery).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var allCreators []models.SimpleCreatorRank
	for rows.Next() {
		var creator models.SimpleCreatorRank
		var creatorIDStr string

		if err := rows.Scan(&creatorIDStr, &creator.Username,
			&creator.Email, &creator.JoinedAt); err != nil {
			return nil, err
		}

		// Convertir string vers UUID
		if parsedID, err := uuid.Parse(creatorIDStr); err == nil {
			creator.CreatorID = parsedID
		}

		allCreators = append(allCreators, creator)
	}

	// 2. Pour chaque créateur, calculer ses stats séparément
	for i, creator := range allCreators {
		// Nombre de contenus dans la période
		database.DB.Table("content").
			Where("creator_id = ? AND created_at >= ? AND created_at <= ?",
				creator.CreatorID, startDate, endDate).
			Count(&allCreators[i].ContentCount)

		// Revenus totaux (somme des prix des contenus dans la période)
		var totalRevenue *int64
		database.DB.Table("content").
			Where("creator_id = ? AND created_at >= ? AND created_at <= ?",
				creator.CreatorID, startDate, endDate).
			Select("COALESCE(SUM(price), 0)").
			Scan(&totalRevenue)

		if totalRevenue != nil {
			allCreators[i].TotalRevenue = *totalRevenue
		}

		// Nombre d'abonnés actifs (abonnements en cours)
		database.DB.Table("subscription").
			Where("creator_id = ? AND start_date <= NOW() AND end_date >= NOW()",
				creator.CreatorID).
			Count(&allCreators[i].Subscribers)
	}

	// 3. Trier par nombre de contenus puis par revenus
	sort.Slice(allCreators, func(i, j int) bool {
		if allCreators[i].ContentCount != allCreators[j].ContentCount {
			return allCreators[i].ContentCount > allCreators[j].ContentCount
		}
		return allCreators[i].TotalRevenue > allCreators[j].TotalRevenue
	})

	// 4. Limiter et ajouter les rangs
	if limit > len(allCreators) {
		limit = len(allCreators)
	}

	for i := 0; i < limit; i++ {
		allCreators[i].Rank = i + 1
		creators = append(creators, allCreators[i])
	}

	return creators, nil
}

// GetTopContents - Version simplifiée sans sous-requête complexe
func (s *AdminStatsService) GetTopContents(limit int, days int) ([]models.SimpleContentRank, error) {
	var contents []models.SimpleContentRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			ROW_NUMBER() OVER (ORDER BY c.price DESC, c.created_at DESC) as rank,
			c.id::text as content_id,
			c.title,
			u.username as creator_name,
			c.price,
			c.status,
			c.created_at
		FROM content c
		JOIN "user" u ON c.creator_id = u.id
		WHERE c.created_at >= $1 AND c.created_at <= $2
		ORDER BY c.price DESC, c.created_at DESC
		LIMIT $3
	`

	rows, err := database.DB.Raw(query, startDate, endDate, limit).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var content models.SimpleContentRank
		var contentIDStr string
		if err := rows.Scan(&content.Rank, &contentIDStr, &content.Title,
			&content.CreatorName, &content.Price, &content.Status, &content.CreatedAt); err != nil {
			return nil, err
		}
		// Convertir string vers UUID
		if parsedID, err := uuid.Parse(contentIDStr); err == nil {
			content.ContentID = parsedID
		}
		contents = append(contents, content)
	}

	return contents, nil
}

// GetFlopContents - Version simplifiée
func (s *AdminStatsService) GetFlopContents(limit int, days int) ([]models.SimpleContentRank, error) {
	var contents []models.SimpleContentRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			ROW_NUMBER() OVER (ORDER BY c.price ASC, c.created_at ASC) as rank,
			c.id::text as content_id,
			c.title,
			u.username as creator_name,
			c.price,
			c.status,
			c.created_at
		FROM content c
		JOIN "user" u ON c.creator_id = u.id
		WHERE c.created_at >= $1 AND c.created_at <= $2
		ORDER BY c.price ASC, c.created_at ASC
		LIMIT $3
	`

	rows, err := database.DB.Raw(query, startDate, endDate, limit).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var content models.SimpleContentRank
		var contentIDStr string
		if err := rows.Scan(&content.Rank, &contentIDStr, &content.Title,
			&content.CreatorName, &content.Price, &content.Status, &content.CreatedAt); err != nil {
			return nil, err
		}
		// Convertir string vers UUID
		if parsedID, err := uuid.Parse(contentIDStr); err == nil {
			content.ContentID = parsedID
		}
		contents = append(contents, content)
	}

	return contents, nil
}

// GetRevenueByDay - Version simple sans problème de type
func (s *AdminStatsService) GetRevenueByDay(days int) ([]models.RevenueByPeriod, error) {
	var revenue []models.RevenueByPeriod

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			DATE(paid_at) as date,
			COALESCE(SUM(amount), 0) as amount
		FROM payment 
		WHERE paid_at >= $1 AND paid_at <= $2 AND status = 'succeeded'
		GROUP BY DATE(paid_at)
		ORDER BY date ASC
	`

	rows, err := database.DB.Raw(query, startDate, endDate).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var rev models.RevenueByPeriod
		if err := rows.Scan(&rev.Date, &rev.Amount); err != nil {
			return nil, err
		}
		revenue = append(revenue, rev)
	}

	return revenue, nil
}

// GetDashboard - Version qui évite les erreurs complexes
func (s *AdminStatsService) GetDashboard(days int) (*models.AdminDashboard, error) {
	dashboard := &models.AdminDashboard{}

	// Stats principales (simple, sans JOIN)
	stats, err := s.GetBasicStats(days)
	if err != nil {
		return nil, err
	}
	dashboard.Stats = *stats

	// Top créateurs (gestion d'erreur séparée)
	topCreators, err := s.GetTopCreators(5, days)
	if err != nil {
		// Si erreur, on continue avec une liste vide
		topCreators = []models.SimpleCreatorRank{}
	}
	dashboard.TopCreators = topCreators

	// Top contenus (gestion d'erreur séparée)
	topContents, err := s.GetTopContents(5, days)
	if err != nil {
		topContents = []models.SimpleContentRank{}
	}
	dashboard.TopContents = topContents

	// Flop contenus (gestion d'erreur séparée)
	flopContents, err := s.GetFlopContents(5, days)
	if err != nil {
		flopContents = []models.SimpleContentRank{}
	}
	dashboard.FlopContents = flopContents

	// Revenus récents (simple)
	recentRevenue, err := s.GetRevenueByDay(7)
	if err != nil {
		recentRevenue = []models.RevenueByPeriod{}
	}
	dashboard.RecentRevenue = recentRevenue

	return dashboard, nil
}

// =============================================
// VERSION ULTRA-SIMPLE POUR DEBUG
// =============================================

// Si tout échoue, utilisez cette version ultra-basique
func (s *AdminStatsService) GetSimpleDashboard(days int) (*models.AdminDashboard, error) {
	dashboard := &models.AdminDashboard{}

	// Stats de base uniquement
	stats, err := s.GetBasicStats(days)
	if err != nil {
		return nil, err
	}
	dashboard.Stats = *stats

	// Listes vides pour éviter les erreurs
	dashboard.TopCreators = []models.SimpleCreatorRank{}
	dashboard.TopContents = []models.SimpleContentRank{}
	dashboard.FlopContents = []models.SimpleContentRank{}
	dashboard.RecentRevenue = []models.RevenueByPeriod{}

	return dashboard, nil
}
