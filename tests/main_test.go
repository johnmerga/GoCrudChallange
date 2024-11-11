package tests

import (
	"GoCrudChallange/api"
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

var server *httptest.Server

func setup() {
	server = httptest.NewServer(api.SetupRouter())
}

func teardown() {
	server.Close()
}

func TestPersonCRUD(t *testing.T) {
	setup()
	defer teardown()

	fmt.Println("This is the server ", server.URL)
	t.Run("Test Get", func(t *testing.T) {
		// get persons db
		expectedPersons := api.Persons
		res, err := http.Get(server.URL + "/person")
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var actualPersons map[int]api.Person
		err = json.NewDecoder(res.Body).Decode(&actualPersons)
		assert.NoError(t, err)

		assert.Equal(t, expectedPersons, actualPersons)
	})

	t.Run("Test Get By ID", func(t *testing.T) {
		res, err := http.Get(server.URL + "/person/1")
		assert.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, res.StatusCode)
	})

	t.Run("Test Post", func(t *testing.T) {
		newPerson := api.Person{
			Name:    "keber",
			Age:     24,
			Hobbies: []string{"dubstep"},
		}

		payload, _ := json.Marshal(newPerson)
		res, err := http.Post(server.URL+"/person", "application/json", bytes.NewBuffer(payload))
		persons := api.Persons
		fmt.Println("This is persons db ", persons)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res.StatusCode)
	})
	t.Run("Test Get By ID", func(t *testing.T) {
		res, err := http.Get(server.URL + "/person/1")
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)
	})
	t.Run("Test Post Validation All Empty", func(t *testing.T) {
		res, err := http.Post(server.URL+"/person", "application/json", bytes.NewBuffer([]byte(`{}`)))
		assert.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, res.StatusCode)
	})

	t.Run("Test Post Validation Name Empty", func(t *testing.T) {
		data := map[string]interface{}{"age": 26, "hobbies": []string{}}
		payload, _ := json.Marshal(data)
		res, err := http.Post(server.URL+"/person", "application/json", bytes.NewBuffer(payload))
		assert.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, res.StatusCode)
	})

	t.Run("Test Put", func(t *testing.T) {
		updatedPerson := api.Person{
			Name:    "Sam",
			Age:     26,
			Hobbies: []string{"dubstep", "jazz"},
		}

		payload, _ := json.Marshal(updatedPerson)
		req, _ := http.NewRequest(http.MethodPut, server.URL+"/person/1", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		client := &http.Client{}
		res, err := client.Do(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

	})

	t.Run("Test Delete", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodDelete, server.URL+"/person/1", nil)
		client := &http.Client{}
		res, err := client.Do(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

	})

	t.Run("Test Non-Existing User", func(t *testing.T) {
		res, err := http.Get(server.URL + "/person/9999")
		assert.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, res.StatusCode)
	})

	t.Run("Test Non-Existing Endpoint", func(t *testing.T) {
		res, err := http.Get(server.URL + "/test/non-existing/endpoint")
		assert.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, res.StatusCode)
	})
}
