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
	content, err := s.repo.FindByID(contentID)
	if err != nil {
		return fmt.Errorf("contenu non trouvé")
	}

	subscribed, err := s.repo.IsUserSubscribedToCreator(userID, content.CreatorID)
	if err != nil {
		return fmt.Errorf("erreur vérif abonnement: %v", err)
	}

	imagePath := filepath.Join(s.uploadPath, content.FilePath)
	file, err := os.Open(imagePath)
	if err != nil {
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
		return fmt.Errorf("format d'image non supporté")
	}
	if err != nil {
		return fmt.Errorf("erreur décodage image: %v", err)
	}

	var buf bytes.Buffer
	if subscribed {
		if ext == ".png" {
			err = png.Encode(&buf, img)
			c.Header("Content-Type", "image/png")
		} else {
			err = jpeg.Encode(&buf, img, nil)
			c.Header("Content-Type", "image/jpeg")
		}
		if err != nil {
			return fmt.Errorf("erreur encoding image: %v", err)
		}
	} else {
		watermarked := addWatermark(img, "Abonne-toi pour voir l'image !")
		if ext == ".png" {
			err = png.Encode(&buf, watermarked)
			c.Header("Content-Type", "image/png")
		} else {
			err = jpeg.Encode(&buf, watermarked, nil)
			c.Header("Content-Type", "image/jpeg")
		}
		if err != nil {
			return fmt.Errorf("erreur encoding image: %v", err)
		}
	}

	c.Header("Content-Disposition", "inline; filename="+filepath.Base(imagePath))
	c.Data(200, c.GetHeader("Content-Type"), buf.Bytes())
	return nil
}

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
