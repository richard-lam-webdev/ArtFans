// internal/handlers/admin_stats_handler.go

package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type AdminStatsHandler struct {
	service *services.AdminStatsService
}

func NewAdminStatsHandler() *AdminStatsHandler {
	return &AdminStatsHandler{
		service: services.NewAdminStatsService(),
	}
}

// GetStats GET /api/admin/stats
func (h *AdminStatsHandler) GetStats(c *gin.Context) {
	// Période par défaut : 30 jours
	days := 30
	if daysParam := c.Query("days"); daysParam != "" {
		if d, err := strconv.Atoi(daysParam); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	stats, err := h.service.GetBasicStats(days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Impossible de récupérer les statistiques",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

// GetDashboard GET /api/admin/dashboard
func (h *AdminStatsHandler) GetDashboard(c *gin.Context) {
	// Période par défaut : 30 jours
	days := 30
	if daysParam := c.Query("days"); daysParam != "" {
		if d, err := strconv.Atoi(daysParam); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	dashboard, err := h.service.GetDashboard(days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Impossible de récupérer le dashboard",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    dashboard,
	})
}

// GetTopCreators GET /api/admin/top-creators
func (h *AdminStatsHandler) GetTopCreators(c *gin.Context) {
	// Limite par défaut : 10
	limit := 10
	if limitParam := c.Query("limit"); limitParam != "" {
		if l, err := strconv.Atoi(limitParam); err == nil && l > 0 && l <= 50 {
			limit = l
		}
	}

	// Période par défaut : 30 jours
	days := 30
	if daysParam := c.Query("days"); daysParam != "" {
		if d, err := strconv.Atoi(daysParam); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	// ✨ UTILISER LA VERSION ULTRA-SAFE
	creators, err := h.service.GetTopCreators(limit, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Impossible de récupérer le top créateurs",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    creators,
		"meta": gin.H{
			"limit": limit,
			"days":  days,
		},
	})
}

// GetTopContents GET /api/admin/top-contents
func (h *AdminStatsHandler) GetTopContents(c *gin.Context) {
	// Limite par défaut : 10
	limit := 10
	if limitParam := c.Query("limit"); limitParam != "" {
		if l, err := strconv.Atoi(limitParam); err == nil && l > 0 && l <= 50 {
			limit = l
		}
	}

	// Période par défaut : 30 jours
	days := 30
	if daysParam := c.Query("days"); daysParam != "" {
		if d, err := strconv.Atoi(daysParam); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	contents, err := h.service.GetTopContents(limit, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Impossible de récupérer le top contenus",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    contents,
		"meta": gin.H{
			"limit": limit,
			"days":  days,
		},
	})
}

// GetFlopContents GET /api/admin/flop-contents
func (h *AdminStatsHandler) GetFlopContents(c *gin.Context) {
	// Limite par défaut : 10
	limit := 10
	if limitParam := c.Query("limit"); limitParam != "" {
		if l, err := strconv.Atoi(limitParam); err == nil && l > 0 && l <= 50 {
			limit = l
		}
	}

	// Période par défaut : 30 jours
	days := 30
	if daysParam := c.Query("days"); daysParam != "" {
		if d, err := strconv.Atoi(daysParam); err == nil && d > 0 && d <= 365 {
			days = d
		}
	}

	contents, err := h.service.GetFlopContents(limit, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Impossible de récupérer le flop contenus",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    contents,
		"meta": gin.H{
			"limit": limit,
			"days":  days,
		},
	})
}

// GetRevenueChart GET /api/admin/revenue-chart
func (h *AdminStatsHandler) GetRevenueChart(c *gin.Context) {
	// Période par défaut : 7 jours
	days := 7
	if daysParam := c.Query("days"); daysParam != "" {
		if d, err := strconv.Atoi(daysParam); err == nil && d > 0 && d <= 90 {
			days = d
		}
	}

	revenue, err := h.service.GetRevenueByDay(days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Impossible de récupérer les revenus",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    revenue,
		"meta": gin.H{
			"days": days,
		},
	})
}

// GetQuickStats GET /api/admin/quick-stats (pour affichage rapide)
func (h *AdminStatsHandler) GetQuickStats(c *gin.Context) {
	stats, err := h.service.GetBasicStats(30)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Impossible de récupérer les stats rapides",
		})
		return
	}

	// Version simplifiée pour l'affichage rapide
	quickStats := gin.H{
		"total_users":      stats.TotalUsers,
		"total_revenue":    stats.TotalRevenue,
		"pending_contents": stats.PendingContents,
		"total_creators":   stats.TotalCreators,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    quickStats,
	})
}
