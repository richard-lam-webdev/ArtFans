// backend/internal/handlers/admin_comment_handler.go
package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

// AdminCommentHandler gère la modération des commentaires
type AdminCommentHandler struct {
	commentSvc *services.CommentService
}

// NewAdminCommentHandler instancie le handler de modération
func NewAdminCommentHandler(commentSvc *services.CommentService) *AdminCommentHandler {
	return &AdminCommentHandler{commentSvc: commentSvc}
}

// ListComments renvoie la liste paginée de tous les commentaires
// avec : auteur, contenu, date et lien vers le post parent
func (h *AdminCommentHandler) ListComments(c *gin.Context) {
	// pagination
	page, _ := strconv.Atoi(c.Query("page"))
	if page < 1 {
		page = 1
	}
	pageSize, _ := strconv.Atoi(c.Query("page_size"))
	if pageSize < 1 {
		pageSize = 20
	}

	// fetch avec préchargement des relations Author & Content
	comments, err := h.commentSvc.ListAllComments(page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// formate la réponse en injectant author.username et content.title
	resp := make([]gin.H, len(comments))
	for i, cm := range comments {
		resp[i] = gin.H{
			"id":          cm.ID.String(),
			"content_id":  cm.ContentID.String(),
			"author_id":   cm.AuthorID.String(),
			"text":        cm.Text,
			"created_at":  cm.CreatedAt.Format(time.RFC3339),
			"parent_id":   cm.ParentID,
			"author_name": cm.Author.Username,
			"content": gin.H{ // <- on renvoie un sous-objet content
				"id":         cm.Content.ID.String(),
				"title":      cm.Content.Title,
				"created_at": cm.Content.CreatedAt.Format(time.RFC3339),
			},

			// URL vers l’API publique du post
			"post_url": "/api/contents/" + cm.ContentID.String(),
		}
	}

	c.JSON(http.StatusOK, gin.H{"comments": resp})
}

// DeleteComment supprime définitivement un commentaire par son ID
func (h *AdminCommentHandler) DeleteComment(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de commentaire invalide"})
		return
	}
	if err := h.commentSvc.DeleteCommentByID(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}
