package main

import (
	"bytes"
	"compress/gzip"
	"crypto/subtle"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
)

var webhookSecret []byte

func main() {
	webhookSecret = []byte(os.Getenv("WEBHOOK_SECRET"))
	webhookListen := os.Getenv("WEBHOOK_LISTEN")
	app := fiber.New()

	app.Post("/log/:secret", func(c *fiber.Ctx) error {
		secret := c.Params("secret")

		if subtle.ConstantTimeCompare([]byte(secret), webhookSecret) == 1 {
			// Read the compressed data from the request body
			body := c.Body()

			// Decompress the data
			gzipReader, err := gzip.NewReader(bytes.NewReader(body))
			if err != nil {
				return err
			}
			defer gzipReader.Close()

			// Read the decompressed data
			decompressed, err := ioutil.ReadAll(gzipReader)
			if err != nil {
				return err
			}

			// Log the decompressed data to STDOUT
			// fmt.Println("Received data:", string(decompressed))
			fmt.Print(string(decompressed))

			// Send a response back to the client (optional)
			return c.SendString("Data received successfully!")
		} else {
			return c.Status(fiber.StatusUnauthorized).SendString("Unauthorized access")
		}
	})

	// Start the server
	err := app.Listen(webhookListen) // Replace with the desired port or address to listen on
	if err != nil {
		log.Fatal(err)
	}
}
