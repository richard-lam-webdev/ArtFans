// backend/internal/handlers/comment_handler.go
package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type CommentHandler struct {
	service *services.CommentService
}

func NewCommentHandler(svc *services.CommentService) *CommentHandler {
	return &CommentHandler{service: svc}
}

// GET /api/contents/:contentId/comments
func (h *CommentHandler) GetComments(c *gin.Context) {
	cidParam := c.Param("id")
	contentID, err := uuid.Parse(cidParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}
	userRaw, exists := c.Get("userID")
	var userID uuid.UUID
	if exists {
		userID, _ = uuid.Parse(userRaw.(string))
	}
	comments, err := h.service.FetchComments(contentID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de charger les commentaires"})
		return
	}
	// On peut formater la réponse pour ne renvoyer que les champs utiles
	var out []gin.H
	for _, cm := range comments {
		out = append(out, gin.H{
			"id":         cm.ID,
			"author_id":  cm.AuthorID,
			"text":       cm.Text,
			"created_at": cm.CreatedAt,
		})
	}
	c.JSON(http.StatusOK, out)
}

// POST /api/contents/:contentId/comments
func (h *CommentHandler) PostComment(c *gin.Context) {
	// Récupérer userID depuis le contexte (même méthode que pour Subscriptions)
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	authorID, _ := uuid.Parse(userRaw.(string))

	cidParam := c.Param("id")
	contentID, err := uuid.Parse(cidParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}

	var body struct {
		Text string `json:"text"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Text == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "texte requis"})
		return
	}

	comment, err := h.service.PostComment(contentID, authorID, body.Text, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de poster le commentaire"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{
		"id":         comment.ID,
		"author_id":  comment.AuthorID,
		"text":       comment.Text,
		"created_at": comment.CreatedAt,
	})
}
