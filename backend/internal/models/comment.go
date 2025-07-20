package models

import (
	"time"

	"github.com/google/uuid"
)

type Comment struct {
	ID        uuid.UUID  `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	ContentID uuid.UUID  `gorm:"column:content_id;not null;index"           json:"content_id"`
	AuthorID  uuid.UUID  `gorm:"column:author_id;not null;index"            json:"author_id"`
	Text      string     `gorm:"not null"                                   json:"text"`
	CreatedAt time.Time  `gorm:"column:created_at;autoCreateTime"           json:"created_at"`
	ParentID  *uuid.UUID `gorm:"column:parent_id;type:uuid;index"           json:"parent_id"`
	Author    User       `gorm:"foreignKey:AuthorID;references:ID"          json:"author"`
	Content   Content    `gorm:"foreignKey:ContentID;references:ID"         json:"content"`
}

type CommentLike struct {
	UserID    uuid.UUID `gorm:"column:user_id;type:uuid;not null;primaryKey"`
	CommentID uuid.UUID `gorm:"column:comment_id;type:uuid;not null;primaryKey"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}
