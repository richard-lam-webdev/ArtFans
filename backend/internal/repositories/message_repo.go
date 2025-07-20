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

/* -------------------------------------------------------------------------- */
/* CRUD basique                                                               */
/* -------------------------------------------------------------------------- */

func (r *MessageRepository) Create(message *models.Message) error {
	return r.db.Create(message).Error
}

func (r *MessageRepository) GetConversationBetween(userID1, userID2 uuid.UUID) ([]models.Message, error) {
	var messages []models.Message
	err := r.db.
		Where(`(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)`,
			userID1, userID2, userID2, userID1).
		Order("sent_at ASC").
		Find(&messages).
		Error
	return messages, err
}

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

func (r *MessageRepository) GetConversationPreviews(userID uuid.UUID) ([]models.ConversationPreview, error) {
	var previews []models.ConversationPreview
	uid := userID.String()

	sub := r.db.
		Table("message").
		Select(`
			(CASE
			   WHEN sender_id::text = ? THEN receiver_id::text
			   ELSE sender_id::text
			 END)                         AS partner_id,
			MAX(sent_at)                  AS last_sent_at
		`, uid).
		Where("sender_id::text = ? OR receiver_id::text = ?", uid, uid).
		Group("partner_id")

	err := r.db.
		Table("message AS m").
		Select(`
			l.partner_id                  AS other_user_id,
			u.username                    AS other_user_name,
			m.text                        AS last_message,
			m.sent_at                     AS last_message_time,
			m.sender_id::text             AS last_message_sender
		`).
		Joins(`
			JOIN (?) AS l ON
			     m.sent_at = l.last_sent_at
			  AND (
			       (m.sender_id::text   = ? AND m.receiver_id::text = l.partner_id)
			    OR (m.receiver_id::text = ? AND m.sender_id::text   = l.partner_id)
			  )
		`, sub, uid, uid).
		Joins(`JOIN "user" AS u ON u.id::text = l.partner_id`).
		Order("m.sent_at DESC").
		Scan(&previews).Error

	return previews, err
}

func (r *MessageRepository) MarkAsRead(messageID uuid.UUID) error {
	return nil
}

func (r *MessageRepository) GetUnreadCount(userID uuid.UUID) (int64, error) {
	var count int64
	return count, nil
}
