package main

import (
	"GoCrudChallange/api"
	"log"
	"net/http"
)

func main() {
	r := api.SetupRouter()

	log.Println("Server started at http://localhost:8080")
	http.ListenAndServe(":8080", r)
}
