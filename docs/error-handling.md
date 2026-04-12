# Error Handling

The MaliPoPay Ruby SDK uses a structured exception hierarchy so you can rescue specific error types and respond appropriately. All exceptions inherit from `MaliPoPay::Error`.

## Exception Hierarchy

```
MaliPoPay::Error (base)
├── MaliPoPay::AuthenticationError    (HTTP 401 -- invalid or missing API key)
├── MaliPoPay::PermissionError        (HTTP 403 -- insufficient permissions)
├── MaliPoPay::NotFoundError          (HTTP 404 -- resource does not exist)
├── MaliPoPay::ValidationError        (HTTP 422 -- invalid request parameters)
├── MaliPoPay::RateLimitError         (HTTP 429 -- too many requests)
├── MaliPoPay::ApiError               (HTTP 5xx -- server-side error)
└── MaliPoPay::ConnectionError        (network timeout, DNS failure, etc.)
```

## Rescuing Specific Exceptions

### Ordered by Specificity

```ruby
begin
  result = client.payments.collect(
    amount: 50_000,
    currency: 'TZS',
    phone: '255712345678',
    provider: 'M-Pesa',
    reference: 'ORD-2024-100',
    description: 'Monthly subscription'
  )

  puts "Collection initiated: #{result['reference']}"

rescue MaliPoPay::AuthenticationError
  # API key is invalid or expired
  puts 'Authentication failed. Rotate your API key at app.malipopay.co.tz'

rescue MaliPoPay::PermissionError
  # API key lacks permission for this operation
  puts 'Insufficient permissions. Check your API key scopes.'

rescue MaliPoPay::ValidationError => e
  # The request had invalid fields
  puts "Invalid request: #{e.message}"
  # e.message might say: "phone must be a valid Tanzanian number (255xxxxxxxxx)"

rescue MaliPoPay::NotFoundError
  puts 'The requested resource was not found.'

rescue MaliPoPay::RateLimitError
  puts 'Too many requests. Back off and retry.'

rescue MaliPoPay::ApiError => e
  # MaliPoPay server error -- transient, safe to retry
  puts "Server error (#{e.message}). Retrying..."

rescue MaliPoPay::ConnectionError => e
  # Network-level failure
  puts "Connection failed: #{e.message}"

rescue MaliPoPay::Error => e
  # Catch-all for any other SDK error
  puts "Unexpected error: #{e.message}"
end
```

## Exception Properties

Every `MaliPoPay::Error` includes:

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | Human-readable error description |
| `status_code` | `Integer` or `nil` | HTTP status code (`nil` for `ConnectionError`) |

## Retry Strategies

The SDK automatically retries transient errors (5xx, connection timeouts) based on the `retries` option. You can also implement your own retry logic for specific cases.

### Built-in Retries

```ruby
client = MaliPoPay::Client.new(
  api_key: ENV['MALIPOPAY_API_KEY'],
  retries: 3  # retry up to 3 times on transient failures (default: 2)
)
```

The SDK uses exponential backoff between retries. It will only retry on:
- `MaliPoPay::ApiError` (5xx responses)
- `MaliPoPay::ConnectionError` (network timeouts and DNS failures)

