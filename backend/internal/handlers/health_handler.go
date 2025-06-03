package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// HealthCheck renvoie un status 200 simple pour vérifier que l’API tourne
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
