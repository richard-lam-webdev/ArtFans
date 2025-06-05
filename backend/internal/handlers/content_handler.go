package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type Handler struct {
	contentService *services.ContentService
}

func NewHandler(contentService *services.ContentService) *Handler {
	return &Handler{
		contentService: contentService,
	}
}

func (h *Handler) CreateContent(c *gin.Context) {
	user := c.MustGet("user").(*models.User)

	title := c.PostForm("title")
	body := c.PostForm("body")
	priceStr := c.PostForm("price")
	if title == "" || body == "" || priceStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Champs requis manquants"})
		return
	}
	price, err := strconv.Atoi(priceStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Prix invalide"})
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Fichier requis"})
		return
	}

	content, err := h.contentService.CreateContent(
		user.ID,
		user.Username,
		title,
		body,
		price,
		file,
		string(user.Role),
	)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, content)
}
