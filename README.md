# Weather System

A comprehensive Ruby on Rails web application for weather data management, featuring user authentication, weather data retrieval, reporting capabilities, and RESTful API endpoints.

## 🌟 Features

### Core Functionality
- **Weather Data Retrieval**: Search weather information by Brazilian postal code (CEP)
- **User Authentication**: Complete user management with Devise
- **Data Persistence**: Store weather data with user associations
- **Caching**: Redis-based caching for improved performance
- **Background Jobs**: Asynchronous report generation with Sidekiq

### User Management
- User registration and authentication
- Email confirmation system
- Password recovery
- JWT token-based API authentication
- User-specific weather data tracking

### Reporting System
- **Multiple Export Formats**: CSV, Excel (XLSX), and PDF
- **Advanced Filtering**: Filter by postal code, date ranges
- **Background Processing**: Asynchronous report generation
- **Email Notifications**: Optional email alerts when reports are ready
- **Report History**: Track and download previously generated reports

### API Integration
- **OpenWeatherMap Integration**: Real-time weather data from external API
- **Fallback System**: Database fallback when API is unavailable
- **RESTful API**: JSON endpoints for external integrations
- **API Documentation**: Swagger/OpenAPI documentation

### Security & Performance
- **Rate Limiting**: Rack-attack for API protection
- **Input Validation**: Comprehensive data validation
- **Caching Strategy**: 30-minute cache for weather data
- **Background Processing**: Non-blocking report generation

## 🏗️ Architecture

### Technology Stack
- **Backend**: Ruby on Rails 8.0.3
- **Database**: PostgreSQL 16
- **Cache**: Redis 5.0
- **Background Jobs**: Sidekiq
- **Email**: MailHog (development)
- **Containerization**: Docker & Docker Compose
- **Frontend**: Bootstrap, Stimulus, Turbo

### Key Components
- **WeatherService**: Handles external API integration and caching
- **WeatherReportService**: Manages report generation in multiple formats
- **ReportGenerationJob**: Background job for asynchronous processing
- **User Model**: Authentication and authorization
- **Weather Model**: Data persistence and associations

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Make (for using the Makefile)

### Environment Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd weather
   ```

2. **Create environment file**:
   ```bash
   cp .env.example .env
   ```
   
   Configure the following variables in `.env`:
   ```env
   OPENWEATHER_API_KEY=your_openweather_api_key
   RAILS_MASTER_KEY=your_rails_master_key
   ```

3. **Start the platform using Makefile**:
   ```bash
   make up
   ```

   This command will:
   - Build and start all Docker containers
   - Set up PostgreSQL database
   - Start Redis cache
   - Launch MailHog for email testing
   - Start the Rails application

4. **Load seed data**:
   ```bash
   # Access the web container and run seeds
   docker exec -it web bash
   rails db:seed
   ```

5. **Access the application**:
   - **Web Application**: http://localhost:3000 (login with `web@weather.com` / `password123`)
   - **API Documentation**: http://localhost:3000/api-docs
   - **MailHog Interface**: http://localhost:8025

## 📋 Makefile Commands

The project includes a comprehensive Makefile for easy platform management:

### Container Management
```bash
make up          # Start all services (PostgreSQL, Redis, MailHog, Web)
make down        # Stop all services
make logs        # View logs from all services
make logs ARG=web # View logs from specific service
make ps          # List status of all containers
make prune       # Clean up unused Docker resources
```

### Usage Examples
```bash
# Start the entire platform
make up

# View real-time logs
make logs

# View only web application logs
make logs ARG=web

# Check container status
make ps

# Stop all services
make down

# Clean up Docker resources
make prune
```

## 🔧 Configuration

### Database Setup
The application automatically sets up the database on first run. If you need to reset:

```bash
# Access the web container
docker exec -it web bash

# Run database setup
rails db:create db:migrate db:seed
```

### Seed Data
The application includes pre-configured users for testing:

**Web User (for web interface):**
- Email: `web@weather.com`
- Password: `password123`
- Use: Login to the web interface at http://localhost:3000

**API User (for API testing):**
- Email: `api@weather.com`
- Password: `api123456`
- Token: Generated automatically (displayed after seeding)
- Use: API authentication with `Authorization: Bearer <token>`

**Admin User:**
- Email: `admin@weather.com`
- Password: `admin123`
- Use: System administration

**Sample Data:**
- Pre-loaded weather data for testing
- Multiple postal codes with different weather conditions
- Associated with different users for testing user-specific features

To run the seeds:
```bash
# Access the web container
docker exec -it web bash

