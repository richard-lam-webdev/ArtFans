// internal/services/admin_stats_service.go

package services

import (
	"fmt"
	"time"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
)

type AdminStatsService struct{}

func NewAdminStatsService() *AdminStatsService {
	return &AdminStatsService{}
}

// GetBasicStats - Stats de base avec vos tables existantes
func (s *AdminStatsService) GetBasicStats(days int) (*models.AdminStatsSimple, error) {
	var stats models.AdminStatsSimple

	// Période
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)
	stats.Period = fmt.Sprintf("%d days", days)
	stats.StartDate = startDate
	stats.EndDate = endDate

	// Total Users dans la période
	database.DB.Model(&models.User{}).
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&stats.TotalUsers)

	// Total Creators dans la période
	database.DB.Model(&models.User{}).
		Where("role = ? AND created_at >= ? AND created_at <= ?", "creator", startDate, endDate).
		Count(&stats.TotalCreators)

	// Total Contents dans la période
	database.DB.Model(&models.Content{}).
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&stats.TotalContents)

	// Total Revenue (depuis les payments dans la période)
	database.DB.Model(&models.Payment{}).
		Where("paid_at >= ? AND paid_at <= ? AND status = ?", startDate, endDate, "succeeded").
		Select("COALESCE(SUM(amount), 0)").
		Scan(&stats.TotalRevenue)

	// Total Subscribers actifs
	database.DB.Model(&models.Subscription{}).
		Where("start_date <= ? AND end_date >= ?", endDate, startDate).
		Count(&stats.TotalSubscribers)

	// Contents par status
	database.DB.Model(&models.Content{}).
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, models.ContentStatusPending).
		Count(&stats.PendingContents)

	database.DB.Model(&models.Content{}).
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, models.ContentStatusApproved).
		Count(&stats.ApprovedContents)

	database.DB.Model(&models.Content{}).
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, models.ContentStatusRejected).
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

// GetTopCreators - Top créateurs avec vos tables existantes
func (s *AdminStatsService) GetTopCreators(limit int, days int) ([]models.SimpleCreatorRank, error) {
	var creators []models.SimpleCreatorRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	// Requête avec vos tables existantes
	query := `
		SELECT 
			ROW_NUMBER() OVER (ORDER BY content_count DESC, total_revenue DESC) as rank,
			u.id as creator_id,
			u.username,
			u.email,
			u.created_at as joined_at,
			COALESCE(stats.content_count, 0) as content_count,
			COALESCE(stats.total_revenue, 0) as total_revenue,
			COALESCE(stats.subscribers, 0) as subscribers
		FROM users u
		LEFT JOIN (
			SELECT 
				c.creator_id,
				COUNT(c.id) as content_count,
				SUM(c.price) as total_revenue,
				COUNT(DISTINCT s.subscriber_id) as subscribers
			FROM content c
			LEFT JOIN subscription s ON c.creator_id = s.creator_id 
				AND s.start_date >= ? AND s.start_date <= ?
			WHERE c.created_at >= ? AND c.created_at <= ?
			GROUP BY c.creator_id
		) stats ON u.id = stats.creator_id
		WHERE u.role = 'creator'
		ORDER BY content_count DESC, total_revenue DESC
		LIMIT ?
	`

	rows, err := database.DB.Raw(query, startDate, endDate, startDate, endDate, limit).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var creator models.SimpleCreatorRank
		if err := rows.Scan(&creator.Rank, &creator.CreatorID, &creator.Username,
			&creator.Email, &creator.JoinedAt, &creator.ContentCount,
			&creator.TotalRevenue, &creator.Subscribers); err != nil {
			return nil, err
		}
		creators = append(creators, creator)
	}

	return creators, nil
}

// GetTopContents - Top contenus les plus chers/récents
func (s *AdminStatsService) GetTopContents(limit int, days int) ([]models.SimpleContentRank, error) {
	var contents []models.SimpleContentRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			ROW_NUMBER() OVER (ORDER BY c.price DESC, c.created_at DESC) as rank,
			c.id as content_id,
			c.title,
			u.username as creator_name,
			c.price,
			c.status,
			c.created_at
		FROM content c
		JOIN users u ON c.creator_id = u.id
		WHERE c.created_at >= ? AND c.created_at <= ?
		ORDER BY c.price DESC, c.created_at DESC
		LIMIT ?
	`

	rows, err := database.DB.Raw(query, startDate, endDate, limit).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var content models.SimpleContentRank
		if err := rows.Scan(&content.Rank, &content.ContentID, &content.Title,
			&content.CreatorName, &content.Price, &content.Status, &content.CreatedAt); err != nil {
			return nil, err
		}
		contents = append(contents, content)
	}

	return contents, nil
}

// GetFlopContents - Contenus les moins chers ou les plus anciens
func (s *AdminStatsService) GetFlopContents(limit int, days int) ([]models.SimpleContentRank, error) {
	var contents []models.SimpleContentRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			ROW_NUMBER() OVER (ORDER BY c.price ASC, c.created_at ASC) as rank,
			c.id as content_id,
			c.title,
			u.username as creator_name,
			c.price,
			c.status,
			c.created_at
		FROM content c
		JOIN users u ON c.creator_id = u.id
		WHERE c.created_at >= ? AND c.created_at <= ?
		ORDER BY c.price ASC, c.created_at ASC
		LIMIT ?
	`

	rows, err := database.DB.Raw(query, startDate, endDate, limit).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var content models.SimpleContentRank
		if err := rows.Scan(&content.Rank, &content.ContentID, &content.Title,
			&content.CreatorName, &content.Price, &content.Status, &content.CreatedAt); err != nil {
			return nil, err
		}
		contents = append(contents, content)
	}

	return contents, nil
}

// GetRevenueByDay - Revenus des 7 derniers jours
func (s *AdminStatsService) GetRevenueByDay(days int) ([]models.RevenueByPeriod, error) {
	var revenue []models.RevenueByPeriod

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			DATE(paid_at) as date,
			COALESCE(SUM(amount), 0) as amount
		FROM payment 
		WHERE paid_at >= ? AND paid_at <= ? AND status = 'succeeded'
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

// GetDashboard - Toutes les données pour le dashboard
func (s *AdminStatsService) GetDashboard(days int) (*models.AdminDashboard, error) {
	dashboard := &models.AdminDashboard{}

	// Stats principales
	stats, err := s.GetBasicStats(days)
	if err != nil {
		return nil, err
	}
	dashboard.Stats = *stats

	// Top créateurs
	topCreators, err := s.GetTopCreators(5, days)
	if err != nil {
		return nil, err
	}
	dashboard.TopCreators = topCreators

	// Top contenus
	topContents, err := s.GetTopContents(5, days)
	if err != nil {
		return nil, err
	}
	dashboard.TopContents = topContents

	// Flop contenus
	flopContents, err := s.GetFlopContents(5, days)
	if err != nil {
		return nil, err
	}
	dashboard.FlopContents = flopContents

	// Revenus récents
	recentRevenue, err := s.GetRevenueByDay(7)
	if err != nil {
		return nil, err
	}
	dashboard.RecentRevenue = recentRevenue

	return dashboard, nil
}
