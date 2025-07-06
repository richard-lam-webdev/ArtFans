// backend/internal/handlers/search_handler.go
package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// DTOs pour JSON
// ------------

type CreatorDTO struct {
	ID         int64  `json:"id"`
	Username   string `json:"username"`
	AvatarURL  string `json:"avatar_url"`
	IsFollowed bool   `json:"is_followed"`
}

type ContentDTO struct {
	ID           int64  `json:"id"`
	Title        string `json:"title"`
	ThumbnailURL string `json:"thumbnail_url"`
	CreatorName  string `json:"creator_name"`
}

type Subscription struct {
	FollowerID int64 `gorm:"column:follower_id"`
	CreatorID  int64 `gorm:"column:creator_id"`
}

// SearchHandler contient la BDD
// ------------------------------
type SearchHandler struct {
	DB *gorm.DB
}

// NewSearchHandler instancie le handler
func NewSearchHandler(db *gorm.DB) *SearchHandler {
	return &SearchHandler{DB: db}
}

// Search gère GET /api/search?q=…&type=creators,contents
func (h *SearchHandler) Search(c *gin.Context) {
	q := strings.TrimSpace(c.Query("q"))
	if q == "" || len(q) > 256 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Paramètre 'q' manquant ou trop long (max 256 caractères)"})
		return
	}
	types := strings.Split(c.Query("type"), ",")

	// Récupère l'ID utilisateur depuis le contexte JWT
	uidVal, _ := c.Get("userID")
	uid := uidVal.(int64)

	// Initialise à vide (évite null dans JSON)
	creators := make([]CreatorDTO, 0)
	contents := make([]ContentDTO, 0)

	// Requête créateurs avec suivi
	if contains(types, "creators") {
		h.DB.Table("users u").
			Select(`
        u.id,
        u.username,
        u.avatar_url,
        CASE WHEN s.creator_id IS NOT NULL THEN true ELSE false END AS is_followed
      `).
			Joins(`
        LEFT JOIN subscriptions s
          ON s.creator_id = u.id
         AND s.follower_id = ?
      `, uid).
			Where("u.username ILIKE ? OR u.bio ILIKE ?", "%"+q+"%", "%"+q+"%").
			Order("u.followers DESC").
			Limit(20).
			Find(&creators)
	}

	// Requête contenus
	if contains(types, "contents") {
		h.DB.Table("posts p").
			Select("p.id, p.title, p.thumbnail_url, u.username AS creator_name").
			Joins("JOIN users u ON u.id = p.user_id").
			Where("p.title ILIKE ? OR p.caption ILIKE ?", "%"+q+"%", "%"+q+"%").
			Order("p.likes DESC").
			Limit(20).
			Find(&contents)
	}

	c.JSON(http.StatusOK, gin.H{
		"creators": creators,
		"contents": contents,
	})
}

// Follow gère POST /api/subscriptions/:creatorID
func (h *SearchHandler) Follow(c *gin.Context) {
	uidVal, _ := c.Get("userID")
	uid := uidVal.(int64)
	cidParam := c.Param("creatorID")
	cid, err := strconv.ParseInt(cidParam, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "creatorID invalide"})
		return
	}
	sub := Subscription{FollowerID: uid, CreatorID: cid}
	if err := h.DB.Create(&sub).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// Unfollow gère DELETE /api/subscriptions/:creatorID
func (h *SearchHandler) Unfollow(c *gin.Context) {
	uidVal, _ := c.Get("userID")
	uid := uidVal.(int64)
	cidParam := c.Param("creatorID")
	cid, err := strconv.ParseInt(cidParam, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "creatorID invalide"})
		return
	}
	if err := h.DB.Where("follower_id = ? AND creator_id = ?", uid, cid).
		Delete(&Subscription{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// contains vérifie si slice contient s
func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}
