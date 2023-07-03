# Gopher Squeeze

`log streaming experiment`

Gopher Squeeze is a program written in Go that takes input from STDIN in chunks, compresses the data with gzip, and sends it to an HTTP endpoint. The server receives the compressed data, decompresses it, and logs it to STDOUT.

## Requirements

- Go 1.20 or higher

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/daxxog/gopher-squeeze.git
   ```

2. Navigate to the project directory:

   ```bash
   cd gopher-squeeze
   ```

3. Build the client and server binaries:

   ```bash
   make
   ```

## Usage

### Server

1. Set the `WEBHOOK_SECRET` environment variable with the desired secret value:

   ```bash
   export WEBHOOK_SECRET=your-secret
   export WEBHOOK_LISTEN=127.0.0.1:8000
   ```

2. Start the server:

   ```bash
   ./gopher-squeeze
   ```

3. The server will start listening on `localhost:8000` (default). It will receive the compressed data, decompress it, and log it to STDOUT.

### Client

1. Set the `WEBHOOK_ENDPOINT` environment variable with the same secret value used for the server:

   ```bash
   export WEBHOOK_ENDPOINT=http://localhost:8000/your-secret
   ```

2. Pipe the input data to the client binary:

   ```bash
   cat input.txt | ./gopher-squeeze
   ```

3. The client will read the input from STDIN in chunks, compress each chunk with gzip, and send it to the server. It will receive a response from the server (optional) and log it to STDOUT.

## License

This project is licensed under the Apache License Version 2.0. See the [LICENSE](LICENSE) file for details.
