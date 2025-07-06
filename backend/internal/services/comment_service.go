package services

import (
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

// CommentWithMeta est le DTO renvoyé à l'API,
// incluant le nombre de likes, si l'utilisateur a liké,
// et le ParentID pour gérer les fils de réponses.
type CommentWithMeta struct {
	models.Comment
	LikeCount int64 `json:"like_count"`
	LikedByMe bool  `json:"liked_by_me"`
}

// CommentService gère les commentaires et leurs likes
type CommentService struct {
	repo     *repositories.CommentRepository
	likeRepo *repositories.CommentLikeRepository
}

// NewCommentService injecte les repositories nécessaires
func NewCommentService(
	repo *repositories.CommentRepository,
	likeRepo *repositories.CommentLikeRepository,
) *CommentService {
	return &CommentService{repo: repo, likeRepo: likeRepo}
}

// FetchComments récupère tous les commentaires associés à un contenu,
// avec métadonnées (likes + likedByMe).
// userID est l'utilisateur courant (extrait du JWT) pour le flag LikedByMe.
func (s *CommentService) FetchComments(
	contentID uuid.UUID,
	userID uuid.UUID,
) ([]CommentWithMeta, error) {
	raw, err := s.repo.FindAllByContent(contentID)
	if err != nil {
		return nil, err
	}

	out := make([]CommentWithMeta, 0, len(raw))
	for _, c := range raw {
		// Comptage des likes
		cnt, err := s.likeRepo.CountByComment(c.ID)
		if err != nil {
			return nil, err
		}
		// Vérification si liked par l'utilisateur
		liked, err := s.likeRepo.IsLiked(userID, c.ID)
		if err != nil {
			return nil, err
		}
		out = append(out, CommentWithMeta{
			Comment:   c,
			LikeCount: cnt,
			LikedByMe: liked,
		})
	}
	return out, nil
}

// PostComment crée un commentaire (optionnellement en réponse à un parent)
func (s *CommentService) PostComment(
	contentID uuid.UUID,
	authorID uuid.UUID,
	text string,
	parentID *uuid.UUID,
) (*models.Comment, error) {
	comment := &models.Comment{
		ContentID: contentID,
		AuthorID:  authorID,
		Text:      text,
		ParentID:  parentID, // nil si commentaire racine
	}
	if err := s.repo.Create(comment); err != nil {
		return nil, err
	}
	return comment, nil
}

// LikeComment ajoute un like sur le commentaire pour l'utilisateur
func (s *CommentService) LikeComment(
	userID uuid.UUID,
	commentID uuid.UUID,
) error {
	return s.likeRepo.Like(userID, commentID)
}

// UnlikeComment supprime le like de l'utilisateur
func (s *CommentService) UnlikeComment(
	userID uuid.UUID,
	commentID uuid.UUID,
) error {
	return s.likeRepo.Unlike(userID, commentID)
}
