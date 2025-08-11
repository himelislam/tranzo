# Tranzo - File Translation Application

A modern, full-stack file translation application built with Next.js frontend and Express.js backend. Supports translation of text files, Word documents, PDFs, and ZIP archives across 50+ languages.

## 🚀 Features

### Frontend (Next.js)
- **Modern UI**: Clean, responsive design with dark/light theme support
- **File Upload**: Drag-and-drop interface supporting .txt, .docx, .pdf, .zip files
- **Language Selection**: 50+ supported languages with intuitive dropdown
- **Progress Tracking**: Real-time translation progress with visual indicators
- **Status Monitoring**: Live status updates with automatic polling
- **Download Interface**: Easy download of translated files

### Backend (Express.js)
- **File Processing**: Handles multiple file formats with specialized parsers
- **Translation Services**: Google Cloud Translate API + LibreTranslate support
- **Queue System**: Bull/Redis for background job processing
- **Admin Dashboard**: Bull Board for monitoring translation jobs
- **File Management**: Automatic cleanup and organized storage

## 🛠️ Tech Stack

**Frontend:**
- Next.js 15 with TypeScript
- Radix UI components
- Tailwind CSS
- next-themes for theme management

**Backend:**
- Express.js server
- Google Cloud Translate API
- LibreTranslate (alternative)
- Bull Queue with Redis
- Multer for file uploads
- Mammoth.js (DOCX), PDF-lib (PDF), AdmZip (ZIP)

## 📋 Prerequisites

**For Local Development:**
- Node.js 18+
- Redis server
- Google Cloud Translate API key (optional, can use LibreTranslate)

**For Docker Deployment:**
- Docker 20.10+
- Docker Compose 2.0+

## 🚀 Quick Start

Choose between Docker deployment (recommended) or local development:

### 🐳 Option A: Docker Deployment (Recommended)

**1. Start all services with Docker:**
```bash
# Build and start all services (Redis, LibreTranslate, Backend)
npm run docker:start

# Or use the Docker manager directly
./docker-manager.sh start
```

**2. Access the application:**
- **Backend API**: http://localhost:3001
- **Admin Dashboard**: http://localhost:3001/admin/queues
- **LibreTranslate**: http://localhost:5001

**3. Start the frontend separately:**
```bash
npm run dev
```

**4. Access the complete application:**
- **Frontend**: http://localhost:3002 (or next available port)

### 🔧 Option B: Local Development

### 1. Install Dependencies

```bash
# Install frontend dependencies
npm install

# Install backend dependencies
npm run backend:install
```

### 2. Environment Configuration

The project includes pre-configured environment files:

**Frontend (`.env.local`):**
```env
NEXT_PUBLIC_PORT=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001
```

**Backend (`backend/.env`):**
```env
# Google Cloud Translate API Key (optional)
GOOGLE_APPLICATION_CREDENTIALS=path/to/your/google-cloud-key.json

# LibreTranslate Configuration (alternative)
LIBRETRANSLATE_URL=http://localhost:5001

# Redis Configuration
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Server Configuration
PORT=3001
NODE_ENV=development

# CORS Configuration
FRONTEND_URL=http://localhost:3000
```

### 3. Start Redis Server

```bash
# macOS with Homebrew
brew services start redis

# Ubuntu/Debian
sudo systemctl start redis-server

# Docker
docker run -d -p 6379:6379 redis:alpine
```

### 4. Run the Application

**Option A: Run both services simultaneously**
```bash
npm run dev:all
```

**Option B: Run services separately**
```bash
# Terminal 1 - Backend
npm run backend:dev

# Terminal 2 - Frontend
npm run dev
```

### 5. Access the Application

- **Frontend**: http://localhost:3002 (or next available port)
- **Backend API**: http://localhost:3001
- **Admin Dashboard**: http://localhost:3001/admin/queues

## 📁 Project Structure

