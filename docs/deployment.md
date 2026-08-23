# Deployment Guide

## Overview

AI Song Studio can be deployed in multiple configurations:

1. **Local Development** (simulator/device)
2. **Apple Native** (iOS/macOS app)
3. **Web Frontend** (React/Next.js)
4. **Backend API** (Node.js/Docker)
5. **Hybrid Cloud** (managed service)

## Prerequisites

### For All Platforms
- Git
- Environment variables configured (see `.env.example`)

### For Apple Native
- Xcode 14+ (for Core AI: Xcode 15+)
- iOS 16+ or macOS 13+ (for Core AI: iOS 18+ or macOS 14+)
- Apple Developer Account (for device deployment)

### For Web
- Node.js 18+
- npm or yarn

### For Backend
- Docker (optional)
- Node.js 18+
- Database (optional, for production)

## Local Development Setup

### 1. Clone Repository
```bash
git clone https://github.com/ozzyag9-cloud/ai-song-studio.git
cd ai-song-studio
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env and add your credentials
```

### 3. Apple Native (Simulator)
```bash
cd Apple
xed -b AISongStudio.xcodeproj
# Or via command line:
xcodebuild -scheme AISongStudio -destination 'generic/platform=iOS Simulator'
```

### 4. Apple Native (Device)
```bash
# Build and run on connected device
xcodebuild -scheme AISongStudio -destination 'generic/platform=iOS'
```

### 5. Web Development
```bash
cd Web/frontend
npm install
npm run dev
# App runs on http://localhost:3000
```

### 6. Backend (Optional)
```bash
cd Web/backend
npm install
npm run dev
# API runs on http://localhost:8080
```

## Production Deployment

### Apple App Store

1. **Sign & Certify**
   ```bash
   # Create signing certificate
   xcodebuild -scheme AISongStudio archive \
     -archivePath build/AISongStudio.xcarchive \
     -signingStyle automatic
   ```

2. **Create IPA**
   ```bash
   xcodebuild -exportArchive \
     -archivePath build/AISongStudio.xcarchive \
     -exportOptionsPlist exportOptions.plist \
     -exportPath build
   ```

3. **Submit to App Store**
   - Use Xcode's Organizer or Transporter
   - Follow App Store Connect review guidelines

### Web Frontend (Vercel)

1. **Connect Repository**
   ```bash
   npm install -g vercel
   vercel link
   ```

2. **Deploy**
   ```bash
   vercel --prod
   ```

3. **Environment Variables**
   - Set in Vercel dashboard
   - BACKEND_URL, DEBUG, etc.

### Backend (Docker/Heroku)

1. **Build Docker Image**
   ```dockerfile
   FROM node:18-alpine
   WORKDIR /app
   COPY Web/backend/package*.json ./
   RUN npm ci --only=production
   COPY Web/backend ./
   EXPOSE 8080
   CMD ["npm", "start"]
   ```

2. **Deploy to Heroku**
   ```bash
   heroku login
   heroku create ai-song-studio-api
   git push heroku main
   ```

3. **Configure Secrets**
   ```bash
   heroku config:set ELEVENLABS_API_KEY="..."
   heroku config:set GOOGLE_LYRIA_API_KEY="..."
   ```

### Backend (AWS Lambda)

1. **Package Function**
   ```bash
   cd Web/backend
   npm install
   zip -r lambda-function.zip .
   ```

2. **Deploy**
   - Create Lambda function
   - Upload ZIP
   - Set environment variables
   - Create API Gateway endpoint

## Configuration

### Environment Variables

See `.env.example` for all variables. Key ones:

```bash
# Producer mode
PRODUCER_MODE=hybrid

# Providers
ELEVENLABS_API_KEY=sk-...
GOOGLE_LYRIA_API_KEY=...

# Backend
BACKEND_URL=https://api.example.com
DATABASE_URL=postgresql://...

# Logging
DEBUG=false
LOG_LEVEL=info
```

### Secrets Management

#### Local (Development)
- Use `.env` file (gitignored)
- Never commit real credentials

#### Production (Apple)
- Store in Keychain
- Load at runtime
- See `Apple/AISongStudio/Services/CredentialManager.swift`

#### Production (Web)
- Backend loads from environment
- Frontend never holds API keys
- Backend proxies all provider calls

## Testing Before Deployment

### Unit Tests
```bash
# Swift (Apple)
xcodebuild test -scheme AISongStudio

# Web/Backend
npm test
```

### Integration Tests
```bash
# Test with real credentials (gated by flag)
PROVIDER_TEST=true npm test
```

### Manual Testing
1. Create a test Song Project
2. Generate lyrics (local or cloud)
3. Generate music
4. Analyze audio
5. Critique song

## Monitoring & Logging

### Apple Native
- Xcode Console for development
- os_log framework for structured logging
- CloudKit for crash reporting (optional)

### Web/Backend
- Console logging via Winston or Pino
- Error tracking (Sentry, DataDog)
- Metrics (Prometheus, CloudWatch)

### Providers
- Monitor API rate limits
- Log generation times and costs
- Alert on credential expiration

## Scaling

### Backend API
- Horizontally scale with load balancer
- Use connection pooling for database
- Cache common requests (Redis)
- Queue long-running tasks (Bull, RabbitMQ)

### Cloud Storage
- Store audio files in S3/GCS
- CDN for distribution
- Consider regional endpoints

## Rollback Procedure

### App Store
1. Create new build with fix
2. Increment version number
3. Submit for review
4. During review, existing version remains active

### Web (Vercel)
1. Revert commit or create hotfix branch
2. Deploy previous version: `vercel --prod --target <commit-sha>`

### Backend (Heroku/Lambda)
1. Heroku: `heroku rollback`
2. Lambda: Publish previous layer/version

## Support

For deployment issues:
1. Check logs: `heroku logs --tail`, Xcode Console, browser DevTools
2. Review `.env` configuration
3. Verify provider credentials and quotas
4. Check network connectivity
5. Open GitHub issue with logs and error details
