package repositories

import (
	"errors"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

type MessageRepository struct {
	db *gorm.DB
}

func NewMessageRepository() *MessageRepository {
	return &MessageRepository{db: database.DB}
}

// Create crée un nouveau message
func (r *MessageRepository) Create(message *models.Message) error {
	return r.db.Create(message).Error
}

// GetConversationBetween récupère tous les messages entre deux utilisateurs
func (r *MessageRepository) GetConversationBetween(userID1, userID2 uuid.UUID) ([]models.Message, error) {
	var messages []models.Message
	err := r.db.Where(
		"(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
		userID1, userID2, userID2, userID1,
	).Order("sent_at ASC").Find(&messages).Error

	if err != nil {
		return nil, err
	}
	return messages, nil
}

// GetUserConversations récupère la dernière message de chaque conversation pour un utilisateur
func (r *MessageRepository) GetUserConversations(userID uuid.UUID) ([]models.Message, error) {
	var messages []models.Message

	// Sous-requête pour obtenir le dernier message de chaque conversation
	subQuery := r.db.Model(&models.Message{}).
		Select("GREATEST(sender_id, receiver_id) as user1, LEAST(sender_id, receiver_id) as user2, MAX(sent_at) as max_sent_at").
		Where("sender_id = ? OR receiver_id = ?", userID, userID).
		Group("GREATEST(sender_id, receiver_id), LEAST(sender_id, receiver_id)")

	// Requête principale pour récupérer les messages complets
	err := r.db.Joins(
		"JOIN (?) as last_messages ON ((messages.sender_id = last_messages.user1 AND messages.receiver_id = last_messages.user2) OR (messages.sender_id = last_messages.user2 AND messages.receiver_id = last_messages.user1)) AND messages.sent_at = last_messages.max_sent_at",
		subQuery,
	).Where("messages.sender_id = ? OR messages.receiver_id = ?", userID, userID).
		Order("messages.sent_at DESC").
		Find(&messages).Error

	if err != nil {
		return nil, err
	}
	return messages, nil
}

// GetMessageByID récupère un message par son ID
func (r *MessageRepository) GetMessageByID(id uuid.UUID) (*models.Message, error) {
	var message models.Message
	err := r.db.First(&message, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &message, nil
}

// MarkAsRead marque un message comme lu (si tu veux ajouter cette fonctionnalité plus tard)
func (r *MessageRepository) MarkAsRead(messageID uuid.UUID) error {
	// Pour l'instant, on ne fait rien car le modèle n'a pas de champ "read"
	// Tu pourras ajouter un champ ReadAt *time.Time dans le modèle si besoin
	return nil
}

// GetUnreadCount compte les messages non lus pour un utilisateur (pour plus tard)
func (r *MessageRepository) GetUnreadCount(userID uuid.UUID) (int64, error) {
	var count int64
	// Pour l'instant retourne 0, tu pourras implémenter quand tu auras un champ "read"
	return count, nil
}
