package main

import (
	"fmt"
	"log"
	"os"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func main() {
	if os.Getenv("DATABASE_URL") == "" {
		log.Fatal("$DATABASE_URL must be set")
	}

	m, err := migrate.New("file://migrations", os.Getenv("DATABASE_URL"))

	if err != nil {
		fmt.Printf("migrate.New failed with: " + err.Error())
		log.Fatal(err)
	}

	err = m.Up()

	if err != nil && err != migrate.ErrNoChange {
		fmt.Printf("migrate.Up failed with:\n")
		log.Fatal(err)
	}

	version, _, _ := m.Version()
	fmt.Printf("Migrations complete at version: %d\n", version)
}
