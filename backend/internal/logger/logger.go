package logger

import (
	"io"
	"os"
	"time"

	"maps"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

func init() {
	Log = logrus.New()

	Log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "time",
			logrus.FieldKeyLevel: "level",
			logrus.FieldKeyMsg:   "message",
		},
	})

	logFile, err := os.OpenFile("/logs/artfans-api.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err == nil {
		multiWriter := io.MultiWriter(os.Stdout, logFile)
		Log.SetOutput(multiWriter)
	} else {
		Log.SetOutput(os.Stdout)
	}

	if os.Getenv("ENV") == "production" {
		Log.SetLevel(logrus.InfoLevel)
	} else {
		Log.SetLevel(logrus.DebugLevel)
	}
}

func GinLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		clientIP := c.ClientIP()
		method := c.Request.Method
		statusCode := c.Writer.Status()
		errorMessage := c.Errors.ByType(gin.ErrorTypePrivate).String()

		if raw != "" {
			path = path + "?" + raw
		}

		entry := Log.WithFields(logrus.Fields{
			"type":        "http_request",
			"client_ip":   clientIP,
			"method":      method,
			"path":        path,
			"status_code": statusCode,
			"latency_ms":  latency.Milliseconds(),
			"user_agent":  c.Request.UserAgent(),
		})

		if userID, exists := c.Get("userID"); exists {
			entry = entry.WithField("user_id", userID)
		}

		if errorMessage != "" {
			entry.WithField("error", errorMessage).Error("Request failed")
		} else {
			entry.Info("Request completed")
		}
	}
}

func LogBusinessEvent(event string, data map[string]interface{}) {
	fields := logrus.Fields{
		"type":  "business_event",
		"event": event,
	}
	for k, v := range data {
		fields[k] = v
	}
	Log.WithFields(fields).Info("Business event")
}

func LogSecurity(event string, data map[string]interface{}) {
	fields := logrus.Fields{
		"type":  "security_event",
		"event": event,
	}
	for k, v := range data {
		fields[k] = v
	}
	Log.WithFields(fields).Warn("Security event")
}

func LogError(err error, context string, data map[string]interface{}) {
	fields := logrus.Fields{
		"type":    "error",
		"context": context,
		"error":   err.Error(),
	}
	for k, v := range data {
		fields[k] = v
	}
	Log.WithFields(fields).Error("Error occurred")
}

func LogPayment(event string, userID string, amount float64, success bool, data map[string]interface{}) {
	fields := logrus.Fields{
		"type":    "payment_event",
		"event":   event,
		"user_id": userID,
		"amount":  amount,
		"success": success,
	}
	for k, v := range data {
		fields[k] = v
	}

	if success {
		Log.WithFields(fields).Info("Payment event")
	} else {
		Log.WithFields(fields).Error("Payment failed")
	}
}

func LogContent(event string, userID string, contentID string, data map[string]interface{}) {
	fields := logrus.Fields{
		"type":       "content_event",
		"event":      event,
		"user_id":    userID,
		"content_id": contentID,
	}
	maps.Copy(fields, data)
	Log.WithFields(fields).Info("Content event")
}

func LogAdmin(event string, adminID uint, targetType string, targetID uint, data map[string]interface{}) {
	fields := logrus.Fields{
		"type":        "admin_action",
		"event":       event,
		"admin_id":    adminID,
		"target_type": targetType,
		"target_id":   targetID,
	}
	for k, v := range data {
		fields[k] = v
	}
	Log.WithFields(fields).Warn("Admin action")
}
