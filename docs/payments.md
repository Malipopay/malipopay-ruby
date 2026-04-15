# Payments

The `payments` resource handles all payment operations: mobile money collections, disbursements, payment verification, payment links, and search.

## How Payments Work in Tanzania

Malipopay integrates with Tanzania's major mobile money and banking networks:

- **Vodacom M-Pesa** -- largest mobile money network
- **Airtel Money** -- second-largest MNO
- **Tigo Pesa (Mixx by Yas)** -- merged MNO brand
- **Halotel Halopesa** -- growing rural network
- **TTCL T-Pesa** -- state telco mobile money
- **USSD (*146*08#)** -- unified USSD payment channel
- **Bank transfers** -- CRDB, NMB, and other banks via H2H integration
- **Card payments** -- Visa and Mastercard

### Collection Flow

1. Your app calls `collect` with the customer's phone number and amount
2. Malipopay sends a USSD push to the customer's phone
3. The customer sees a prompt like: *"Pay TZS 50,000 to ACME Ltd? Enter PIN to confirm"*
4. The customer enters their mobile money PIN
5. Malipopay receives the confirmation and notifies you via webhook
6. You can also poll using `verify`

### Disbursement Flow

1. Your app calls `disburse` with the recipient's phone/account and amount
2. Malipopay processes the transfer from your merchant float
3. The recipient receives the funds in their mobile money or bank account
4. You receive a webhook notification with the result

## Mobile Money Collection

Collect payments from any supported mobile money provider:

```ruby
# M-Pesa collection
mpesa = client.payments.collect(
  amount: 75_000,
  currency: 'TZS',
  phone: '255712345678',
  provider: 'M-Pesa',
  reference: 'INV-2024-0042',
  description: 'Invoice payment - Office furniture'
)

# Airtel Money collection
airtel = client.payments.collect(
  amount: 25_000,
  currency: 'TZS',
  phone: '255782345678',
  provider: 'Airtel Money',
  reference: 'INV-2024-0043',
  description: 'Delivery fee'
)

# Halopesa collection
halo = client.payments.collect(
  amount: 10_000,
  currency: 'TZS',
  phone: '255622345678',
  provider: 'Halopesa',
  reference: 'INV-2024-0044',
  description: 'Service charge'
)

# Tigo Pesa / Mixx by Yas collection
tigo = client.payments.collect(
  amount: 35_000,
  currency: 'TZS',
  phone: '255652345678',
  provider: 'Mixx',
  reference: 'INV-2024-0045',
  description: 'Consultation fee'
)

# T-Pesa collection
tpesa = client.payments.collect(
  amount: 20_000,
  currency: 'TZS',
  phone: '255742345678',
  provider: 'T-Pesa',
  reference: 'INV-2024-0046',
  description: 'Registration fee'
)
```

## Card Payments

Collect payments via Visa or Mastercard:

```ruby
card = client.payments.collect(
  amount: 150_000,
  currency: 'TZS',
  provider: 'Card',
  reference: 'INV-2024-0050',
  description: 'Annual membership',
  customer_email: 'juma@example.com',
  redirect_url: 'https://yoursite.co.tz/payment/success'
)

# The result includes a checkout URL for the customer
puts "Redirect customer to: #{card['checkout_url']}"
```

## Disbursement

Send money to mobile money wallets or bank accounts:

```ruby
# Disburse to M-Pesa wallet
disbursement = client.payments.disburse(
  amount: 150_000,
  currency: 'TZS',
  phone: '255712345678',
  provider: 'M-Pesa',
  reference: 'PAYOUT-2024-001',
  description: 'Salary payment - January 2024'
)

# Disburse to bank account (CRDB)
bank_disbursement = client.payments.disburse(
  amount: 500_000,
  currency: 'TZS',
  account_number: '01J1234567890',
  bank_code: 'CRDB',
  account_name: 'Juma Hassan',
  reference: 'PAYOUT-2024-002',
  description: 'Vendor payment'
)

# Disburse to NMB account
nmb_disbursement = client.payments.disburse(
  amount: 2_500_000,
  currency: 'TZS',
  account_number: '2345678901',
  bank_code: 'NMB',
  account_name: 'Maria Joseph',
  reference: 'PAYOUT-2024-003',
  description: 'Contractor payout'
)
```

## Payment Verification

After initiating a collection, verify the payment status. In production you should rely on webhooks, but polling is useful for synchronous flows and reconciliation:

```ruby
# Verify by reference
status = client.payments.verify('INV-2024-0042')

if status['success']
  puts "Payment status: #{status['status']}"
end
```

### Polling with Timeout

For cases where you need to wait for the customer to complete the payment:

```ruby
def wait_for_payment(client, reference, timeout: 120, interval: 5)
  deadline = Time.now + timeout

  while Time.now < deadline
    result = client.payments.verify(reference)

    return true if result['status'] == 'completed'
    return false if result['status'] == 'failed'

    sleep interval
  end

  false # timed out
end

# Wait up to 2 minutes, polling every 5 seconds
paid = wait_for_payment(client, 'INV-2024-0042')
```

> **Recommendation:** Use webhooks instead of polling in production. Polling is acceptable for testing, CLI tools, and reconciliation scripts.

## Payment Links

Generate a shareable payment link that customers can use to pay via any supported method:

```ruby
link = client.payments.pay(
  amount: 250_000,
  currency: 'TZS',
  reference: 'LINK-2024-001',
  description: 'Annual membership fee',
  customer_name: 'Asha Mwalimu',
  customer_email: 'asha@example.com',
  customer_phone: '255712345678',
  redirect_url: 'https://yoursite.co.tz/payment/success',
  callback_url: 'https://yoursite.co.tz/api/webhooks/malipopay'
)

puts "Send this link to the customer: #{link['payment_url']}"
```

## Retry Failed Collections

If a collection failed due to a transient issue (timeout, network error), you can retry it:

```ruby
retry_result = client.payments.retry('INV-2024-0042')

if retry_result['success']
  puts 'Collection retry initiated. Customer will receive a new USSD push.'
end
```

## List and Search Payments

### List All Payments

```ruby
payments = client.payments.list

if payments['success']
  puts "Total payments: #{payments['data'].length}"
end
```

### Search Payments

```ruby
results = client.payments.search
```

### Get Payment by Reference

```ruby
payment = client.payments.get_by_reference('INV-2024-0042')

if payment['success']
  puts "Amount: #{payment['data']['amount']}"
  puts "Status: #{payment['data']['status']}"
  puts "Provider: #{payment['data']['provider']}"
end
```

## Error Handling for Payments

Always wrap payment operations in begin/rescue:

```ruby
begin
  result = client.payments.collect(
    amount: 50_000,
    currency: 'TZS',
    phone: '255712345678',
    provider: 'M-Pesa',
    reference: 'ORDER-001',
    description: 'Test payment'
  )
rescue Malipopay::ValidationError => e
  # Invalid parameters (wrong phone format, missing fields, etc.)
  puts "Validation error: #{e.message}"
rescue Malipopay::AuthenticationError
  # Bad API key
  puts 'Check your API key.'
rescue Malipopay::RateLimitError
  # Too many requests -- back off and retry
  puts 'Rate limited. Please wait and retry.'
rescue Malipopay::ConnectionError => e
  # Network issue
  puts "Network error: #{e.message}"
rescue Malipopay::Error => e
  # Catch-all for other SDK errors
  puts "Payment error: #{e.message}"
end
```

## Next Steps

- [Webhooks](./webhooks.md) -- receive real-time payment status updates
- [Invoices](./invoices.md) -- create invoices and record payments against them
- [Error Handling](./error-handling.md) -- comprehensive error handling patterns
