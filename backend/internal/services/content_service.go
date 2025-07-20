package services

import (
	"bytes"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"image/png"
	"io"
	"log"
	"mime/multipart"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/image/font"
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type ContentService struct {
	repo       *repositories.ContentRepository
	uploadPath string
}

func NewContentService(repo *repositories.ContentRepository, uploadPath string) *ContentService {
	return &ContentService{repo: repo, uploadPath: uploadPath}
}

func (s *ContentService) CreateContent(
	creatorID uuid.UUID,
	username, title, body string,
	price int,
	fileHeader *multipart.FileHeader,
	role string,
) (*models.Content, error) {

	if role != "creator" && role != "admin" {
		return nil, fmt.Errorf("seuls les créateurs peuvent ajouter du contenu")
	}
	if title == "" || body == "" || price <= 0 || fileHeader == nil {
		return nil, fmt.Errorf("champs requis manquants ou invalides")
	}

	userDir := filepath.Join(s.uploadPath, username)
	if err := os.MkdirAll(userDir, 0o755); err != nil {
		return nil, fmt.Errorf("mkdir: %w", err)
	}

	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true}
	if !allowed[ext] {
		return nil, fmt.Errorf("format de fichier non autorisé")
	}

	filename := uuid.NewString() + ext
	dstPath := filepath.Join(userDir, filename)

	src, err := fileHeader.Open()
	if err != nil {
		return nil, err
	}
	defer src.Close()

	dst, err := os.Create(dstPath)
	if err != nil {
		return nil, err
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		return nil, err
	}

	relativePath := filepath.Join(username, filename)
	content := &models.Content{
		CreatorID: creatorID,
		Title:     title,
		Body:      body,
		Price:     price,
		FilePath:  relativePath,
		Status:    "pending",
	}

	if err := s.repo.Create(content); err != nil {
		return nil, err
	}

	return content, nil
}

func (s *ContentService) GetAllContents() ([]models.Content, error) {
	return s.repo.FindAll()
}

func (s *ContentService) ServeProtectedImage(
	c *gin.Context,
	contentID uuid.UUID,
	userID uuid.UUID,
) error {
	log.Printf("🖼️ ServeProtectedImage - contentID: %s | userID: %s", contentID.String(), userID.String())

	content, err := s.repo.FindByID(contentID)
	if err != nil {
		log.Printf("❌ Contenu non trouvé: %v", err)
		return fmt.Errorf("contenu non trouvé")
	}
	log.Printf("📄 Contenu trouvé: %s (creatorID: %s)", content.Title, content.CreatorID.String())

	subscribed, err := s.repo.IsUserSubscribedToCreator(userID, content.CreatorID)
	if err != nil {
		log.Printf("❌ Erreur vérif abonnement: %v", err)
		return fmt.Errorf("erreur vérif abonnement: %v", err)
	}
	log.Printf("🔐 Abonné ? %v", subscribed)

	imagePath := filepath.Join(s.uploadPath, content.FilePath)
	file, err := os.Open(imagePath)
	if err != nil {
		log.Printf("❌ Image introuvable: %v", err)
		return fmt.Errorf("image non trouvée")
	}
	defer file.Close()

	ext := strings.ToLower(path.Ext(imagePath))
	var img image.Image
	switch ext {
	case ".jpg", ".jpeg":
		img, err = jpeg.Decode(file)
	case ".png":
		img, err = png.Decode(file)
	default:
		log.Printf("❌ Format d'image non supporté: %s", ext)
		return fmt.Errorf("format d'image non supporté")
	}
	if err != nil {
		log.Printf("❌ Erreur décodage image: %v", err)
		return fmt.Errorf("erreur décodage image: %v", err)
	}

	var buf bytes.Buffer
	if subscribed {
		log.Println("✅ Image originale envoyée (pas de watermark)")
		if ext == ".png" {
			err = png.Encode(&buf, img)
			c.Header("Content-Type", "image/png")
		} else {
			err = jpeg.Encode(&buf, img, nil)
			c.Header("Content-Type", "image/jpeg")
		}
	} else {
		log.Println("🔒 Image avec watermark")
		watermarked := addWatermark(img, "Abonne-toi pour voir l'image !")
		if ext == ".png" {
			err = png.Encode(&buf, watermarked)
			c.Header("Content-Type", "image/png")
		} else {
			err = jpeg.Encode(&buf, watermarked, nil)
			c.Header("Content-Type", "image/jpeg")
		}
	}
	if err != nil {
		log.Printf("❌ Erreur encoding image: %v", err)
		return fmt.Errorf("erreur encoding image: %v", err)
	}

	c.Header("Content-Disposition", "inline; filename="+filepath.Base(imagePath))
	c.Data(200, c.GetHeader("Content-Type"), buf.Bytes())
	return nil
}

