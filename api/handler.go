package api

import (
	"sync"

	"github.com/gin-gonic/gin"
)

// Person struct
type Person struct {
	ID      string   `json:"id"`
	Name    string   `json:"name"`
	Age     int      `json:"age"`
	Hobbies []string `json:"hobbies"`
}

var (
	// This is your in memory db
	Persons = make(map[int]Person)
	mu      sync.Mutex
)

func SetupRouter() *gin.Engine {
	router := gin.Default()

	//Todo CRUD routes for managing persons

	return router
}

//TODO: Implement crud of person
