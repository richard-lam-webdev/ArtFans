// backend/internal/handlers/content.go
package handlers

import (
	"log"
	"net/http"
	"path/filepath"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

// ContentHandler regroupe les routes liées au contenu
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

	/* -------- FORM-DATA -------- */
	username := c.PostForm("username") // envoyé par le client
	role := c.PostForm("role")         // ex: "creator"

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

	/* -------- SERVICE -------- */
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

	/* -------- OK -------- */
	c.JSON(http.StatusCreated, gin.H{
		"id":        content.ID,
		"title":     content.Title,
		"body":      content.Body,
		"price":     content.Price,
		"file_path": filepath.Base(content.FilePath),
	})
}

// GetAllContents GET /api/contents
func (h *ContentHandler) GetAllContents(c *gin.Context) {
	contents, err := h.service.GetAllContents()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	// ✅ Toujours renvoyer un tableau, même vide
	c.JSON(http.StatusOK, gin.H{"contents": contents})
}
