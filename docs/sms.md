# SMS

The `sms` resource lets you send transactional and promotional SMS messages to Tanzanian phone numbers. You can send single messages, bulk messages to multiple recipients, and schedule messages for future delivery.

## Sending a Single SMS

```ruby
sms = client.sms.send_message(
  to: '255712345678',
  message: 'Your payment of TZS 50,000 has been confirmed. Reference: ORD-2024-100. Thank you for shopping with us!',
  sender_id: 'MALIPOPAY'
)

if sms['success']
  puts "SMS sent: #{sms['data']}"
else
  puts "Failed: #{sms['message']}"
end
```

### With Error Handling

```ruby
begin
  sms = client.sms.send_message(
    to: '255754321098',
    message: 'Dear Amina, your invoice INV-2024-042 of TZS 3,746,500 is due on 15 March 2024. Pay via M-Pesa to avoid late fees.',
    sender_id: 'ACME'
  )

  puts "Message delivered: #{sms['data']}"
rescue MaliPoPay::ValidationError => e
  puts "Invalid request: #{e.message}"
rescue MaliPoPay::Error => e
  puts "SMS error: #{e.message}"
end
```

## Bulk SMS

Send the same message or different messages to multiple recipients at once.

### Same Message to Multiple Recipients

```ruby
bulk = client.sms.send_bulk(
  recipients: [
    '255712345678',
    '255754321098',
    '255622345678',
    '255652345678',
    '255742345678'
  ],
  message: 'Reminder: Our office will be closed on Monday 1st January for the New Year holiday. Happy New Year from ACME Ltd!',
  sender_id: 'ACME'
)

if bulk['success']
  puts "Bulk SMS sent to #{bulk['data']} recipients"
end
```

### Individual Messages per Recipient

```ruby
personalized = client.sms.send_bulk(
  messages: [
    {
      to: '255712345678',
      message: 'Hi Juma, your account balance is TZS 125,000. Login at app.malipopay.co.tz to view details.'
    },
    {
      to: '255754321098',
      message: 'Hi Amina, your account balance is TZS 340,500. Login at app.malipopay.co.tz to view details.'
    },
    {
      to: '255622345678',
      message: 'Hi Baraka, your account balance is TZS 78,200. Login at app.malipopay.co.tz to view details.'
    }
  ],
  sender_id: 'ACME'
)
```

## Scheduling SMS

Schedule messages for future delivery by providing a `scheduled_at` timestamp in ISO 8601 format. All times are in East Africa Time (EAT, UTC+3):

```ruby
# Schedule a payment reminder for 9:00 AM tomorrow
scheduled = client.sms.send_message(
  to: '255712345678',
  message: 'Reminder: Your subscription of TZS 15,000 is due tomorrow. Pay now via M-Pesa to avoid interruption.',
  sender_id: 'ACME',
  scheduled_at: '2024-03-15T09:00:00+03:00'
)

if scheduled['success']
  puts "SMS scheduled: #{scheduled['data']}"
end
```

### Schedule Bulk SMS

```ruby
# Schedule a promotional message for Friday at 2:00 PM
scheduled_bulk = client.sms.send_bulk(
  recipients: [
    '255712345678',
    '255754321098',
    '255652345678'
  ],
  message: 'Weekend offer! Get 20% off all services this Saturday and Sunday. Visit our shop on Samora Avenue or pay via M-Pesa. Code: WEEKEND20',
  sender_id: 'ACME',
  scheduled_at: '2024-03-15T14:00:00+03:00'
)
```

## Sender IDs

The `sender_id` field controls what appears as the sender on the recipient's phone. This is the name or short code displayed instead of a phone number.

| Sender ID | Description |
|-----------|-------------|
| `MALIPOPAY` | Default MaliPoPay sender ID |
| Custom (e.g., `ACME`) | Your registered brand name |

### Registering a Custom Sender ID

Custom sender IDs must be registered and approved in your MaliPoPay dashboard:

1. Go to [app.malipopay.co.tz](https://app.malipopay.co.tz) > **Settings > SMS > Sender IDs**
2. Click **Request New Sender ID**
3. Enter your desired sender name (up to 11 characters, alphanumeric)
4. Submit for approval -- this typically takes 24-48 hours

> **Note:** TCRA regulations in Tanzania require sender IDs to be registered. Unregistered sender IDs will be replaced with a default numeric sender.

## SMS Character Limits

Standard SMS messages have a 160-character limit per segment. Messages longer than 160 characters are split into multiple segments and reassembled on the recipient's device:

| Length | Segments | Effective Characters per Segment |
|--------|----------|----------------------------------|
| 1--160 | 1 | 160 |
| 161--306 | 2 | 153 (7 bytes used for concatenation header) |
| 307--459 | 3 | 153 |

Billing is per segment. Keep messages concise to minimize costs.

## Complete Example: Payment Confirmation SMS

A common pattern is sending an SMS after a successful payment webhook:

```ruby
# In your Sinatra/Rails webhook handler
post '/webhooks/malipopay' do
  # ... verify signature (see Webhooks guide) ...

  event = verifier.construct_event(payload, signature)

  if event['event_type'] == 'payment.completed'
    client.sms.send_message(
      to: event['phone'],
      message: "Payment confirmed! TZS #{event['amount']} received for #{event['reference']}. " \
               "Transaction ID: #{event['transaction_id']}. Thank you!",
      sender_id: 'ACME'
    )

    puts "Confirmation SMS sent to #{event['phone']}"
  end

  status 200
end
```

## Next Steps

- [Payments](./payments.md) -- collect payments that trigger SMS notifications
- [Webhooks](./webhooks.md) -- automate SMS sending from webhook events
- [Error Handling](./error-handling.md) -- handle SMS delivery failures
- [Configuration](./configuration.md) -- configure timeouts and retries
