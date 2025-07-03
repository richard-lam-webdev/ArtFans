// backend/internal/handlers/subscription_handler.go
package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type SubscriptionHandler struct {
	service *services.SubscriptionService
}

func NewSubscriptionHandler(service *services.SubscriptionService) *SubscriptionHandler {
	return &SubscriptionHandler{service: service}
}

// POST /api/subscriptions/:creatorID
func (h *SubscriptionHandler) Subscribe(c *gin.Context) {
	subscriberIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	subscriberID, _ := uuid.Parse(subscriberIDRaw.(string))

	creatorIDParam := c.Param("creatorID")
	creatorID, err := uuid.Parse(creatorIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	if err := h.service.Subscribe(creatorID, subscriberID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur abonnement"})
		return
	}

	if subscriberID == creatorID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Impossible de s’abonner à soi-même"})
		return
	}

	c.Status(http.StatusCreated)
}

// DELETE /api/subscriptions/:creatorID
func (h *SubscriptionHandler) Unsubscribe(c *gin.Context) {
	subscriberIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	subscriberID, _ := uuid.Parse(subscriberIDRaw.(string))

	creatorIDParam := c.Param("creatorID")
	creatorID, err := uuid.Parse(creatorIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	if err := h.service.Unsubscribe(subscriberID, creatorID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur désabonnement"})
		return
	}

	c.Status(http.StatusNoContent)
}

// GET /api/subscriptions/:creatorID
func (h *SubscriptionHandler) IsSubscribed(c *gin.Context) {
	subscriberIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	subscriberID, _ := uuid.Parse(subscriberIDRaw.(string))

	creatorIDParam := c.Param("creatorID")
	creatorID, err := uuid.Parse(creatorIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	ok, err := h.service.IsSubscribed(subscriberID, creatorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"subscribed": ok})
}

// GET /api/subscriptions
func (h *SubscriptionHandler) GetFollowedCreatorIDs(c *gin.Context) {
	subscriberIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	subscriberID, _ := uuid.Parse(subscriberIDRaw.(string))

	ids, err := h.service.GetFollowedCreatorIDs(subscriberID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"creator_ids": ids})
}
