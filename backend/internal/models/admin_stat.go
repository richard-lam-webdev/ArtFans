package models

import (
	"time"

	"github.com/google/uuid"
)

type AdminStatsSimple struct {
	TotalUsers       int64 `json:"total_users"`
	TotalCreators    int64 `json:"total_creators"`
	TotalContents    int64 `json:"total_contents"`
	TotalRevenue     int64 `json:"total_revenue"`
	TotalSubscribers int64 `json:"total_subscribers"`
	PendingContents  int64 `json:"pending_contents"`
	ApprovedContents int64 `json:"approved_contents"`
	RejectedContents int64 `json:"rejected_contents"`

	AvgRevenuePerUser    float64 `json:"avg_revenue_per_user"`
	AvgContentPerCreator float64 `json:"avg_content_per_creator"`
	ConversionRate       float64 `json:"conversion_rate"`

	Period    string    `json:"period"`
	StartDate time.Time `json:"start_date"`
	EndDate   time.Time `json:"end_date"`
}

type SimpleCreatorRank struct {
	Rank         int       `json:"rank"`
	CreatorID    uuid.UUID `json:"creator_id"`
	Username     string    `json:"username"`
	Email        string    `json:"email"`
	ContentCount int64     `json:"content_count"`
	TotalRevenue int64     `json:"total_revenue"`
	Subscribers  int64     `json:"subscribers"`
	JoinedAt     time.Time `json:"joined_at"`
}

type SimpleContentRank struct {
	Rank        int       `json:"rank"`
	ContentID   uuid.UUID `json:"content_id"`
	Title       string    `json:"title"`
	CreatorName string    `json:"creator_name"`
	Price       int       `json:"price"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

type RevenueByPeriod struct {
	Date   time.Time `json:"date"`
	Amount int64     `json:"amount"`
}

type AdminDashboard struct {
	Stats         AdminStatsSimple    `json:"stats"`
	TopCreators   []SimpleCreatorRank `json:"top_creators"`
	TopContents   []SimpleContentRank `json:"top_contents"`
	FlopContents  []SimpleContentRank `json:"flop_contents"`
	RecentRevenue []RevenueByPeriod   `json:"recent_revenue"`
}

type ContentStatusCount struct {
	Status string `json:"status"`
	Count  int64  `json:"count"`
}
