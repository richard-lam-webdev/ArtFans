package handlers

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type ContentHandler struct {
	service *services.ContentService
}

func NewHandler(s *services.ContentService) *ContentHandler {
	return &ContentHandler{service: s}
}

// CreateContent POST /api/contents (protégé par JWTAuth)
func (h *ContentHandler) CreateContent(c *gin.Context) {
	/* -------- RÉCUP USER ID MIDDLEWARE -------- */
	userIDRaw, ok := c.Get("userID") // middleware JWTAuth stocke "userID"
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, err := uuid.Parse(userIDRaw.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	username := c.PostForm("username")
	role := c.PostForm("role")

	title := c.PostForm("title")
	body := c.PostForm("body")
	priceStr := c.PostForm("price")

	if title == "" || body == "" || priceStr == "" {
		log.Print("[CreateContent] champs manquants")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Champs requis manquants"})
		return
	}
	price, err := strconv.Atoi(priceStr)
	if err != nil {
		log.Printf("[CreateContent] prix invalide: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Prix invalide"})
		return
	}

	fileHeader, err := c.FormFile("file")
	if err != nil {
		log.Printf("[CreateContent] fichier manquant: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Fichier requis"})
		return
	}

	content, err := h.service.CreateContent(
		userID,
		username,
		title,
		body,
		price,
		fileHeader,
		role,
	)
	if err != nil {
		log.Printf("[CreateContent] service error: %v", err)
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":        content.ID,
		"title":     content.Title,
		"body":      content.Body,
		"price":     content.Price,
		"file_path": content.FilePath,
	})
}

func (h *ContentHandler) GetAllContents(c *gin.Context) {
	contents, err := h.service.GetAllContents()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"contents": contents})
}

// GetContentImage GET /api/contents/:id/image (protégé par JWT)
func (h *ContentHandler) GetContentImage(c *gin.Context) {
	// Récupère l'ID du contenu
	contentIDStr := c.Param("id")
	contentID, err := uuid.Parse(contentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de contenu invalide"})
		return
	}

	// Récupère l'ID utilisateur via le middleware JWTAuth
	userIDRaw, ok := c.Get("userID")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Non autorisé"})
		return
	}
	userID, err := uuid.Parse(userIDRaw.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	// Utilise le service pour servir l'image avec les vérifs
	err = h.service.ServeProtectedImage(c, contentID, userID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
}
