package services

import (
	"errors"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type MessageService struct {
	messageRepo *repositories.MessageRepository
	userRepo    *repositories.UserRepository
}

func NewMessageService(messageRepo *repositories.MessageRepository, userRepo *repositories.UserRepository) *MessageService {
	return &MessageService{
		messageRepo: messageRepo,
		userRepo:    userRepo,
	}
}

// SendMessage envoie un message d'un utilisateur à un autre
func (s *MessageService) SendMessage(senderID, receiverID uuid.UUID, text string) (*models.Message, error) {
	// Vérifier que le destinataire existe
	receiver, err := s.userRepo.FindByID(receiverID)
	if err != nil {
		return nil, err
	}
	if receiver == nil {
		return nil, errors.New("destinataire introuvable")
	}

	// Vérifier que l'utilisateur n'essaie pas de s'envoyer un message à lui-même
	if senderID == receiverID {
		return nil, errors.New("impossible de s'envoyer un message à soi-même")
	}

	// Créer le message (l'ID sera généré par GORM grâce au default:uuid_generate_v4())
	message := &models.Message{
		SenderID:   senderID,
		ReceiverID: receiverID,
		Text:       text,
		// SentAt sera automatiquement rempli par GORM grâce à autoCreateTime
	}

	// Sauvegarder en base
	if err := s.messageRepo.Create(message); err != nil {
		return nil, err
	}

	return message, nil
}

// GetConversation récupère tous les messages entre deux utilisateurs
func (s *MessageService) GetConversation(userID, otherUserID uuid.UUID) ([]models.Message, error) {
	return s.messageRepo.GetConversationBetween(userID, otherUserID)
}

// GetUserConversations récupère toutes les conversations d'un utilisateur
func (s *MessageService) GetUserConversations(userID uuid.UUID) ([]models.ConversationPreview, error) {
	// Récupérer les derniers messages de chaque conversation
	messages, err := s.messageRepo.GetUserConversations(userID)
	if err != nil {
		return nil, err
	}

	// Construire la liste des previews
	previews := make([]models.ConversationPreview, 0, len(messages))

	for _, msg := range messages {
		// Déterminer qui est l'autre utilisateur
		var otherUserID uuid.UUID
		if msg.SenderID == userID {
			otherUserID = msg.ReceiverID
		} else {
			otherUserID = msg.SenderID
		}

		// Récupérer les infos de l'autre utilisateur
		otherUser, err := s.userRepo.FindByID(otherUserID)
		if err != nil || otherUser == nil {
			continue // Skip si on ne trouve pas l'utilisateur
		}

		preview := models.ConversationPreview{
			OtherUserID:       otherUserID,
			OtherUserName:     otherUser.Username,
			LastMessage:       msg.Text,
			LastMessageTime:   msg.SentAt,
			LastMessageSender: msg.SenderID,
		}

		previews = append(previews, preview)
	}

	return previews, nil
}

// CanAccessMessage vérifie si un utilisateur peut accéder à un message
func (s *MessageService) CanAccessMessage(userID, messageID uuid.UUID) (bool, error) {
	message, err := s.messageRepo.GetMessageByID(messageID)
	if err != nil {
		return false, err
	}
	if message == nil {
		return false, nil
	}

	// Un utilisateur peut accéder au message s'il est l'expéditeur ou le destinataire
	return message.SenderID == userID || message.ReceiverID == userID, nil
}
