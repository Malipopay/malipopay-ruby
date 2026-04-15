# Configuration

This guide covers all the ways to configure the Malipopay Ruby SDK, from basic client setup to Rails integration.

## Malipopay::Client Options

The `Malipopay::Client.new` constructor accepts the following options:

```ruby
client = Malipopay::Client.new(
  api_key: 'your_api_key',
  environment: :production,   # or :uat
  base_url: nil,              # overrides environment if set
  timeout: 30,                # request timeout in seconds
  retries: 2,                 # automatic retries on transient errors
  webhook_secret: nil         # for webhook signature verification
)
```

### Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | `String` | *required* | Your Malipopay API key |
| `environment` | `Symbol` | `:production` | `:production` or `:uat` |
| `base_url` | `String` | `nil` | Custom base URL; overrides `environment` when set |
| `timeout` | `Integer` | `30` | HTTP request timeout in seconds |
| `retries` | `Integer` | `2` | Number of automatic retries for transient errors |
| `webhook_secret` | `String` | `nil` | HMAC-SHA256 secret for webhook signature verification |

### Environment URLs

| Environment | Base URL |
|-------------|----------|
| `:production` | `https://core-prod.malipopay.co.tz` |
| `:uat` | `https://core-uat.malipopay.co.tz` |

## Symbols vs Strings

The SDK accepts both symbols and strings for the `environment` option. Symbols are the Ruby convention:

```ruby
# Preferred (symbol)
client = Malipopay::Client.new(api_key: key, environment: :uat)

# Also works (string)
client = Malipopay::Client.new(api_key: key, environment: 'uat')
```

The same applies to provider names in payment methods -- you can use either:

```ruby
# Both work
client.payments.collect(provider: 'M-Pesa', ...)
client.payments.collect(provider: :'M-Pesa', ...)
```

## Basic Configuration

### Minimal Setup

```ruby
# Production with defaults (30s timeout, 2 retries)
client = Malipopay::Client.new(api_key: ENV['MALIPOPAY_API_KEY'])
```

### UAT for Testing

```ruby
client = Malipopay::Client.new(
  api_key: ENV['MALIPOPAY_UAT_API_KEY'],
  environment: :uat
)
```

### Custom Timeout and Retries

```ruby
client = Malipopay::Client.new(
  api_key: ENV['MALIPOPAY_API_KEY'],
  environment: :production,
  timeout: 60,    # longer timeout for slow networks
  retries: 5      # more retries for critical operations
)
```

## Environment Selection

### Automatic Based on RACK_ENV / RAILS_ENV

Tie the Malipopay environment to your application environment:

```ruby
malipopay_env = if ENV['RACK_ENV'] == 'production' || ENV['RAILS_ENV'] == 'production'
                  :production
                else
                  :uat
                end

api_key = if malipopay_env == :production
            ENV.fetch('MALIPOPAY_API_KEY')
          else
            ENV.fetch('MALIPOPAY_UAT_API_KEY')
          end

client = Malipopay::Client.new(
  api_key: api_key,
  environment: malipopay_env
)
```

### Custom Base URL

For proxies or custom routing:

```ruby
client = Malipopay::Client.new(
  api_key: ENV['MALIPOPAY_API_KEY'],
  base_url: 'https://custom-proxy.example.com'
)
```

When `base_url` is set, it takes precedence over the `environment` setting.

## Rails Integration

### Initializer

Create a Rails initializer to configure the client globally:

```ruby
# config/initializers/malipopay.rb

MALIPOPAY_CLIENT = Malipopay::Client.new(
  api_key: Rails.application.credentials.dig(:malipopay, :api_key) ||
           ENV.fetch('MALIPOPAY_API_KEY'),
  environment: Rails.env.production? ? :production : :uat,
  timeout: 30,
  retries: 2,
  webhook_secret: Rails.application.credentials.dig(:malipopay, :webhook_secret) ||
                  ENV['MALIPOPAY_WEBHOOK_SECRET']
)
```

