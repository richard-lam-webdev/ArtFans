package handlers

import (
	"errors"

	gosentry "github.com/getsentry/sentry-go"
	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/sentry"
)

func TestSentryHandler(c *gin.Context) {
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
	err := errors.New("erreur de test: ceci est une erreur simulée")

	logger.LogError(err, "test_error", map[string]interface{}{
		"test": true,
	})

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
	panic("Test panic: ceci est un panic simulé pour Sentry")
}

// TestSentryPaymentHandler teste une erreur de paiement
func TestSentryPaymentHandler(c *gin.Context) {
	paymentErr := errors.New("card_declined: insufficient funds")

	logger.LogPayment("test_payment_failed", "123", 30.00, false, map[string]interface{}{
		"error": paymentErr.Error(),
		"test":  true,
	})

	sentry.CapturePaymentError(paymentErr, "123", 30.00, map[string]interface{}{
		"stripe_error_code": "card_declined",
		"test":              true,
	})

	for i := 0; i < 5; i++ {
		sentry.CaptureAuthError("multiple_failed_logins", "test@example.com", c.ClientIP(), "test_simulation")
	}

	c.JSON(400, gin.H{
		"error":   "Erreur de paiement simulée",
		"message": "Vérifiez Sentry pour voir l'erreur et l'alerte",
	})
}
