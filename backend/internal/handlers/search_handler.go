package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CreatorDTO struct {
	ID         string `json:"id"`
	Username   string `json:"username"`
	AvatarURL  string `json:"avatar_url"`
	IsFollowed bool   `json:"is_followed"`
}

type ContentDTO struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	ThumbnailURL string `json:"thumbnail_url"`
	CreatorName  string `json:"creator_name"`
}

// SearchHandler gère GET /api/search?q=…&type=creators,contents
type SearchHandler struct {
	DB *gorm.DB
}

// NewSearchHandler instancie le handler
func NewSearchHandler(db *gorm.DB) *SearchHandler {
	return &SearchHandler{DB: db}
}

// Search exécute la recherche créateurs et contenus
func (h *SearchHandler) Search(c *gin.Context) {
	q := strings.TrimSpace(c.Query("q"))
	if q == "" || len(q) > 256 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Paramètre 'q' manquant ou trop long (max 256 caractères)"})
		return
	}
	types := strings.Split(c.Query("type"), ",")

	var uid string
	if v, exists := c.Get("userID"); exists {
		switch id := v.(type) {
		case string:
			uid = id
		case []byte:
			uid = string(id)
		}
	}

	creators := make([]CreatorDTO, 0)
	contents := make([]ContentDTO, 0)

	if contains(types, "creators") {
		h.DB.Table(`"user" u`).
			Select(`
		  u.id::text   AS id,
		  u.username,
		  ''            AS avatar_url,
		  CASE WHEN s.creator_id IS NOT NULL THEN true ELSE false END AS is_followed
		`).
			Joins(`
		  LEFT JOIN subscription s
		    ON s.creator_id::text   = u.id::text
		   AND s.subscriber_id::text = ?
		`, uid).
			Where("u.username ILIKE ?", "%"+q+"%").
			Order("u.created_at DESC").
			Limit(20).
			Find(&creators)
	}

	if contains(types, "contents") {
		h.DB.Table("content p").
			Select(`
      p.id::text            AS id,
      p.title,
      p.image_url           AS thumbnail_url,
      u.username            AS creator_name
    `).
			Joins(`
      JOIN "user" u
        ON u.id::text = p.creator_id::text
    `).
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

func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}
