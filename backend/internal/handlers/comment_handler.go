package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type CommentHandler struct {
	svc *services.CommentService
}

func NewCommentHandler(svc *services.CommentService) *CommentHandler {
	return &CommentHandler{svc: svc}
}

// GET /api/contents/:id/comments
func (h *CommentHandler) GetComments(c *gin.Context) {
	userRaw, exists := c.Get("userID")
	var userID uuid.UUID
	if exists {
		userID, _ = uuid.Parse(userRaw.(string))
	}

	cid := c.Param("id")
	contentID, err := uuid.Parse(cid)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}

	comments, err := h.svc.FetchComments(contentID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de charger les commentaires"})
		return
	}

	c.JSON(http.StatusOK, comments)
}

// POST /api/contents/:id/comments
func (h *CommentHandler) PostComment(c *gin.Context) {
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	authorID, _ := uuid.Parse(userRaw.(string))

	cid := c.Param("id")
	contentID, err := uuid.Parse(cid)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}

	var body struct {
		Text     string     `json:"text"`
		ParentID *uuid.UUID `json:"parent_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Text == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "texte requis"})
		return
	}

	comment, err := h.svc.PostComment(contentID, authorID, body.Text, body.ParentID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de poster le commentaire"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":         comment.ID,
		"author_id":  comment.AuthorID,
		"text":       comment.Text,
		"parent_id":  comment.ParentID,
		"created_at": comment.CreatedAt.Format(time.RFC3339),
	})
}

// POST /api/comments/:commentID/like
func (h *CommentHandler) LikeComment(c *gin.Context) {
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, _ := uuid.Parse(userRaw.(string))

	id := c.Param("commentID")
	commentID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID commentaire invalide"})
		return
	}

	if err := h.svc.LikeComment(userID, commentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de liker le commentaire"})
		return
	}
	c.Status(http.StatusNoContent)
}

// DELETE /api/comments/:commentID/like
func (h *CommentHandler) UnlikeComment(c *gin.Context) {
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, _ := uuid.Parse(userRaw.(string))

	id := c.Param("commentID")
	commentID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID commentaire invalide"})
		return
	}

	if err := h.svc.UnlikeComment(userID, commentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de retirer le like"})
		return
	}
	c.Status(http.StatusNoContent)
}
