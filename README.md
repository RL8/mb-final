# MB Final Project

A containerized web application with:
- Frontend: Nuxt.js (root directory)
- Backend: FastAPI (`/backend` directory)
- Reverse Proxy: Nginx (`/nginx` directory)
- Containerized with Docker

## Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for frontend development)
- Python 3.9+ (for backend development)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/RL8/mb-final.git
   cd mb-final
   ```

2. **Install frontend dependencies**
   ```bash
   npm install
   ```

3. **Start the development environment**
   ```bash
   # Start all services with Docker Compose
   docker-compose up --build -d
   ```

4. **Access the application**
   - Frontend: http://localhost
   - Backend API: http://localhost/api
   - API Health Check: http://localhost/api/health
   - API Documentation: http://localhost/api/docs

## Project Structure

```
.
├── .nuxt/              # Generated Nuxt.js files (not in version control)
├── node_modules/       # Frontend dependencies (not in version control)
├── public/            # Static files served by Nuxt.js
├── server/            # Nuxt.js server middleware
├── backend/           # FastAPI application
│   ├── main.py        # API endpoints
│   ├── requirements.txt
│   ├── Dockerfile
│   └── README.md      # Backend documentation
├── nginx/             # Nginx configuration
│   ├── nginx.conf
│   └── Dockerfile
├── .gitignore
├── app.vue           # Main Vue component
├── nuxt.config.ts    # Nuxt configuration
├── package.json      # Frontend dependencies
└── README.md        # This file
```

## Development

### Backend Development
1. Navigate to the backend directory
2. Create a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: .\venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the development server:
   ```bash
   uvicorn main:app --reload
   ```

### Frontend Development
1. Install dependencies (from project root):
   ```bash
   npm install
   ```
2. Run the development server:
   ```bash
   npm run dev
   ```

## Production Deployment

1. Build the frontend:
   ```bash
   npm run build
   ```

2. Start the containers in production mode:
   ```bash
   docker-compose -f docker-compose.prod.yml up --build -d
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
