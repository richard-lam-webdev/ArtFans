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
	log.Println("➡️ GetAllContents called")

	userIDRaw, ok := c.Get("userID")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, err := uuid.Parse(userIDRaw.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	contents, err := h.service.GetContentsByUserID(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"contents": contents})
}


// GET /api/contents/:id
func (h *ContentHandler) GetContentByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	content, err := h.service.GetContentByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		return
	}

	userID := c.GetString("userID")
	if userID != content.CreatorID.String() {
		c.JSON(http.StatusForbidden, gin.H{"error": "Accès interdit"})
		return
	}

	c.JSON(http.StatusOK, content)
}

// PUT /api/contents/:id
func (h *ContentHandler) UpdateContent(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	existing, err := h.service.GetContentByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		return
	}

	userID := c.GetString("userID")
	if userID != existing.CreatorID.String() {
		c.JSON(http.StatusForbidden, gin.H{"error": "Interdit"})
		return
	}

	var payload struct {
		Title string `json:"title"`
		Body  string `json:"body"`
		Price int    `json:"price"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payload invalide"})
		return
	}

	existing.Title = payload.Title
	existing.Body = payload.Body
	existing.Price = payload.Price

	if err := h.service.UpdateContent(existing); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur update"})
		return
	}

	c.JSON(http.StatusOK, existing)
}

// DELETE /api/contents/:id
func (h *ContentHandler) DeleteContent(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	content, err := h.service.GetContentByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		return
	}

	userID := c.GetString("userID")
	if userID != content.CreatorID.String() {
		c.JSON(http.StatusForbidden, gin.H{"error": "Interdit"})
		return
	}

	if err := h.service.DeleteContent(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur suppression"})
		return
	}

	c.Status(http.StatusNoContent)
}
