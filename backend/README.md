# Backend Service

This directory contains the FastAPI backend service for the application.

## Project Structure

```
backend/
├── main.py           # FastAPI application entry point
├── requirements.txt  # Python dependencies
└── Dockerfile        # Container configuration
```

## Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the development server:
   ```bash
   uvicorn main:app --reload
   ```

## API Endpoints

- `GET /health` - Health check endpoint
- `GET /api/items` - Get list of items (example)
- `GET /api/items/{item_id}` - Get item by ID (example)

## Development

- The server will reload automatically when you make changes
- Access API documentation at `http://localhost:8000/docs`

## Docker

Build and run with Docker:
```bash
docker build -t backend .
docker run -p 8000:8000 backend
```
