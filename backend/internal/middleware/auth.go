// backend/internal/middleware/auth.go
package middleware

import (
	"net/http"
	"strings"

	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
)

// JWTAuth vérifie la présence et la validité du token dans l'en-tête Authorization.
func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token manquant ou mal formé"})
			return
		}
		tokenStr := parts[1]

		// Parse le JWT
		token, err := jwt.ParseWithClaims(tokenStr, &jwt.StandardClaims{}, func(t *jwt.Token) (interface{}, error) {
			return []byte(config.C.JwtSecret), nil
		})
		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token invalide"})
			return
		}

		// Récupère les claims standard (dont le Subject = userID)
		claims, ok := token.Claims.(*jwt.StandardClaims)
		if !ok {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "claims invalides"})
			return
		}

		// Stocke l’ID utilisateur dans le contexte Gin
		c.Set("userID", claims.Subject)
		c.Next()
	}
}
