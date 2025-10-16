// // package main

// // import (
// // 	"encoding/base64"
// // 	"encoding/json"
// // 	"fmt"
// // 	"log"
// // 	"net/http"
// // 	"os"
// // 	"os/exec"
// // 	"path/filepath"
// // )

// // type ProcessRequest struct {
// // 	ImagePath  string `json:"image_path"`
// // 	OutputPath string `json:"output_path"` 
// // }

// // type PythonResponse struct {
// // 	RipeCount   int    `json:"ripe_count"`
// // 	UnripeCount int    `json:"unripe_count"`
// // 	OutputImage string `json:"output_image"` 
// // 	Error       string `json:"error"`
// // }

// // type FlutterResponse struct {
// // 	ProcessedImagePath string `json:"processed_image_path"`
// // 	RipeCount          int    `json:"ripe_count"`
// // 	UnripeCount        int    `json:"unripe_count"`
// // }

// // func processImageHandler(w http.ResponseWriter, r *http.Request) {
// // 	if r.Method != "POST" {
// // 		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
// // 		return
// // 	}

// // 	var req ProcessRequest
// // 	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
// // 		http.Error(w, err.Error(), http.StatusBadRequest)
// // 		return
// // 	}

// // 	if req.ImagePath == "" || req.OutputPath == "" {
// // 		http.Error(w, "image_path and output_path cannot be empty", http.StatusBadRequest)
// // 		return
// // 	}

// // 	log.Printf("[Go] Received request to process image: %s", req.ImagePath)
// // 	log.Printf("[Go] Will save processed image to: %s", req.OutputPath)

// // 	exePath, err := os.Executable()
// // 	if err != nil {
// // 		http.Error(w, "Could not find executable path", 500)
// // 		return
// // 	}
// // 	exeDir := filepath.Dir(exePath)
// // 	detectionEnginePath := filepath.Join(exeDir, "dist/detect_ripeness")

// // 	cmd := exec.Command(detectionEnginePath, "--image_path", req.ImagePath)
// // 	output, err := cmd.CombinedOutput()
// // 	if err != nil {
// // 		log.Printf("Detection script execution failed. Output: %s", string(output))
// // 		http.Error(w, fmt.Sprintf("Error executing detection script: %s", string(output)), http.StatusInternalServerError)
// // 		return
// // 	}

// // 	var pyResponse PythonResponse
// // 	if err := json.Unmarshal(output, &pyResponse); err != nil {
// // 		http.Error(w, "Could not parse response from detection script", http.StatusInternalServerError)
// // 		return
// // 	}
// // 	if pyResponse.Error != "" {
// // 		http.Error(w, fmt.Sprintf("Detection script error: %s", pyResponse.Error), http.StatusInternalServerError)
// // 		return
// // 	}

// // 	decodedImage, err := base64.StdEncoding.DecodeString(pyResponse.OutputImage)
// // 	if err != nil {
// // 		http.Error(w, "Failed to decode base64 image from script", http.StatusInternalServerError)
// // 		return
// // 	}

// // 	processedImagePath := req.OutputPath

// // 	if err := os.WriteFile(processedImagePath, decodedImage, 0644); err != nil {
// // 		http.Error(w, "Failed to save processed image", http.StatusInternalServerError)
// // 		return
// // 	}

// // 	log.Printf("[Go] Successfully saved processed image to: %s", processedImagePath)

// // 	response := FlutterResponse{
// // 		ProcessedImagePath: processedImagePath,
// // 		RipeCount:          pyResponse.RipeCount,
// // 		UnripeCount:        pyResponse.UnripeCount,
// // 	}

// // 	w.Header().Set("Content-Type", "application/json")
// // 	w.WriteHeader(http.StatusOK)
// // 	json.NewEncoder(w).Encode(response)
// // }

