# Webhooks

Webhooks let you receive real-time notifications when events happen in Malipopay -- payment completed, payment failed, disbursement processed, etc. Instead of polling the API, you register a URL and Malipopay sends HTTP POST requests to it.

## How Webhooks Work

1. You register a webhook URL in your Malipopay dashboard at [app.malipopay.co.tz](https://app.malipopay.co.tz) under **Settings > Webhooks**
2. Malipopay generates a **webhook signing secret** for you
3. When an event occurs, Malipopay sends a POST request to your URL with:
   - The event payload as JSON in the request body
   - An `X-Malipopay-Signature` header containing the HMAC-SHA256 signature
4. Your endpoint verifies the signature and processes the event

## Event Types

| Event | Description |
|-------|-------------|
| `payment.completed` | A collection was successfully completed |
| `payment.failed` | A collection failed (timeout, insufficient funds, cancelled) |
| `disbursement.completed` | A disbursement was sent successfully |
| `disbursement.failed` | A disbursement failed |
| `invoice.paid` | An invoice was fully paid |
| `invoice.partially_paid` | A partial payment was recorded |

## Sinatra Webhook Endpoint

A lightweight webhook endpoint using Sinatra:

```ruby
require 'sinatra'
require 'json'
require 'malipopay'

WEBHOOK_SECRET = ENV.fetch('MALIPOPAY_WEBHOOK_SECRET')
verifier = Malipopay::Webhooks::Verifier.new(WEBHOOK_SECRET)

post '/webhooks/malipopay' do
  payload = request.body.read
  signature = request.env['HTTP_X_MALIPOPAY_SIGNATURE']

  unless signature
    halt 400, 'Missing signature'
  end

  begin
    event = verifier.construct_event(payload, signature)

    case event['event_type']
    when 'payment.completed'
      puts "Payment completed: #{event['reference']}, Amount: TZS #{event['amount']}"
      # Update your order/invoice status in the database

    when 'payment.failed'
      puts "Payment failed: #{event['reference']}, Reason: #{event['reason']}"
      # Notify the customer, retry, or cancel the order

    when 'disbursement.completed'
      puts "Disbursement sent: #{event['reference']}"

    else
      puts "Unhandled event type: #{event['event_type']}"
    end

    status 200
    'OK'
  rescue Malipopay::Error => e
    puts "Webhook verification failed: #{e.message}"
    halt 401, 'Invalid signature'
  end
end
```

## Rails Controller Example

A full Rails controller for handling Malipopay webhooks:

```ruby
# app/controllers/webhooks/malipopay_controller.rb
module Webhooks
  class MalipopayController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      signature = request.headers['X-Malipopay-Signature']

      unless signature.present?
        render json: { error: 'Missing signature' }, status: :bad_request
        return
      end

      begin
        event = webhook_verifier.construct_event(payload, signature)
        handle_event(event)
        head :ok
      rescue Malipopay::Error => e
        Rails.logger.error("Webhook verification failed: #{e.message}")
        head :unauthorized
      end
    end

    private

    def webhook_verifier
      @webhook_verifier ||= Malipopay::Webhooks::Verifier.new(
        ENV.fetch('MALIPOPAY_WEBHOOK_SECRET')
      )
    end

    def handle_event(event)
      case event['event_type']
      when 'payment.completed'
        handle_payment_completed(event)
      when 'payment.failed'
        handle_payment_failed(event)
      when 'disbursement.completed'
        Rails.logger.info("Disbursement completed: #{event['reference']}")
      when 'invoice.paid'
        handle_invoice_paid(event)
      else
        Rails.logger.info("Unhandled webhook event: #{event['event_type']}")
      end
    end

    def handle_payment_completed(event)
      Rails.logger.info(
        "Payment completed: #{event['reference']}, " \
        "Amount: TZS #{event['amount']}"
      )

      # Update your order status
      order = Order.find_by(reference: event['reference'])
      order&.mark_as_paid!(
        transaction_id: event['transaction_id'],
        provider: event['provider']
      )
    end

    def handle_payment_failed(event)
      Rails.logger.warn(
        "Payment failed: #{event['reference']}, " \
        "Reason: #{event['reason']}"
      )

      order = Order.find_by(reference: event['reference'])
      order&.mark_as_failed!(reason: event['reason'])
    end

    def handle_invoice_paid(event)
      invoice = Invoice.find_by(external_id: event['reference'])
      invoice&.mark_as_paid!
    end
  end
end
```

Add the route in `config/routes.rb`:

```ruby
namespace :webhooks do
  post 'malipopay', to: 'malipopay#create'
end
```

## Signature Verification

Every webhook request includes an `X-Malipopay-Signature` header. The signature is an HMAC-SHA256 hash of the raw request body, signed with your webhook secret.

The `Malipopay::Webhooks::Verifier` handles this for you:

```ruby
verifier = Malipopay::Webhooks::Verifier.new('your_webhook_secret')

# Just verify (returns true/false)
valid = verifier.verify(payload, signature)

# Verify and parse in one step (raises on failure)
event = verifier.construct_event(payload, signature)
```

### Manual Verification

If you need to verify the signature manually without using the SDK:

```ruby
require 'openssl'

def verify_manually(payload, signature, secret)
  expected = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
  Rack::Utils.secure_compare(expected, signature)
end
```

## Best Practices

1. **Always verify signatures.** Never process a webhook without checking the signature. This prevents spoofed requests.

2. **Return 200 quickly.** Process the event asynchronously if needed (e.g., with Sidekiq or ActiveJob). Malipopay expects a response within 30 seconds. If you don't return 200, the webhook will be retried.

3. **Handle duplicates.** Webhooks may be delivered more than once. Use the `reference` or `transaction_id` as an idempotency key.

4. **Log everything.** Log the raw payload and event type for debugging and audit trails.

5. **Use HTTPS.** Your webhook endpoint must be accessible over HTTPS in production.

6. **Process asynchronously in Rails.** Offload heavy work to a background job:

```ruby
def handle_payment_completed(event)
  PaymentCompletedJob.perform_later(event.to_json)
  # Return 200 immediately -- the job processes the event
end
```

## Next Steps

- [Error Handling](./error-handling.md) -- handle webhook verification failures
- [Payments](./payments.md) -- understand the payment flow that triggers webhooks
- [Configuration](./configuration.md) -- client setup