Then use it anywhere in your Rails app:

```ruby
class PaymentsController < ApplicationController
  def create
    result = MALIPOPAY_CLIENT.payments.collect(
      amount: params[:amount].to_i,
      currency: 'TZS',
      phone: params[:phone],
      provider: params[:provider],
      reference: "ORD-#{SecureRandom.hex(6).upcase}",
      description: params[:description]
    )

    if result['success']
      render json: { status: 'initiated', reference: result['reference'] }
    else
      render json: { error: result['message'] }, status: :unprocessable_entity
    end
  rescue Malipopay::Error => e
    render json: { error: e.message }, status: :service_unavailable
  end
end
```

### Rails Encrypted Credentials

Store your API keys securely with Rails credentials:

```bash
EDITOR=vim rails credentials:edit
```

Add your Malipopay keys:

```yaml
malipopay:
  api_key: your_production_api_key
  webhook_secret: your_webhook_secret
```

Access them in your initializer:

```ruby
Rails.application.credentials.dig(:malipopay, :api_key)
```

### Per-Environment Credentials

Use Rails environment-specific credentials:

```bash
EDITOR=vim rails credentials:edit --environment development
```

```yaml
# config/credentials/development.yml.enc
malipopay:
  api_key: your_uat_api_key
  webhook_secret: your_uat_webhook_secret
```

```bash
EDITOR=vim rails credentials:edit --environment production
```

```yaml
# config/credentials/production.yml.enc
malipopay:
  api_key: your_production_api_key
  webhook_secret: your_production_webhook_secret
```

## Sinatra Integration

For Sinatra apps, configure the client at the top of your app file:

```ruby
require 'sinatra'
require 'malipopay'

configure do
  set :malipopay, Malipopay::Client.new(
    api_key: ENV.fetch('MALIPOPAY_API_KEY'),
    environment: settings.production? ? :production : :uat
  )
end

post '/payments' do
  result = settings.malipopay.payments.collect(
    amount: params[:amount].to_i,
    currency: 'TZS',
    phone: params[:phone],
    provider: 'M-Pesa',
    reference: "ORD-#{SecureRandom.hex(6).upcase}",
    description: 'Payment'
  )

  json result
end
```

## Timeout and Retry Settings

### Timeout

The `timeout` option controls how long the SDK waits for an API response before raising `Malipopay::ConnectionError`:

```ruby
# Short timeout for fast-fail scenarios
client = Malipopay::Client.new(api_key: key, timeout: 10)

# Longer timeout for slow networks or large batch operations
client = Malipopay::Client.new(api_key: key, timeout: 120)
```

### Retries

The `retries` option controls how many times the SDK retries on transient errors (5xx and connection failures):

```ruby
# No automatic retries (handle retries yourself)
client = Malipopay::Client.new(api_key: key, retries: 0)

# Aggressive retries for critical operations
client = Malipopay::Client.new(api_key: key, retries: 5)
```

The SDK uses exponential backoff between retries (1s, 2s, 4s, ...).

## Security Best Practices

1. **Never hardcode API keys.** Use environment variables or Rails encrypted credentials.

2. **Use `.env` files for local development** (with [dotenv](https://github.com/bkeepers/dotenv)):
   ```ruby
   # Gemfile
   gem 'dotenv-rails', groups: [:development, :test]
   ```

   ```bash
   # .env (add to .gitignore!)
   MALIPOPAY_API_KEY=your_uat_key
   MALIPOPAY_WEBHOOK_SECRET=your_webhook_secret
   ```

3. **Rotate keys regularly.** Generate new keys at [app.malipopay.co.tz](https://app.malipopay.co.tz) and update your credentials store.

4. **Use separate keys per environment.** Never share keys between UAT and production.

## Next Steps

- [Getting Started](./getting-started.md) -- quick start guide
- [Error Handling](./error-handling.md) -- handle errors and configure retries
- [Webhooks](./webhooks.md) -- webhook configuration
- [Payments](./payments.md) -- payment operations
