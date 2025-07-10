package handlers

import (
	"fmt"
	"log"
	"net/http"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
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

	logger.LogContent("content_created", userID.String(), content.ID.String(), map[string]interface{}{
		"title":      content.Title,
		"body":       content.Body,
		"creator_id": content.CreatorID.String(),
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

	c.JSON(http.StatusOK, gin.H{
		"id":          content.ID,
		"title":       content.Title,
		"body":        content.Body,
		"price":       content.Price,
		"created_at":  content.CreatedAt,
		"author_id":   content.CreatorID,
		"author_name": content.Creator.Username, // ← le nom que tu afficheras
	})
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

// GET /api/contents/:id/image
func (h *ContentHandler) GetContentImage(c *gin.Context) {
	contentIDStr := c.Param("id")
	contentID, err := uuid.Parse(contentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de contenu invalide"})
		return
	}

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

	if err := h.service.ServeProtectedImage(c, contentID, userID); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
}

// GET /api/feed
func (h *ContentHandler) GetFeed(c *gin.Context) {
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

	feed, err := h.service.GetFeedContents(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"feed": feed})
}

// POST  /api/contents/:id/like
func (h *ContentHandler) LikeContent(c *gin.Context) {
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, _ := uuid.Parse(userRaw.(string))

	contentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}

	if err := h.service.LikeContent(userID, contentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de liker"})
		return
	}

	content, err := h.service.GetContentByID(contentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		return
	}
	logger.LogContent(
		"content_liked",
		userID.String(),
		contentID.String(),
		map[string]interface{}{
			"creator_id": content.CreatorID.String(),
		},
	)

	c.Status(http.StatusOK)

}

// DELETE /api/contents/:id/like
func (h *ContentHandler) UnlikeContent(c *gin.Context) {
	userRaw, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, _ := uuid.Parse(userRaw.(string))

	contentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}

	if err := h.service.UnlikeContent(userID, contentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de un-liker"})
		return
	}
	c.Status(http.StatusOK)
}

func (h *ContentHandler) DownloadContent(c *gin.Context) {
	// 1) Récupération de l'ID utilisateur depuis le contexte
	userIDRaw, exists := c.Get("userID")
	if !exists {
		log.Printf("❌ DownloadContent: Pas d'userID dans le contexte")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "non autorisé"})
		return
	}
	userID, err := uuid.Parse(userIDRaw.(string))
	if err != nil {
		log.Printf("❌ DownloadContent: userID invalide: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	// 2) Récupération de l'ID du contenu
	contentIDParam := c.Param("id")
	contentID, err := uuid.Parse(contentIDParam)
	if err != nil {
		log.Printf("❌ DownloadContent: contentID invalide: %s", contentIDParam)
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID contenu invalide"})
		return
	}

	log.Printf("🔄 DownloadContent: userID=%s, contentID=%s", userID, contentID)

	// 3) On cherche le contenu pour obtenir son CreatorID ET son titre
	content, err := h.service.GetContentByID(contentID)
	if err != nil {
		log.Printf("❌ DownloadContent: Contenu introuvable: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Contenu introuvable"})
		return
	}
	creatorID := content.CreatorID
	log.Printf("📝 DownloadContent: Contenu trouvé - titre='%s', creator=%s", content.Title, creatorID)

	// 4) Vérification de l'abonnement sur le creatorID
	canDownload := h.service.CanDownload(userID, creatorID)
	log.Printf("🔐 DownloadContent: CanDownload=%t", canDownload)
	if !canDownload {
		c.JSON(http.StatusForbidden, gin.H{"error": "Accès refusé"})
		return
	}

	// 5) On récupère le chemin du fichier depuis le service
	filePath, originalFilename, err := h.service.GetFilePath(contentID)
	if err != nil {
		log.Printf("❌ DownloadContent: Erreur GetFilePath: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Fichier introuvable"})
		return
	}

	// 6) Nettoyage du titre pour créer un nom de fichier valide
	cleanTitle := sanitizeFilename(content.Title)

	// 7) Obtenir l'extension du fichier original
	ext := filepath.Ext(originalFilename)

	// 8) Créer le nouveau nom de fichier avec le titre nettoyé
	downloadFilename := cleanTitle + ext

	log.Printf("📁 DownloadContent: Envoi du fichier")
	log.Printf("   - Chemin: %s", filePath)
	log.Printf("   - Nom original: %s", originalFilename)
	log.Printf("   - Nom téléchargement: %s", downloadFilename)

	// 9) Envoi du fichier en téléchargement avec le titre comme nom
	c.Header("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, downloadFilename))
	c.File(filePath)

	log.Printf("✅ DownloadContent: Fichier envoyé avec succès")
}

func sanitizeFilename(title string) string {
	// Remplacer les caractères interdits par des underscores
	re := regexp.MustCompile(`[<>:"/\\|?*]`)
	cleaned := re.ReplaceAllString(title, "_")

	// Remplacer les espaces multiples par un seul underscore
	spaceRe := regexp.MustCompile(`\s+`)
	cleaned = spaceRe.ReplaceAllString(cleaned, "_")

	// Supprimer les caractères de contrôle
	cleaned = strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return -1
		}
		return r
	}, cleaned)

	// Limiter la longueur (Windows a une limite de 255 caractères)
	if len(cleaned) > 200 {
		cleaned = cleaned[:200]
	}

	// Supprimer les underscores en début et fin
	cleaned = strings.Trim(cleaned, "_")

	// Si le nom est vide après nettoyage, utiliser un nom par défaut
	if cleaned == "" {
		cleaned = "contenu"
	}

	return cleaned
}
