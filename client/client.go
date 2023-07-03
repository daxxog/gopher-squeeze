package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

const (
	chunkSize = 100 // Predefined increment for reading from STDIN
)

func main() {
	// Read the secret from the environment variable
	secret := os.Getenv("WEBHOOK_ENDPOINT")

	// Read input from STDIN in chunks
	input := make([]byte, chunkSize)
	for {
		n, err := os.Stdin.Read(input)
		if err != nil {
			break
		}

		// Compress the chunk with gzip
		var compressed bytes.Buffer
		gzipWriter := gzip.NewWriter(&compressed)
		_, _ = gzipWriter.Write(input[:n])
		_ = gzipWriter.Close()

		// Send the compressed data to the HTTP endpoint
		url := secret
		resp, err := http.Post(url, "application/octet-stream", &compressed)
		if err != nil {
			fmt.Println("Error sending data:", err)
			os.Exit(1)
		}
		defer resp.Body.Close()

		// Read the response from the server (optional)
		body, _ := ioutil.ReadAll(resp.Body)
		fmt.Println("Server response:", string(body))
	}
}
