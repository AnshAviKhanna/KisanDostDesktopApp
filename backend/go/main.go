package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os/exec"
	"path/filepath"
	"time"
    "os"
)

// Request body from Flutter
type ProcessRequest struct {
	ImagePaths []string `json:"image_paths"`
}

// Response body to Flutter
type ProcessResponse struct {
	DatabasePath string `json:"database_path"`
	SessionID    string `json:"session_id"`
}

func processingHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ProcessRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	log.Printf("[Go] Received request to process %d images", len(req.ImagePaths))

	// Create a new, unique database file for this session
    // This should be in a user-writable directory. Flutter will provide this.
    // For now, we assume a documents directory. A real app would get this from Flutter.
    docsDir, err := os.UserHomeDir()
    if err != nil {
        docsDir = "." // fallback to current dir
    }
    docsDir = filepath.Join(docsDir, "Documents")


	timestamp := time.Now().Format("2006-01-02_15-04-05")
	sessionID := fmt.Sprintf("session_%s", timestamp)
	newDbPath := filepath.Join(docsDir, sessionID+".db")

	log.Printf("[Go] Created new session DB at: %s", newDbPath)

	// Get path to the python executable
    exePath, err := os.Executable()
    if err != nil {
        http.Error(w, "Could not find executable path", 500)
        return
    }
    exeDir := filepath.Dir(exePath)
    // The Python executable should be in the same folder as the Go one.
    pythonEnginePath := filepath.Join(exeDir, "process_engine")


	// Run processing for each image in the background
	for _, imgPath := range req.ImagePaths {
		go func(path string) {
			log.Printf("[Go] Spawning Python process for: %s", path)
			cmd := exec.Command(pythonEnginePath, path, newDbPath)
			output, err := cmd.CombinedOutput()
			if err != nil {
				log.Printf("[Go] Error running Python script for %s: %s\nOutput: %s", path, err, string(output))
				return
			}
			log.Printf("[Go] Python script finished for %s", path)
		}(imgPath)
	}

	// Respond to Flutter immediately
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusAccepted)
	json.NewEncoder(w).Encode(ProcessResponse{
		DatabasePath: newDbPath,
		SessionID:    sessionID,
	})
}

func main() {
	http.HandleFunc("/start-processing", processingHandler)
	port := "8081"
	log.Printf("[Go] Starting local API server on http://localhost:%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}