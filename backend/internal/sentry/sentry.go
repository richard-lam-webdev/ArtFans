package sentry

import (
	"fmt"
	"os"
	"time"

	"github.com/getsentry/sentry-go"
	gosentry "github.com/getsentry/sentry-go"
	sentrygin "github.com/getsentry/sentry-go/gin"
	"github.com/gin-gonic/gin"
)

// InitSentry initialise Sentry
func InitSentry() error {
	dsn := os.Getenv("SENTRY_DSN")
	if dsn == "" {
		fmt.Println("⚠️  Sentry DSN non configuré, monitoring désactivé")
		return nil
	}

	environment := os.Getenv("SENTRY_ENVIRONMENT")
	if environment == "" {
		environment = "development"
	}

	err := gosentry.Init(gosentry.ClientOptions{
		Dsn:              dsn,
		Environment:      environment,
		TracesSampleRate: 0.1,
		BeforeSend: func(event *gosentry.Event, hint *gosentry.EventHint) *gosentry.Event {
			if event.User.Email != "" {
				event.User.Email = ""
			}
			return event
		},
	})

	if err != nil {
		return fmt.Errorf("sentry.Init: %v", err)
	}

	defer sentry.Flush(2 * time.Second)

	fmt.Println("✅ Sentry initialisé")
	return nil
}

func Middleware() gin.HandlerFunc {
	return sentrygin.New(sentrygin.Options{
		Repanic:         true,
		WaitForDelivery: true,
	})
}

func CaptureError(err error, context map[string]interface{}) {
	if err == nil {
		return
	}

	gosentry.WithScope(func(scope *gosentry.Scope) {
		for key, value := range context {
			scope.SetExtra(key, value)
		}

		// Capturer l'erreur
		gosentry.CaptureException(err)
	})
}

func CaptureMessage(message string, level gosentry.Level, context map[string]interface{}) {
	gosentry.WithScope(func(scope *gosentry.Scope) {
		scope.SetLevel(level)

		for key, value := range context {
			scope.SetExtra(key, value)
		}

		gosentry.CaptureMessage(message)
	})
}

func CapturePaymentError(err error, userID string, amount float64, metadata map[string]interface{}) {
	context := map[string]interface{}{
		"payment": map[string]interface{}{
			"user_id":  userID,
			"amount":   amount,
			"metadata": metadata,
		},
	}

	CaptureError(err, context)
}

func CaptureAuthError(event string, email string, ip string, reason string) {
	if event == "multiple_failed_logins" {
		CaptureMessage(
			fmt.Sprintf("Multiple failed login attempts for %s", email),
			gosentry.LevelWarning,
			map[string]interface{}{
				"auth": map[string]interface{}{
					"email":  email,
					"ip":     ip,
					"reason": reason,
				},
			},
		)
	}
}

func RecoverWithSentry() {
	if err := recover(); err != nil {
		gosentry.CurrentHub().Recover(err)
		panic(err)
	}
}