// // func main() {
// // 	http.HandleFunc("/process-image", processImageHandler)
// // 	port := "8081"
// // 	log.Printf("[Go] Starting local API server on http://localhost:%s", port)
// // 	if err := http.ListenAndServe(":"+port, nil); err != nil {
// // 		log.Fatal(err)
// // 	}
// // }
// // main.go (Corrected to call python3 directly)
// package main

// import (
// 	"encoding/base64"
// 	"encoding/json"
// 	"fmt"
// 	"log"
// 	"net/http"
// 	"os"
// 	"os/exec"
// 	"path/filepath"
// )

// // ProcessRequest defines the structure of the incoming request from Flutter.
// type ProcessRequest struct {
// 	ImagePath  string `json:"image_path"`
// 	OutputPath string `json:"output_path"`
// }

// // PythonResponse defines the structure of the JSON output from the Python script.
// type PythonResponse struct {
// 	RipeCount            int    `json:"ripe_count"`
// 	UnripeCount          int    `json:"unripe_count"`
// 	ProcessedImageBase64 string `json:"processed_image_base64"`
// 	Error                string `json:"error"`
// }

// // FlutterResponse defines the structure of the JSON response sent back to Flutter.
// type FlutterResponse struct {
// 	ProcessedImagePath string `json:"processed_image_path"`
// 	RipeCount          int    `json:"ripe_count"`
// 	UnripeCount        int    `json:"unripe_count"`
// }

// func processImageHandler(w http.ResponseWriter, r *http.Request) {
// 	if r.Method != "POST" {
// 		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
// 		return
// 	}

// 	var req ProcessRequest
// 	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
// 		http.Error(w, err.Error(), http.StatusBadRequest)
// 		return
// 	}

// 	if req.ImagePath == "" || req.OutputPath == "" {
// 		http.Error(w, "image_path and output_path cannot be empty", http.StatusBadRequest)
// 		return
// 	}

// 	// log.Printf("[Go] Received request to process image: %s", req.ImagePath)

// 	// Determine the directory of the running Go executable.
// 	exePath, err := os.Executable()
// 	if err != nil {
// 		http.Error(w, "Could not find Go executable path", 500)
// 		return
// 	}
// 	exeDir := filepath.Dir(exePath)
// 	// Assume main.py is in the same directory as the Go executable.
// 	scriptPath := filepath.Join(exeDir, "main.py")

// 	// --- CRITICAL CHANGE ---
// 	// Execute 'python3 main.py <image_path>' instead of a bundled app.
// 	cmd := exec.Command("python3", scriptPath, req.ImagePath)
// 	output, err := cmd.CombinedOutput() // Captures both stdout and stderr
// 	if err != nil {
// 		log.Printf("Python script execution failed. Output: %s", string(output))
// 		http.Error(w, fmt.Sprintf("Error executing python script: %s", string(output)), http.StatusInternalServerError)
// 		return
// 	}

// 	var pyResponse PythonResponse
// 	if err := json.Unmarshal(output, &pyResponse); err != nil {
// 		log.Printf("Could not parse JSON from script. Raw output: %s", string(output))
// 		http.Error(w, "Could not parse response from python script", http.StatusInternalServerError)
// 		return
// 	}

// 	if pyResponse.Error != "" {
// 		http.Error(w, fmt.Sprintf("Python script error: %s", pyResponse.Error), http.StatusInternalServerError)
// 		return
// 	}

// 	decodedImage, err := base64.StdEncoding.DecodeString(pyResponse.ProcessedImageBase64)
// 	if err != nil {
// 		http.Error(w, "Failed to decode base64 image from script", http.StatusInternalServerError)
// 		return
// 	}

// 	if err := os.WriteFile(req.OutputPath, decodedImage, 0644); err != nil {
// 		http.Error(w, "Failed to save processed image", http.StatusInternalServerError)
// 		return
// 	}

// 	log.Printf("[Go] Successfully saved processed image to: %s", req.OutputPath)

// 	response := FlutterResponse{
// 		ProcessedImagePath: req.OutputPath,
// 		RipeCount:          pyResponse.RipeCount,
// 		UnripeCount:        pyResponse.UnripeCount,
// 	}

// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusOK)
// 	json.NewEncoder(w).Encode(response)
// }

// func main() {
// 	http.HandleFunc("/process-image", processImageHandler)
// 	port := "8081"
// 	// log.Printf("[Go] Starting local API server on http://localhost:%s", port)
// 	if err := http.ListenAndServe(":"+port, nil); err != nil {
// 		log.Fatal(err)
// 	}
// }

// main.go (Final Corrected Version)
package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
)

// ... (struct definitions are the same) ...
type ProcessRequest struct {
	ImagePath  string `json:"image_path"`
	OutputPath string `json:"output_path"`
}
type PythonResponse struct {
	RipeCount            int    `json:"ripe_count"`
	UnripeCount          int    `json:"unripe_count"`
	ProcessedImageBase64 string `json:"processed_image_base64"`
	Error                string `json:"error"`
}
type FlutterResponse struct {
	ProcessedImagePath string `json:"processed_image_path"`
	RipeCount          int    `json:"ripe_count"`
	UnripeCount        int    `json:"unripe_count"`
}


func processImageHandler(w http.ResponseWriter, r *http.Request) {
	// ... (request decoding is the same) ...
    if r.Method != "POST" {
        http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
        return
    }
    var req ProcessRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    if req.ImagePath == "" || req.OutputPath == "" {
        http.Error(w, "image_path and output_path cannot be empty", http.StatusBadRequest)
        return
    }

	log.Printf("[Go] Received request to process image: %s", req.ImagePath)

	exePath, err := os.Executable()
	if err != nil {
		http.Error(w, "Could not find Go executable path", 500)
		return
	}
	exeDir := filepath.Dir(exePath)
	scriptPath := filepath.Join(exeDir, "main.py")

	cmd := exec.Command("python3", scriptPath, req.ImagePath)
	
    // --- CRITICAL FIX ---
	// Use .Output() to capture ONLY stdout (the clean JSON).
	// Stderr (the Python logs) will still appear in your terminal for debugging,
	// but it won't be mixed with the JSON data.
	output, err := cmd.Output() 

	if err != nil {
		// If there's an error, cast it to ExitError to get the stderr content
		if exitError, ok := err.(*exec.ExitError); ok {
			log.Printf("Python script execution failed. Stderr: %s", string(exitError.Stderr))
			http.Error(w, fmt.Sprintf("Error executing python script: %s", string(exitError.Stderr)), http.StatusInternalServerError)
		} else {
			log.Printf("Python script execution failed: %v", err)
			http.Error(w, "Error executing python script", http.StatusInternalServerError)
		}
		return
	}
    
    // ... (the rest of the function is the same) ...
	var pyResponse PythonResponse
	if err := json.Unmarshal(output, &pyResponse); err != nil {
		log.Printf("Could not parse JSON from script. Raw output from stdout: %s", string(output))
		http.Error(w, "Could not parse response from python script", http.StatusInternalServerError)
		return
	}

	if pyResponse.Error != "" {
		http.Error(w, fmt.Sprintf("Python script error: %s", pyResponse.Error), http.StatusInternalServerError)
		return
	}

	decodedImage, err := base64.StdEncoding.DecodeString(pyResponse.ProcessedImageBase64)
	if err != nil {
		http.Error(w, "Failed to decode base64 image from script", http.StatusInternalServerError)
		return
	}

	if err := os.WriteFile(req.OutputPath, decodedImage, 0644); err != nil {
		http.Error(w, "Failed to save processed image", http.StatusInternalServerError)
		return
	}

	log.Printf("[Go] Successfully saved processed image to: %s", req.OutputPath)

	response := FlutterResponse{
		ProcessedImagePath: req.OutputPath,
		RipeCount:          pyResponse.RipeCount,
		UnripeCount:        pyResponse.UnripeCount,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/process-image", processImageHandler)
	port := "8081"
	log.Printf("[Go] Starting local API server on http://localhost:%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}