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

func NewMessageService(
	messageRepo *repositories.MessageRepository,
	userRepo *repositories.UserRepository,
) *MessageService {
	return &MessageService{
		messageRepo: messageRepo,
		userRepo:    userRepo,
	}
}

/* -------------------------------------------------------------------------- */
/* Envoi d’un message                                                         */
/* -------------------------------------------------------------------------- */

func (s *MessageService) SendMessage(
	senderID, receiverID uuid.UUID,
	text string,
) (*models.Message, error) {

	// Vérifier que le destinataire existe
	receiver, err := s.userRepo.FindByID(receiverID)
	if err != nil {
		return nil, err
	}
	if receiver == nil {
		return nil, errors.New("destinataire introuvable")
	}

	// Interdire l’auto-envoi
	if senderID == receiverID {
		return nil, errors.New("impossible de s'envoyer un message à soi-même")
	}

	// Créer et sauvegarder
	msg := &models.Message{
		SenderID:   senderID,
		ReceiverID: receiverID,
		Text:       text,
	}
	if err := s.messageRepo.Create(msg); err != nil {
		return nil, err
	}
	return msg, nil
}

/* -------------------------------------------------------------------------- */
/* Conversation complète (historique)                                         */
/* -------------------------------------------------------------------------- */

func (s *MessageService) GetConversation(
	userID, otherUserID uuid.UUID,
) ([]models.Message, error) {
	return s.messageRepo.GetConversationBetween(userID, otherUserID)
}

/* -------------------------------------------------------------------------- */
/* Liste des conversations (aperçus)                                          */
/* -------------------------------------------------------------------------- */

func (s *MessageService) GetUserConversations(
	userID uuid.UUID,
) ([]models.ConversationPreview, error) {
	// Le repository renvoie déjà les aperçus complets
	return s.messageRepo.GetConversationPreviews(userID)
}

/* -------------------------------------------------------------------------- */
/* Autorisation d’accès à un message                                          */
/* -------------------------------------------------------------------------- */

func (s *MessageService) CanAccessMessage(
	userID, messageID uuid.UUID,
) (bool, error) {
	msg, err := s.messageRepo.GetMessageByID(messageID)
	if err != nil {
		return false, err
	}
	if msg == nil {
		return false, nil
	}
	return msg.SenderID == userID || msg.ReceiverID == userID, nil
}
