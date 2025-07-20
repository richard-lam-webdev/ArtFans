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

func (s *MessageService) SendMessage(
	senderID, receiverID uuid.UUID,
	text string,
) (*models.Message, error) {

	receiver, err := s.userRepo.FindByID(receiverID)
	if err != nil {
		return nil, err
	}
	if receiver == nil {
		return nil, errors.New("destinataire introuvable")
	}

	if senderID == receiverID {
		return nil, errors.New("impossible de s'envoyer un message à soi-même")
	}

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

func (s *MessageService) GetConversation(
	userID, otherUserID uuid.UUID,
) ([]models.Message, error) {
	return s.messageRepo.GetConversationBetween(userID, otherUserID)
}

func (s *MessageService) GetUserConversations(
	userID uuid.UUID,
) ([]models.ConversationPreview, error) {
	return s.messageRepo.GetConversationPreviews(userID)
}

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
