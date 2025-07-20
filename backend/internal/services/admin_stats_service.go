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
	var subscriptionCount int64

	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)
	stats.Period = fmt.Sprintf("%d days", days)
	stats.StartDate = startDate
	stats.EndDate = endDate

	database.DB.Table("user").
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&stats.TotalUsers)

	database.DB.Table("user").
		Where("role = ? AND created_at >= ? AND created_at <= ?", "creator", startDate, endDate).
		Count(&stats.TotalCreators)

	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&stats.TotalContents)

	database.DB.Table("subscription").
		Where("created_at >= ? AND created_at <= ?", startDate, endDate).
		Count(&subscriptionCount)
	stats.TotalRevenue = subscriptionCount * 3000

	database.DB.Table("subscription").
		Where("start_date <= ? AND end_date >= ?", endDate, startDate).
		Count(&stats.TotalSubscribers)

	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, "pending").
		Count(&stats.PendingContents)

	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, "approved").
		Count(&stats.ApprovedContents)

	database.DB.Table("content").
		Where("created_at >= ? AND created_at <= ? AND status = ?", startDate, endDate, "rejected").
		Count(&stats.RejectedContents)

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

func (s *AdminStatsService) GetTopCreators(limit int, days int) ([]models.SimpleCreatorRank, error) {
	var creators []models.SimpleCreatorRank

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

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

		if parsedID, err := uuid.Parse(creatorIDStr); err == nil {
			creator.CreatorID = parsedID
		}

		allCreators = append(allCreators, creator)
	}

	for i, creator := range allCreators {
		database.DB.Table("content").
			Where("creator_id = ? AND created_at >= ? AND created_at <= ?",
				creator.CreatorID, startDate, endDate).
			Count(&allCreators[i].ContentCount)

		var subscriptionCount int64
		database.DB.Table("subscription").
			Where("creator_id = ? AND created_at >= ? AND created_at <= ?",
				creator.CreatorID, startDate, endDate).
			Count(&subscriptionCount)

		allCreators[i].TotalRevenue = subscriptionCount * 3000

		allCreators[i].Subscribers = subscriptionCount

		fmt.Printf("DEBUG Creator %s (ID: %s): ContentCount=%d, SubscriptionCount=%d, Revenue=%d\n",
			creator.Username, creator.CreatorID, allCreators[i].ContentCount, subscriptionCount, allCreators[i].TotalRevenue)
	}

	sort.Slice(allCreators, func(i, j int) bool {
		if allCreators[i].TotalRevenue != allCreators[j].TotalRevenue {
			return allCreators[i].TotalRevenue > allCreators[j].TotalRevenue
		}
		return allCreators[i].ContentCount > allCreators[j].ContentCount
	})

	if limit > len(allCreators) {
		limit = len(allCreators)
	}

	for i := 0; i < len(allCreators) && i < limit; i++ {
		allCreators[i].Rank = i + 1
		creators = append(creators, allCreators[i])
	}

	fmt.Printf("DEBUG: Returning %d creators out of %d total\n", len(creators), len(allCreators))

	return creators, nil
}

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
		if parsedID, err := uuid.Parse(contentIDStr); err == nil {
			content.ContentID = parsedID
		}
		contents = append(contents, content)
	}

	return contents, nil
}

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
		if parsedID, err := uuid.Parse(contentIDStr); err == nil {
			content.ContentID = parsedID
		}
		contents = append(contents, content)
	}

	return contents, nil
}

func (s *AdminStatsService) GetRevenueByDay(days int) ([]models.RevenueByPeriod, error) {
	var revenue []models.RevenueByPeriod

	startDate := time.Now().AddDate(0, 0, -days)
	endDate := time.Now()

	query := `
		SELECT 
			DATE(created_at) as date,
			COUNT(*) * 3000 as amount
		FROM subscription 
		WHERE created_at >= $1 AND created_at <= $2
		GROUP BY DATE(created_at)
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

func (s *AdminStatsService) GetDashboard(days int) (*models.AdminDashboard, error) {
	dashboard := &models.AdminDashboard{}

	stats, err := s.GetBasicStats(days)
	if err != nil {
		return nil, err
	}
	dashboard.Stats = *stats

	topCreators, err := s.GetTopCreators(5, days)
	if err != nil {
		topCreators = []models.SimpleCreatorRank{}
	}
	dashboard.TopCreators = topCreators

	topContents, err := s.GetTopContents(5, days)
	if err != nil {
		topContents = []models.SimpleContentRank{}
	}
	dashboard.TopContents = topContents

	flopContents, err := s.GetFlopContents(5, days)
	if err != nil {
		flopContents = []models.SimpleContentRank{}
	}
	dashboard.FlopContents = flopContents

	recentRevenue, err := s.GetRevenueByDay(7)
	if err != nil {
		recentRevenue = []models.RevenueByPeriod{}
	}
	dashboard.RecentRevenue = recentRevenue

	return dashboard, nil
}

func (s *AdminStatsService) GetSimpleDashboard(days int) (*models.AdminDashboard, error) {
	dashboard := &models.AdminDashboard{}

	stats, err := s.GetBasicStats(days)
	if err != nil {
		return nil, err
	}
	dashboard.Stats = *stats

	dashboard.TopCreators = []models.SimpleCreatorRank{}
	dashboard.TopContents = []models.SimpleContentRank{}
	dashboard.FlopContents = []models.SimpleContentRank{}
	dashboard.RecentRevenue = []models.RevenueByPeriod{}

	return dashboard, nil
}
