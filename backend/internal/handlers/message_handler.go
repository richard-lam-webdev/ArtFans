package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

type MessageHandler struct {
	messageService *services.MessageService
}

func NewMessageHandler(messageService *services.MessageService) *MessageHandler {
	return &MessageHandler{
		messageService: messageService,
	}
}

type SendMessagePayload struct {
	ReceiverID string `json:"receiverId" binding:"required"`
	Text       string `json:"text" binding:"required,min=1"`
}

// SendMessage gère POST /api/messages
func (h *MessageHandler) SendMessage(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	var payload SendMessagePayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	receiverID, err := uuid.Parse(payload.ReceiverID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID destinataire invalide"})
		return
	}

	message, err := h.messageService.SendMessage(userID, receiverID, payload.Text)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": message})
}

// GetConversation gère GET /api/messages/:userId
func (h *MessageHandler) GetConversation(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	otherUserIDStr := c.Param("userId")
	otherUserID, err := uuid.Parse(otherUserIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide dans l'URL"})
		return
	}

	messages, err := h.messageService.GetConversation(userID, otherUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération des messages"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"messages": messages})
}

// GetConversations gère GET /api/messages
func (h *MessageHandler) GetConversations(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	conversations, err := h.messageService.GetUserConversations(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération des conversations"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"conversations": conversations})
}
