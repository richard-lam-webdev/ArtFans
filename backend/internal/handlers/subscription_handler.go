// backend/internal/handlers/subscription_handler.go

package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/sentry"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type SubscriptionHandler struct {
	service *services.SubscriptionService
}

func NewSubscriptionHandler(service *services.SubscriptionService) *SubscriptionHandler {
	return &SubscriptionHandler{service: service}
}

func (s *SubscriptionService) Subscribe(creatorID, userID uuid.UUID) error {
	log.Printf("🔄 Début abonnement: user=%s -> creator=%s", userID, creatorID)

	// Vérifier si l'utilisateur n'est pas déjà abonné
	isSubscribed, err := s.IsSubscribed(userID, creatorID)
	if err != nil {
		log.Printf("❌ Erreur vérification abonnement: %v", err)
		return err
	}
	if isSubscribed {
		log.Printf("⚠️ Utilisateur déjà abonné")
		return errors.New("vous êtes déjà abonné à ce créateur")
	}

	// Vérifier que l'utilisateur ne s'abonne pas à lui-même
	if userID == creatorID {
		log.Printf("⚠️ Tentative auto-abonnement")
		return errors.New("impossible de s'abonner à soi-même")
	}

	now := time.Now()

	// CORRECTION : Transaction pour éviter les doubles entrées
	tx := database.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Créer l'abonnement d'abord
	sub := &models.Subscription{
		CreatorID:    creatorID,
		SubscriberID: userID,
		StartDate:    now,
		EndDate:      now.AddDate(0, 0, models.SubscriptionDurationDays),
		Price:        models.SubscriptionPriceCents,
		Status:       models.SubscriptionStatusActive,
	}

	if err := tx.Create(sub).Error; err != nil {
		tx.Rollback()
		log.Printf("❌ Erreur création abonnement: %v", err)
		return err
	}

	// Créer le paiement avec l'ID de subscription
	payment := &models.Payment{
		SubscriptionID: sub.ID,
		Amount:         models.SubscriptionPriceCents,
		PaidAt:         now,
		Status:         "succeeded",
	}

	if err := tx.Create(payment).Error; err != nil {
		tx.Rollback()
		log.Printf("❌ Erreur création paiement: %v", err)
		return err
	}

	// Valider la transaction
	if err := tx.Commit().Error; err != nil {
		log.Printf("❌ Erreur commit transaction: %v", err)
		return err
	}

	log.Printf("✅ Abonnement créé avec succès: subscription=%s, payment=%s", sub.ID, payment.ID)
	return nil
}

	logger.LogPayment("subscription_created", subscriberID.String(), 30.00, true, map[string]any{
		"creator_id": creatorID.String(),
		"method":     "stripe",
	})
	c.JSON(http.StatusCreated, gin.H{
		"message":    "Abonnement créé avec succès",
		"price":      "30€",
		"duration":   "30 jours",
		"creator_id": creatorID.String(),
	})
}

// DELETE /api/subscriptions/:creatorID - Se désabonner
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
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID créateur invalide"})
		return
	}

	if err := h.service.Unsubscribe(subscriberID, creatorID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors du désabonnement"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Désabonnement effectué avec succès",
	})
}

// GET /api/subscriptions/:creatorID - Vérifier l'abonnement
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
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID créateur invalide"})
		return
	}

	isSubscribed, err := h.service.IsSubscribed(subscriberID, creatorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	response := gin.H{
		"subscribed": isSubscribed,
		"price":      "30€",
		"duration":   "30 jours",
	}

	// Si abonné, ajouter les détails de l'abonnement
	if isSubscribed {
		subscription, err := h.service.GetActiveSubscription(subscriberID, creatorID)
		if err == nil && subscription != nil {
			response["end_date"] = subscription.EndDate
			response["days_remaining"] = subscription.DaysRemaining()
			response["start_date"] = subscription.StartDate
		}
	}

	c.JSON(http.StatusOK, response)
}

// GET /api/subscriptions - Mes abonnements
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

	c.JSON(http.StatusOK, gin.H{
		"creator_ids": ids,
		"count":       len(ids),
		"total_cost":  len(ids) * models.SubscriptionPriceEuros,
	})
}

// GET /api/subscriptions/my - Détails de mes abonnements
func (h *SubscriptionHandler) GetMySubscriptions(c *gin.Context) {
	subscriberIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	subscriberID, _ := uuid.Parse(subscriberIDRaw.(string))

	subscriptions, err := h.service.GetUserSubscriptions(subscriberID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	// Enrichir les données pour le frontend
	var enrichedSubscriptions []gin.H
	for _, sub := range subscriptions {
		enrichedSubscriptions = append(enrichedSubscriptions, gin.H{
			"creator_id":     sub.CreatorID,
			"start_date":     sub.StartDate,
			"end_date":       sub.EndDate,
			"days_remaining": sub.DaysRemaining(),
			"price":          "30€",
			"status":         sub.Status,
			"is_active":      sub.IsActive(),
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"subscriptions": enrichedSubscriptions,
		"count":         len(subscriptions),
		"total_cost":    len(subscriptions) * models.SubscriptionPriceEuros,
	})
}

// GET /api/creator/stats - Statistiques pour un créateur
func (h *SubscriptionHandler) GetCreatorStats(c *gin.Context) {
	userIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	creatorID, _ := uuid.Parse(userIDRaw.(string))

	stats, err := h.service.GetCreatorStats(creatorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

func (h *SubscriptionHandler) CheckSubscriptionStatus(c *gin.Context) {
	// Récupération de l'ID utilisateur depuis le contexte
	subscriberIDRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}

	subscriberID, err := uuid.Parse(subscriberIDRaw.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	// Récupération de l'ID créateur depuis les paramètres
	creatorIDParam := c.Param("creatorID")
	creatorID, err := uuid.Parse(creatorIDParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID créateur invalide"})
		return
	}

	// Vérification du statut d'abonnement
	isSubscribed, err := h.service.IsSubscribed(subscriberID, creatorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Erreur lors de la vérification du statut d'abonnement",
		})
		return
	}

	// Réponse simple avec le statut
	c.JSON(http.StatusOK, gin.H{
		"subscribed": isSubscribed,
		"creator_id": creatorID,
		"timestamp":  time.Now(),
	})
}
