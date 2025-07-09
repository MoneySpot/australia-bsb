# BSB Web Service

A secure REST API for Australian BSB (Bank State Branch) number validation and lookup.

## Features

- 🔐 **Authentication**: Bearer token authentication
- 🚦 **Rate Limiting**: Memory-based rate limiting (100 requests/minute by default)
- 📋 **BSB Lookup**: Validate and get detailed information about BSB numbers
- 🛡️ **Security**: CORS support, proper error handling, and secure headers
- 📊 **Monitoring**: Health checks and comprehensive logging
- 📚 **Documentation**: Built-in API documentation endpoint

## Quick Start

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Configure environment** (optional):
   ```bash
   cp config/env.example .env
   # Edit .env with your configuration
   ```

3. **Start the server**:
   ```bash
   ruby bin/server
   ```
   
   Or using Rack:
   ```bash
   rackup config.ru
   ```

4. **Test the API**:
   ```bash
   # Health check (no auth required)
   curl http://localhost:4567/health
   
   # BSB lookup (requires auth)
   curl -H "Authorization: Bearer dev-token-123" \
        http://localhost:4567/bsb/123456
   ```

## API Endpoints

### Authentication

All endpoints except `/health` and `/docs` require authentication using a Bearer token:

```
Authorization: Bearer <your-token>
```

### Endpoints

#### `GET /health`
- **Description**: Health check endpoint
- **Authentication**: Not required
- **Response**: Service status and timestamp

#### `GET /docs`
- **Description**: API documentation
- **Authentication**: Not required
- **Response**: Complete API documentation

#### `GET /bsb/:number`
- **Description**: Look up BSB details by number in URL path
- **Authentication**: Required
- **Parameters**: 
  - `number`: BSB number (6 digits, with or without dash)
- **Example**: `/bsb/123456` or `/bsb/123-456`

#### `GET /lookup?bsb=:number`
- **Description**: Look up BSB details by number in query parameter
- **Authentication**: Required
- **Parameters**: 
  - `bsb`: BSB number (6 digits, with or without dash)
- **Example**: `/lookup?bsb=123456`

### Response Format

All responses are in JSON format:

**Success Response:**
```json
{
  "success": true,
  "data": {
    "bsb": "123456",
    "mnemonic": "XYZ",
    "bank_name": "Example Bank",
    "branch": "Example Branch",
    "address": "123 Example St",
    "suburb": "Example Suburb",
    "state": "NSW",
    "postcode": "2000",
    "flags": {
      "paper": true,
      "electronic": true,
      "high_value": false
    }
  },
  "timestamp": "2025-01-01T00:00:00Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "BSB number not found",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

## Configuration

### Environment Variables

- `PORT`: Server port (default: 4567)
- `HOST`: Server host (default: localhost)
- `RACK_ENV`: Environment (development/production)
- `BSB_API_TOKENS`: Comma-separated list of valid API tokens
- `MAX_REQUESTS_PER_MINUTE`: Rate limit (default: 100)
- `CORS_ORIGINS`: Allowed CORS origins (default: *)

### Authentication Tokens

#### Development
In development mode, the service automatically includes a default token: `dev-token-123`

#### Production
Set valid tokens using the `BSB_API_TOKENS` environment variable:
```bash
export BSB_API_TOKENS="token1,token2,token3"
```

## Rate Limiting

The service implements memory-based rate limiting:
- **Default**: 100 requests per minute per client
- **Identification**: Based on IP address and User-Agent
- **Headers**: Rate limit info included in responses
- **Response**: 429 status code when limit exceeded

## Security Features

- **Authentication**: Bearer token validation
- **Rate Limiting**: Prevents abuse
- **CORS**: Configurable cross-origin resource sharing
- **Headers**: Security headers included in responses
- **Error Handling**: Secure error responses without sensitive data
- **Input Validation**: BSB number format validation

## Development

### Running Tests

```bash
ruby -Itest test/web_service_test.rb
```

### Project Structure

```
├── app.rb                          # Main application
├── config.ru                       # Rack configuration
├── bin/server                       # Server startup script
├── lib/web_service/
│   ├── authentication.rb           # Authentication middleware
│   ├── rate_limiter.rb             # Rate limiting middleware
│   ├── error_handler.rb            # Error handling
│   └── configuration.rb            # Configuration management
├── config/
│   └── env.example                 # Environment configuration example
└── test/
    └── web_service_test.rb         # Web service tests
```

## Production Deployment

1. **Set environment variables**:
   ```bash
   export RACK_ENV=production
   export BSB_API_TOKENS="your-secure-tokens"
   export PORT=8080
   ```

2. **Use a production server** (e.g., Puma):
   ```bash
   bundle exec puma -C config/puma.rb
   ```

3. **Set up reverse proxy** (Nginx/Apache) for SSL termination and load balancing

## Error Codes

- `400`: Bad Request (invalid parameters)
- `401`: Unauthorized (missing/invalid token)
- `404`: Not Found (BSB not found or invalid endpoint)
- `405`: Method Not Allowed
- `429`: Too Many Requests (rate limit exceeded)
- `500`: Internal Server Error

## Examples

### cURL Examples

```bash
# Health check
curl http://localhost:4567/health

# BSB lookup (path parameter)
curl -H "Authorization: Bearer dev-token-123" \
     http://localhost:4567/bsb/123456

# BSB lookup (query parameter)
curl -H "Authorization: Bearer dev-token-123" \
     "http://localhost:4567/lookup?bsb=123456"

# API documentation
curl http://localhost:4567/docs
```

### Python Example

```python
import requests

url = "http://localhost:4567/bsb/123456"
headers = {"Authorization": "Bearer dev-token-123"}

response = requests.get(url, headers=headers)
print(response.json())
```

### JavaScript Example

```javascript
fetch('http://localhost:4567/bsb/123456', {
  headers: {
    'Authorization': 'Bearer dev-token-123'
  }
})
.then(response => response.json())
.then(data => console.log(data));
```

## License

This project is licensed under the MIT License.
