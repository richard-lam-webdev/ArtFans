package handlers

import (
	"errors"

	gosentry "github.com/getsentry/sentry-go"
	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/sentry"
)

// TestSentryHandler teste l'envoi simple à Sentry

func TestSentryHandler(c *gin.Context) {
	// Test 1: Message simple
	sentry.CaptureMessage("Test Sentry: Message de test", gosentry.LevelInfo, map[string]interface{}{
		"test":       true,
		"endpoint":   "/test/sentry",
		"user_agent": c.Request.UserAgent(),
	})

	c.JSON(200, gin.H{
		"message": "Message envoyé à Sentry",
		"check":   "Vérifiez dans votre dashboard Sentry",
	})
}

// TestSentryErrorHandler teste l'envoi d'erreur
func TestSentryErrorHandler(c *gin.Context) {
	// Simuler une erreur
	err := errors.New("erreur de test: ceci est une erreur simulée")

	// Logger localement
	logger.LogError(err, "test_error", map[string]interface{}{
		"test": true,
	})

	// Envoyer à Sentry
	sentry.CaptureError(err, map[string]interface{}{
		"test_context": map[string]interface{}{
			"endpoint": "/test/sentry-error",
			"ip":       c.ClientIP(),
			"test":     true,
		},
	})

	c.JSON(500, gin.H{
		"error": "Erreur simulée envoyée à Sentry",
	})
}

// TestSentryPanicHandler teste la capture de panic
func TestSentryPanicHandler(c *gin.Context) {
	// ATTENTION: Ceci va faire crasher cette requête
	panic("Test panic: ceci est un panic simulé pour Sentry")
}

// TestSentryPaymentHandler teste une erreur de paiement
func TestSentryPaymentHandler(c *gin.Context) {
	// Simuler une erreur de paiement
	paymentErr := errors.New("card_declined: insufficient funds")

	// Logger comme erreur de paiement
	logger.LogPayment("test_payment_failed", "123", 30.00, false, map[string]interface{}{
		"error": paymentErr.Error(),
		"test":  true,
	})

	// Envoyer à Sentry avec contexte de paiement
	sentry.CapturePaymentError(paymentErr, "123", 30.00, map[string]interface{}{
		"stripe_error_code": "card_declined",
		"test":              true,
	})

	// Simuler plusieurs tentatives (pour déclencher une alerte)
	for i := 0; i < 5; i++ {
		sentry.CaptureAuthError("multiple_failed_logins", "test@example.com", c.ClientIP(), "test_simulation")
	}

	c.JSON(400, gin.H{
		"error":   "Erreur de paiement simulée",
		"message": "Vérifiez Sentry pour voir l'erreur et l'alerte",
	})
}
