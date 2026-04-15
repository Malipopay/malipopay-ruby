# Malipopay Ruby SDK

Official Ruby SDK for the [Malipopay](https://malipopay.co.tz) payment platform (Tanzania).

## Installation

Add to your Gemfile:

```ruby
gem "malipopay"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install malipopay
```

## Quick Start

```ruby
require "malipopay"

client = Malipopay::Client.new(
  api_key: "your_api_token",
  environment: :production  # or :uat for testing
)
```

## Configuration

| Option           | Default       | Description                          |
|------------------|---------------|--------------------------------------|
| `api_key`        | *required*    | Your Malipopay API token             |
| `environment`    | `:production` | `:production` or `:uat`              |
| `base_url`       | `nil`         | Override the base URL                |
| `timeout`        | `30`          | Request timeout in seconds           |
| `retries`        | `2`           | Number of retries on 429/5xx         |
| `webhook_secret` | `nil`         | Secret for verifying webhook events  |

## Resources

### Payments

```ruby
# Collect mobile money
result = client.payments.collect(
  amount: 10_000,
  phone: "255712345678",
  provider: "Vodacom",
  reference: "ORDER-001",
  currency: "TZS"
)

# Disburse (send money)
client.payments.disburse(
  amount: 5_000,
  phone: "255712345678",
  provider: "M-Pesa",
  reference: "PAY-001"
)

# Verify payment
status = client.payments.verify("PAY-REF-123")

# List payments
payments = client.payments.list(page: 1, limit: 20)

# Search payments
results = client.payments.search(status: "completed", dateFrom: "2026-01-01")

# Approve a pending payment
client.payments.approve(reference: "PAY-REF-123")

# Retry a failed collection
client.payments.retry_collection("PAY-REF-123")

# Create a payment link
link = client.payments.create_link(amount: 50_000, description: "Product purchase")

# Instant payment
client.payments.pay_now(amount: 10_000, phone: "255712345678")
```

### Customers

```ruby
# Create a customer
customer = client.customers.create(
  name: "John Doe",
  phone: "255712345678",
  email: "john@example.com"
)

# List customers
customers = client.customers.list(page: 1, limit: 20)

# Get by ID
customer = client.customers.get("customer_id")

# Search
results = client.customers.search(query: "John")

# Get by phone
customer = client.customers.get_by_phone("255712345678")

# Verify customer
client.customers.verify_customer(phone: "255712345678")
```

### Invoices

```ruby
# Create an invoice
invoice = client.invoices.create(
  customerId: "cust_123",
  items: [
    { description: "Service", quantity: 1, unitPrice: 100_000 }
  ],
  currency: "TZS",
  dueDate: "2026-12-31"
)

# List invoices
invoices = client.invoices.list(page: 1, limit: 20)

# Get by ID
invoice = client.invoices.get("invoice_id")

# Approve a draft invoice
client.invoices.approve_draft(invoiceId: "invoice_id")

# Record a payment
client.invoices.record_payment(
  invoiceId: "invoice_id",
  amount: 50_000,
  reference: "RCPT-001"
)
```

### Products

```ruby
# Create a product
product = client.products.create(
  name: "Premium Plan",
  price: 99_000,
  description: "Monthly subscription"
)

# List / Get / Update
products = client.products.list
product = client.products.get("product_id")
client.products.update("product_id", price: 89_000)
```

### Transactions

```ruby
# List transactions
transactions = client.transactions.list(page: 1, limit: 50)

# Get by ID
txn = client.transactions.get("txn_id")

# Search
results = client.transactions.search(dateFrom: "2026-01-01", dateTo: "2026-03-31")

# Paginate through all transactions
client.transactions.paginate(limit: 100).each do |page|
  page["data"].each { |txn| process(txn) }
end
```

### Account

```ruby
# Get account transactions
txns = client.account.transactions(dateFrom: "2026-01-01")

# Reconciliation
recon = client.account.reconciliation(dateFrom: "2026-01-01", dateTo: "2026-03-31")

# Financial reports
client.account.financial_position
client.account.income_statement
client.account.general_ledger
client.account.trial_balance
```

### SMS

```ruby
# Send a single SMS
client.sms.send_sms(
  to: "255712345678",
  message: "Your payment of TZS 10,000 has been received.",
  senderId: "Malipopay"
)

# Send bulk SMS
client.sms.send_bulk(
  messages: [
    { to: "255712345678", message: "Hello John!" },
    { to: "255798765432", message: "Hello Jane!" }
  ],
  senderId: "Malipopay"
)

# Schedule SMS
client.sms.schedule(
  to: "255712345678",
  message: "Reminder: Your invoice is due tomorrow.",
  senderId: "Malipopay",
  scheduledAt: "2026-04-15T09:00:00Z"
)
```

### References

```ruby
banks = client.references.banks
currencies = client.references.currencies
countries = client.references.countries
institutions = client.references.institutions
business_types = client.references.business_types
```

## Webhooks

```ruby
client = Malipopay::Client.new(
  api_key: "your_api_token",
  webhook_secret: "whsec_your_secret"
)

# In your webhook endpoint (e.g., Sinatra, Rails controller)
payload = request.body.read
signature = request.headers["X-Malipopay-Signature"]
timestamp = request.headers["X-Malipopay-Timestamp"]

event = client.webhooks.construct_event(payload, signature, timestamp: timestamp)

case event["event"]
when "payment.completed"
  # Handle successful payment
when "payment.failed"
  # Handle failed payment
end
```

## Error Handling

```ruby
begin
  client.payments.collect(amount: 10_000, phone: "255712345678")
rescue Malipopay::AuthenticationError => e
  # Invalid API key (401)
rescue Malipopay::PermissionError => e
  # Insufficient permissions (403)
rescue Malipopay::NotFoundError => e
  # Resource not found (404)
rescue Malipopay::ValidationError => e
  # Invalid parameters (400/422)
  puts e.errors
rescue Malipopay::RateLimitError => e
  # Rate limited (429) - retry after e.retry_after seconds
rescue Malipopay::ApiError => e
  # Server error (5xx)
rescue Malipopay::ConnectionError => e
  # Network error
end
```

## Environments

| Environment  | Base URL                              |
|-------------|---------------------------------------|
| Production  | `https://core-prod.malipopay.co.tz`   |
| UAT         | `https://core-uat.malipopay.co.tz`    |

## Requirements

- Ruby >= 3.0
- Faraday ~> 2.0

## License

MIT License - Copyright (c) 2026 [Lockwood Technology Ltd](https://lockwood.co.tz)


---

## See Also

| SDK | Install |
|-----|---------|
| [Node.js](https://github.com/Malipopay/malipopay-node) | `npm install malipopay` |
| [Python](https://github.com/Malipopay/malipopay-python) | `pip install malipopay` |
| [PHP](https://github.com/Malipopay/malipopay-php) | `composer require malipopay/malipopay-php` |
| [Java](https://github.com/Malipopay/malipopay-java) | Maven / Gradle |
| [.NET](https://github.com/Malipopay/malipopay-dotnet) | `dotnet add package Malipopay` |
| [Ruby](https://github.com/Malipopay/malipopay-ruby) | `gem install malipopay` |

[API Reference](https://developers.malipopay.co.tz) | [OpenAPI Spec](https://github.com/Malipopay/malipopay-openapi) | [Test Scenarios](https://github.com/Malipopay/malipopay-sdk-tests)