// Watermark visible (répété sur toute la largeur)
func addWatermark(img image.Image, watermark string) image.Image {
	bounds := img.Bounds()
	rgba := image.NewRGBA(bounds)
	draw.Draw(rgba, bounds, img, image.Point{}, draw.Src)

	col := color.RGBA{255, 0, 0, 255}

	d := &font.Drawer{
		Dst:  rgba,
		Src:  image.NewUniform(col),
		Face: basicfont.Face7x13,
	}
	textWidth := d.MeasureString(watermark).Round()
	spacingX := 20
	spacingY := 40

	for y := spacingY; y < bounds.Dy(); y += spacingY {
		for x := 0; x < bounds.Dx(); x += textWidth + spacingX {
			d.Dot = fixed.P(x, y)
			d.DrawString(watermark)
		}
	}
	return rgba
}

func (s *ContentService) GetContentByID(id uuid.UUID) (*models.Content, error) {
	return s.repo.FindByID(id)
}

func (s *ContentService) UpdateContent(content *models.Content) error {
	return s.repo.Update(content)
}

func (s *ContentService) DeleteContent(id uuid.UUID) error {
	return s.repo.Delete(id, s.uploadPath)
}

func (s *ContentService) GetContentsByUserID(userID uuid.UUID) ([]*models.Content, error) {
	log.Printf("📦 Fetching contents for userID: %s\n", userID.String())

	return s.repo.GetContentsByUser(userID)

}

func (s *ContentService) GetFeedContents(userID uuid.UUID) ([]map[string]interface{}, error) {
	contents, err := s.repo.FindAllWithCreators()
	if err != nil {
		return nil, err
	}

	var feed []map[string]interface{}
	for _, c := range contents {
		isSub, _ := s.repo.IsUserSubscribedToCreator(userID, c.CreatorID)
		count, _ := s.repo.CountContentLikes(c.ID)
		liked, _ := s.repo.IsContentLikedBy(userID, c.ID)

		feed = append(feed, map[string]interface{}{
			"id":            c.ID,
			"title":         c.Title,
			"body":          c.Body,
			"price":         c.Price,
			"file_path":     c.FilePath,
			"creator_id":    c.CreatorID,
			"creator_name":  c.Creator.Username,
			"created_at":    c.CreatedAt,
			"is_subscribed": isSub,
			"likes_count":   count,
			"liked_by_user": liked,
		})
	}
	return feed, nil
}

// LikeContent enregistre un like pour un user sur un content
func (s *ContentService) LikeContent(userID, contentID uuid.UUID) error {
	return s.repo.CreateLike(userID, contentID)
}

// UnlikeContent supprime un like existant
func (s *ContentService) UnlikeContent(userID, contentID uuid.UUID) error {
	return s.repo.DeleteLike(userID, contentID)
}

func (s *ContentService) CanDownload(userID, CreatorID uuid.UUID) bool {
	isSub, _ := s.repo.IsUserSubscribedToCreator(userID, CreatorID)
	println("CanDownload - isSub:", isSub)
	return isSub
}

func (s *ContentService) GetFilePath(contentID uuid.UUID) (string, string, error) {
	content, err := s.repo.FindByID(contentID)
	if err != nil {
		return "", "", fmt.Errorf("contenu introuvable: %v", err)
	}

	if content.FilePath == "" {
		return "", "", fmt.Errorf("aucun fichier associé à ce contenu")
	}

	fullPath := filepath.Join(s.uploadPath, content.FilePath)

	log.Printf("🔍 Debug GetFilePath:")
	log.Printf("  - contentID: %s", contentID)
	log.Printf("  - content.FilePath: %s", content.FilePath)
	log.Printf("  - uploadPath: %s", s.uploadPath)
	log.Printf("  - fullPath calculé: %s", fullPath)

	if _, err := os.Stat(fullPath); err != nil {
		log.Printf("❌ Fichier non trouvé: %s", fullPath)
		log.Printf("   Erreur: %v", err)

		parentDir := filepath.Dir(fullPath)
		if files, listErr := os.ReadDir(parentDir); listErr == nil {
			log.Printf("   Contenu du répertoire %s:", parentDir)
			for _, file := range files {
				log.Printf("     - %s", file.Name())
			}
		}

		return "", "", fmt.Errorf("fichier non trouvé sur le disque: %s (erreur: %v)", fullPath, err)
	}

	// Extraire le nom de fichier original (juste le nom, sans le chemin)
	originalFilename := filepath.Base(content.FilePath)

	log.Printf("✅ Fichier trouvé: %s", fullPath)
	log.Printf("   Nom original: %s", originalFilename)

	return fullPath, originalFilename, nil
}