It will **not** retry on:
- `AuthenticationError` (fix your API key)
- `PermissionError` (check your API key scopes)
- `ValidationError` (fix your request)
- `NotFoundError` (the resource doesn't exist)
- `RateLimitError` (handled separately -- see below)

### Custom Retry for Rate Limits

```ruby
def with_rate_limit_retry(max_retries: 3)
  attempts = 0

  begin
    yield
  rescue MaliPoPay::RateLimitError
    attempts += 1
    raise if attempts > max_retries

    delay = 2**attempts  # exponential backoff: 2s, 4s, 8s
    puts "Rate limited. Retrying in #{delay}s..."
    sleep delay
    retry
  end
end

# Usage
result = with_rate_limit_retry do
  client.payments.collect(
    amount: 75_000,
    currency: 'TZS',
    phone: '255712345678',
    provider: 'M-Pesa',
    reference: 'ORD-2024-200',
    description: 'Retry example'
  )
end
```

### Generic Retry Helper

```ruby
def with_retry(max_retries: 3, on: [MaliPoPay::ApiError, MaliPoPay::ConnectionError])
  attempts = 0

  begin
    yield
  rescue *on => e
    attempts += 1
    raise if attempts > max_retries

    delay = 2**attempts
    puts "#{e.class}: #{e.message}. Retry #{attempts}/#{max_retries} in #{delay}s..."
    sleep delay
    retry
  end
end

# Usage
result = with_retry(max_retries: 5) do
  client.payments.disburse(
    amount: 250_000,
    currency: 'TZS',
    phone: '255754321098',
    provider: 'Airtel Money',
    reference: 'PAY-2024-055',
    description: 'Supplier payment'
  )
end
```

## Common Errors and Solutions

### AuthenticationError (401)

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid API key" | The `apiToken` header is wrong or missing | Verify your key at [app.malipopay.co.tz](https://app.malipopay.co.tz) under Settings > API Keys |
| "API key expired" | Key was revoked or rotated | Generate a new key in the dashboard |
| "Unauthorized environment" | Using a production key on UAT or vice versa | Use the correct key for your environment |

### PermissionError (403)

| Error | Cause | Solution |
|-------|-------|----------|
| "Insufficient permissions" | API key lacks required scope | Check key permissions in the dashboard |

### ValidationError (422)

| Error | Cause | Solution |
|-------|-------|----------|
| "phone must be a valid Tanzanian number" | Phone number not in `255xxxxxxxxx` format | Use the full international format: `255712345678` |
| "amount must be greater than 0" | Zero or negative amount | Provide a positive integer amount in TZS |
| "provider is required" | Missing `provider` field | Specify one of: `M-Pesa`, `Airtel Money`, `Mixx`, `Halopesa`, `T-Pesa`, `CRDB`, `NMB` |
| "reference must be unique" | Duplicate reference string | Generate a unique reference per transaction |
| "currency must be TZS" | Unsupported currency | MaliPoPay currently supports TZS only |

### NotFoundError (404)

| Error | Cause | Solution |
|-------|-------|----------|
| "Payment not found" | Reference doesn't match any payment | Double-check the reference string |
| "Customer not found" | Customer ID doesn't exist | Create the customer first or verify the ID |
| "Invoice not found" | Invoice ID doesn't exist | Check the invoice ID from your records |

### RateLimitError (429)

| Error | Cause | Solution |
|-------|-------|----------|
| "Rate limit exceeded" | Too many API calls in a short period | Implement exponential backoff; batch operations where possible |

### ApiError (5xx)

| Error | Cause | Solution |
|-------|-------|----------|
| "Internal server error" | Temporary server issue | Retry after a short delay; these are transient |
| "Service unavailable" | Maintenance or provider downtime | Check [status.malipopay.co.tz](https://status.malipopay.co.tz) for updates |

### ConnectionError

| Error | Cause | Solution |
|-------|-------|----------|
| "Request timed out" | Network latency or server unresponsive | Increase `timeout` in client options; check network connectivity |
| "DNS resolution failed" | Cannot resolve the API hostname | Verify your DNS settings and internet connection |

## Logging Errors

Use Ruby's Logger for production error tracking:

```ruby
require 'logger'

logger = Logger.new($stdout)

begin
  result = client.payments.collect(
    amount: 30_000,
    currency: 'TZS',
    phone: '255622345678',
    provider: 'Halopesa',
    reference: 'ORD-2024-300',
    description: 'Logging example'
  )
rescue MaliPoPay::Error => e
  logger.error("MaliPoPay API error: status=#{e.status_code} message=#{e.message}")
  raise
end
```

### Rails Integration

In Rails, errors are automatically logged. You can add custom handling in an initializer or concern:

```ruby
# app/controllers/concerns/malipopay_error_handling.rb
module MalipopayErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from MaliPoPay::AuthenticationError do |e|
      Rails.logger.error("MaliPoPay auth error: #{e.message}")
      render json: { error: 'Payment service authentication failed' }, status: :service_unavailable
    end

    rescue_from MaliPoPay::ValidationError do |e|
      render json: { error: e.message }, status: :unprocessable_entity
    end

    rescue_from MaliPoPay::Error do |e|
      Rails.logger.error("MaliPoPay error: #{e.class} - #{e.message}")
      render json: { error: 'Payment service error' }, status: :service_unavailable
    end
  end
end
```

## Next Steps

- [Configuration](./configuration.md) -- configure retries and timeouts at the client level
- [Payments](./payments.md) -- payment operations that may raise these exceptions
- [Webhooks](./webhooks.md) -- webhook signature verification errors
