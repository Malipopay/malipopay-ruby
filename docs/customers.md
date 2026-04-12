# Customers

The `customers` resource lets you create, retrieve, search, and verify customer records. Customers are linked to payments, invoices, and transaction history in MaliPoPay.

## Create a Customer

```ruby
customer = client.customers.create(
  name: 'Juma Bakari',
  phone: '255712345678',
  email: 'juma.bakari@example.com',
  address: 'Plot 45, Samora Avenue, Dar es Salaam',
  customer_type: 'individual',
  notes: 'Preferred payment method: M-Pesa'
)

if customer['success']
  puts "Customer created: #{customer['data']['id']}"
end
```

### Create a Business Customer

```ruby
business = client.customers.create(
  name: 'Kilimanjaro Trading Co.',
  phone: '255222123456',
  email: 'accounts@kilitrade.co.tz',
  address: 'Industrial Area, Arusha',
  customer_type: 'business',
  tin: '123-456-789',
  notes: 'Net 30 payment terms'
)
```

## List All Customers

```ruby
customers = client.customers.list

if customers['success']
  customers['data'].each do |c|
    puts "#{c['name']} (#{c['phone']})"
  end
end
```

## Get a Customer by ID

```ruby
customer = client.customers.get('cust_abc123')

if customer['success']
  puts "Name: #{customer['data']['name']}"
  puts "Phone: #{customer['data']['phone']}"
  puts "Email: #{customer['data']['email']}"
end
```

## Get a Customer by Phone Number

Look up a customer using their phone number:

```ruby
customer = client.customers.get_by_phone('255712345678')

if customer['success']
  puts "Found: #{customer['data']['name']}"
end
```

## Get a Customer by Customer Number

Look up using the MaliPoPay-assigned customer number:

```ruby
customer = client.customers.get_by_number('CUST-2024-001')

if customer['success']
  puts "Found: #{customer['data']['name']}"
end
```

## Search Customers

Search by name, phone, email, or other fields:

```ruby
results = client.customers.search

if results['success']
  puts "Found #{results['data'].length} customers"
end
```

## Verify a Customer

Customer verification is useful for KYC (Know Your Customer) compliance. This checks the customer's identity against the phone number or ID document registered with their mobile money provider:

```ruby
verification = client.customers.verify(
  phone: '255712345678',
  provider: 'M-Pesa'
)

if verification['success']
  puts "Verified: #{verification['data']}"
else
  puts "Verification failed: #{verification['message']}"
end
```

## Error Handling

```ruby
begin
  customer = client.customers.create(
    name: 'Incomplete Customer'
    # missing phone -- will trigger validation error
  )
rescue MaliPoPay::ValidationError => e
  puts "Missing required fields: #{e.message}"
rescue MaliPoPay::NotFoundError
  puts 'Customer not found.'
rescue MaliPoPay::Error => e
  puts "Error: #{e.message}"
end
```

## Next Steps

- [Invoices](./invoices.md) -- create invoices for your customers
- [Payments](./payments.md) -- collect payments from customers
