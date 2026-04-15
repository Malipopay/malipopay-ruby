# Getting Started with Malipopay Ruby SDK

## Prerequisites

- **Ruby 3.0** or later
- **Bundler** (included with Ruby)
- A Malipopay merchant account with API credentials

## Installation

Add Malipopay to your Gemfile:

```ruby
gem 'malipopay'
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install malipopay
```

## Getting Your API Key

1. Sign in to your merchant dashboard at [app.malipopay.co.tz](https://app.malipopay.co.tz)
2. Navigate to **Settings > API Keys**
3. Click **Generate New Key**
4. Copy the API key immediately -- it will only be shown once
5. Store it securely (environment variable, credentials file, etc.)

> **Important:** Never commit API keys to source control. Use environment variables or Rails encrypted credentials.

## Your First Payment Collection

Collect TZS 50,000 from an M-Pesa customer in five lines:

```ruby
require 'malipopay'

client = Malipopay::Client.new(api_key: ENV['MALIPOPAY_API_KEY'])

result = client.payments.collect(
  amount: 50_000,
  currency: 'TZS',
  phone: '255712345678',
  provider: 'M-Pesa',
  reference: 'ORDER-2024-001',
  description: 'Payment for office supplies'
)

puts "Collection initiated: #{result['reference']}" if result['success']
```

When this runs, the customer at `255712345678` receives a USSD push prompt on their phone asking them to confirm the TZS 50,000 payment with their M-Pesa PIN.

## Environment Selection

Malipopay provides two environments:

| Environment | Base URL | Purpose |
|-------------|----------|---------|
| **Production** | `https://core-prod.malipopay.co.tz` | Live transactions with real money |
| **UAT** | `https://core-uat.malipopay.co.tz` | Testing and integration development |

### Using UAT for Testing

Always develop and test against UAT before going live:

```ruby
client = Malipopay::Client.new(
  api_key: ENV['MALIPOPAY_UAT_API_KEY'],
  environment: :uat
)
```

### Custom Base URL

For advanced setups (proxies, custom routing), you can override the base URL:

```ruby
client = Malipopay::Client.new(
  api_key: ENV['MALIPOPAY_API_KEY'],
  base_url: 'https://custom-proxy.example.com'
)
```

When `base_url` is set, it takes precedence over the `environment` setting.

## Configuring Timeouts and Retries

The SDK automatically retries transient failures. You can adjust timeout and retry behavior:

```ruby
client = Malipopay::Client.new(
  api_key: ENV['MALIPOPAY_API_KEY'],
  environment: :production,
  timeout: 60,    # seconds (default: 30)
  retries: 3      # automatic retries (default: 2)
)
```

## Complete Minimal Example

A full script that collects a payment and verifies it:

```ruby
require 'malipopay'

api_key = ENV.fetch('MALIPOPAY_API_KEY') { raise 'Set the MALIPOPAY_API_KEY environment variable' }

client = Malipopay::Client.new(
  api_key: api_key,
  environment: :uat
)

begin
  reference = "ORD-#{Time.now.strftime('%Y%m%d%H%M%S')}"

  # Step 1: Initiate collection
  collection = client.payments.collect(
    amount: 15_000,
    currency: 'TZS',
    phone: '255754321098',
    provider: 'Airtel Money',
    reference: reference,
    description: 'Monthly subscription'
  )

  puts "Collection initiated. Reference: #{reference}"

  # Step 2: Wait for the customer to approve on their phone
  # In production, use webhooks instead of polling
  sleep 30

  # Step 3: Verify the payment
  verification = client.payments.verify(reference)

  puts "Payment status: #{verification['status']}"

rescue Malipopay::AuthenticationError
  puts 'Invalid API key. Check your credentials.'
rescue Malipopay::ValidationError => e
  puts "Invalid request: #{e.message}"
rescue Malipopay::Error => e
  puts "Payment error: #{e.message}"
end
```

## Next Steps

- [Payments Guide](./payments.md) -- all payment operations in detail
- [Webhooks](./webhooks.md) -- receive real-time payment notifications
- [Configuration](./configuration.md) -- advanced client setup
- [Error Handling](./error-handling.md) -- handling failures gracefully