# Run seeds
rails db:seed
```

### API Configuration
1. **OpenWeatherMap API**:
   - Sign up at [OpenWeatherMap](https://openweathermap.org/api)
   - Get your API key
   - Add it to your `.env` file as `OPENWEATHER_API_KEY`

2. **Rails Master Key**:
   - Generate a master key: `rails credentials:edit`
   - Add it to your `.env` file as `RAILS_MASTER_KEY`

## 📖 Usage Guide

### Web Interface

1. **User Registration**:
   - Visit http://localhost:3000
   - Click "Sign Up" to create an account
   - Confirm your email via MailHog interface

2. **Weather Search**:
   - Enter a Brazilian postal code (8 digits)
   - Click "Search" to get current weather data
   - View temperature, min/max temps, and weather description

3. **Report Generation**:
   - Navigate to "Reports" section
   - Apply filters (postal code, date range)
   - Choose export format (CSV, Excel, PDF)
   - Enable email notifications if desired
   - Download completed reports

### API Usage

#### Authentication
Include your authentication token in the Authorization header. Use the API user token from the seed data:

```bash
# Using the seeded API user token (replace with actual token from db:seed output)
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     http://localhost:3000/api/v1/weathers/12345678

# Example with a real token (run rails db:seed to get the actual token)
curl -H "Authorization: Bearer a1b2c3d4e5f6..." \
     http://localhost:3000/api/v1/weathers/01310100
```

**Getting the API Token:**
1. Run `rails db:seed` to create the API user
2. The token will be displayed in the console output
3. Use this token in your API requests

#### Available Endpoints
- `GET /api/v1/weathers/:zip` - Get weather data for a postal code
- `GET /api-docs` - API documentation interface

### Data Models

#### Weather Data Structure
```json
{
  "temperature": 25.0,
  "temp_min": 20.0,
  "temp_max": 30.0,
  "description": "clear sky",
  "from_cache": true,
  "from_database": false
}
```

#### User Model
- Email-based authentication
- JWT token for API access
- Associated weather records and reports

## 🧪 Testing

### Running Tests
```bash
# Access the web container
docker exec -it web bash

# Run all tests
rails test

# Run specific test suites
rails test:models
rails test:controllers
rails test:system
```

### Test Coverage
- **Unit Tests**: Models, services, and helpers
- **Integration Tests**: Controller actions and API endpoints
- **System Tests**: End-to-end user workflows
- **Service Tests**: External API integration with mocking

## 🔒 Security Features

- **Rate Limiting**: Prevents API abuse
- **Input Validation**: Comprehensive data sanitization
- **Authentication**: Multi-layer authentication system
- **Authorization**: User-specific data access
- **Secure Headers**: Content Security Policy implementation

## 📊 Monitoring & Logging

### Logs
- **Application Logs**: Rails application events
- **Container Logs**: Docker container status
- **Background Jobs**: Sidekiq job processing

### Monitoring
- **Health Checks**: Container health monitoring
- **Performance Metrics**: Response times and caching statistics
- **Error Tracking**: Comprehensive error logging

## 🚀 Deployment

### Production Considerations
- Update `docker-compose.yml` for production environment
- Configure production database credentials
- Set up proper SSL certificates
- Configure production email service
- Set up monitoring and alerting

### Environment Variables
```env
RAILS_ENV=production
DATABASE_URL=postgresql://user:password@host:port/database
REDIS_URL=redis://host:port
OPENWEATHER_API_KEY=your_production_api_key
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the API documentation at `/api-docs`
- Review the test files for usage examples
- Check container logs with `make logs`

## 🔄 Updates & Maintenance

### Regular Maintenance
```bash
# Update dependencies
make down
docker-compose pull
make up

# Clean up old data
make prune
```

### Database Maintenance
```bash
# Backup database
docker exec weather-pg pg_dump -U postgres weather_development > backup.sql

# Restore database
docker exec -i weather-pg psql -U postgres weather_development < backup.sql
```