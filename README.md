# MB Final Project

A containerized web application with:
- Frontend: Nuxt.js
- Backend: FastAPI
- Reverse Proxy: Nginx
- Containerized with Docker

## Prerequisites

- Docker
- Docker Compose
- Node.js (for frontend development)
- Python 3.9+ (for backend development)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mb-final
   ```

2. **Build and start the services**
   ```bash
   docker-compose up --build -d
   ```

3. **Access the application**
   - Frontend: http://localhost
   - Backend API: http://localhost/api
   - API Health Check: http://localhost/api/health

## Project Structure

```
.
├── docker-compose.yml    # Defines all services
├── nginx/                # Nginx configuration
│   ├── Dockerfile
│   └── nginx.conf
├── backend/              # FastAPI application
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
└── frontend/             # Nuxt.js frontend
```

## Development

### Backend Development
1. Navigate to the backend directory
2. Install dependencies: `pip install -r requirements.txt`
3. Run the development server: `uvicorn main:app --reload`

### Frontend Development
1. Navigate to the frontend directory
2. Install dependencies: `npm install`
3. Run the development server: `npm run dev`

## Production Deployment

1. Build the frontend for production:
   ```bash
   cd frontend
   npm run build
   ```

2. Start the containers in detached mode:
   ```bash
   docker-compose up --build -d
   ```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Backend
SECRET_KEY=your-secret-key
DATABASE_URL=postgresql://user:password@db:5432/dbname

# Frontend
NODE_ENV=production
API_BASE_URL=/api
```

## License

MIT
