package models

import (
	"time"

	"github.com/google/uuid"
)

// ConversationPreview représente un aperçu de conversation pour l'affichage de la liste
type ConversationPreview struct {
	OtherUserID       uuid.UUID `json:"otherUserId"`
	OtherUserName     string    `json:"otherUserName"`
	LastMessage       string    `json:"lastMessage"`
	LastMessageTime   time.Time `json:"lastMessageTime"`
	LastMessageSender uuid.UUID `json:"lastMessageSender"`
}