```
tranzo/
├── app/                    # Next.js app directory
│   ├── globals.css        # Global styles
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Main page component
├── backend/               # Express.js backend
│   ├── index.js          # Main server file
│   ├── package.json      # Backend dependencies
│   ├── .env              # Backend environment
│   ├── uploads/          # Uploaded files
│   ├── translated/       # Translated files
│   └── temp/             # Temporary files
├── components/           # React components
│   ├── ui/              # Radix UI components
│   ├── theme-provider.tsx
│   └── theme-toggle.tsx
├── lib/                 # Utility functions
└── public/              # Static assets
```

## 🔧 Available Scripts

```bash
# Frontend
npm run dev              # Start Next.js development server
npm run build           # Build for production
npm run start           # Start production server

# Backend (Local)
npm run backend:install # Install backend dependencies
npm run backend:dev     # Start backend in development mode
npm run backend:start   # Start backend in production mode

# Combined (Local)
npm run dev:all         # Start both frontend and backend
npm run start:all       # Start both in production mode

# Docker Commands
npm run docker:build    # Build Docker images
npm run docker:start    # Start all services with Docker
npm run docker:stop     # Stop all Docker services
npm run docker:restart  # Restart all Docker services
npm run docker:status   # Show Docker service status
npm run docker:logs     # Show Docker service logs
npm run docker:cleanup  # Stop and clean up Docker resources
```

## 🐳 Docker Deployment

### Docker Services

The application includes a complete Docker setup with:

- **Redis**: Job queue and caching
- **LibreTranslate**: Free translation service
- **Backend**: Express.js API server

### Docker Commands

```bash
# Quick start
./docker-manager.sh start

# Build images
./docker-manager.sh build

# View status
./docker-manager.sh status

# View logs
./docker-manager.sh logs [service-name]

# Stop services
./docker-manager.sh stop

# Clean up
./docker-manager.sh cleanup
```

### Docker Configuration

**Services:**
- `translation-backend`: Main API server (port 3001)
- `redis`: Redis server (port 6379)
- `libretranslate`: Translation service (port 5001)

**Volumes:**
- `./backend/uploads:/app/uploads` - Uploaded files
- `./backend/translated:/app/translated` - Translated files
- `./backend/temp:/app/temp` - Temporary files
- `redis_data:/data` - Redis persistence

### Environment Variables (Docker)

The Docker setup uses `backend/.env.docker` with container-specific settings:
```env
REDIS_HOST=redis
LIBRETRANSLATE_URL=http://libretranslate:5000
NODE_ENV=production
```

## 🌐 API Endpoints

- `POST /upload` - Upload file for translation
- `GET /status/:fileId` - Check translation progress
- `GET /download/:fileId` - Download translated file
- `GET /languages` - Get supported languages
- `GET /admin/queues` - Admin dashboard (Bull Board)
- `GET /` - Health check endpoint

## 🔧 Configuration Options

### Translation Services

**Google Cloud Translate (Recommended):**
1. Create a Google Cloud project
2. Enable the Cloud Translation API
3. Create a service account and download the JSON key
4. Set `GOOGLE_APPLICATION_CREDENTIALS` to the key file path

**LibreTranslate (Free Alternative):**
1. Install LibreTranslate: `pip install libretranslate`
2. Run: `libretranslate --host 0.0.0.0 --port 5001`
3. Update `LIBRETRANSLATE_URL` in backend/.env

## 🚨 Troubleshooting

**Port Conflicts:**
- Frontend automatically finds next available port (3002, 3003, etc.)
- Backend runs on fixed port 3001

**Redis Connection Issues:**
- Ensure Redis is running: `redis-cli ping` should return "PONG"
- Check Redis configuration in backend/.env

**Translation API Issues:**
- Verify Google Cloud credentials are valid
- Check LibreTranslate service is running
- Review backend logs for API errors

## 📝 Development Notes

- Frontend polls backend every 2 seconds for status updates
- Files are automatically cleaned up after processing
- Maximum file size: 50MB (configurable in backend)
- Supported formats: .txt, .docx, .pdf, .zip

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
