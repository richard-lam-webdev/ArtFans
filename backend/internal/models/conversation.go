package models

import (
	"time"

	"github.com/google/uuid"
)

type ConversationPreview struct {
	OtherUserID       uuid.UUID `json:"otherUserId"`
	OtherUserName     string    `json:"otherUserName"`
	LastMessage       string    `json:"lastMessage"`
	LastMessageTime   time.Time `json:"lastMessageTime"`
	LastMessageSender uuid.UUID `json:"lastMessageSender"`
}
