package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL string
	JwtSecret   string
	StripeKey   string
	Port        string
}

var C Config

func LoadEnv() {
	if err := godotenv.Load("backend/.env"); err != nil {
		log.Println("Pas de fichier backend/.env trouvé")
	}
	C.DatabaseURL = os.Getenv("DATABASE_URL")
	C.JwtSecret = os.Getenv("JWT_SECRET")
	C.StripeKey = os.Getenv("STRIPE_KEY")
	if os.Getenv("PORT") == "" {
		C.Port = "8080"
	} else {
		C.Port = os.Getenv("PORT")
	}
	if C.DatabaseURL == "" {
		log.Fatal("DATABASE_URL manquant")
	}
}
