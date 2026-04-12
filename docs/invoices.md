# Invoices

The `invoices` resource lets you create, manage, and track invoices. Invoices can include line items with tax, and you can record payments against them as they come in.

## Create an Invoice

```ruby
invoice = client.invoices.create(
  customer_id: 'cust_abc123',
  currency: 'TZS',
  due_date: '2024-03-15',
  items: [
    {
      description: 'Website Development',
      quantity: 1,
      unit_price: 2_500_000
    },
    {
      description: 'Domain Registration (.co.tz)',
      quantity: 1,
      unit_price: 75_000
    },
    {
      description: 'Hosting (12 months)',
      quantity: 12,
      unit_price: 50_000
    }
  ],
  notes: 'Payment due within 15 days. M-Pesa and bank transfer accepted.',
  tax_rate: 18  # VAT at 18%
)

if invoice['success']
  puts "Invoice created: #{invoice['data']['id']}"
end
```

In this example, the subtotal is TZS 3,175,000 (2,500,000 + 75,000 + 600,000), and with 18% VAT the total would be TZS 3,746,500.

## Tax Calculation

MaliPoPay calculates tax automatically based on the `tax_rate` you provide:

```ruby
# Invoice with 18% VAT (Tanzania standard rate)
invoice = client.invoices.create(
  customer_id: 'cust_abc123',
  currency: 'TZS',
  due_date: '2024-04-30',
  items: [
    { description: 'Consulting (8 hours)', quantity: 8, unit_price: 150_000 }
  ],
  tax_rate: 18
)

# Subtotal: TZS 1,200,000
# VAT (18%): TZS 216,000
# Total: TZS 1,416,000
```

For tax-exempt invoices, omit the `tax_rate` field or set it to `0`:

```ruby
invoice = client.invoices.create(
  customer_id: 'cust_abc123',
  currency: 'TZS',
  due_date: '2024-04-30',
  items: [
    { description: 'Government service (exempt)', quantity: 1, unit_price: 500_000 }
  ],
  tax_rate: 0
)
```

## List Invoices

```ruby
invoices = client.invoices.list

if invoices['success']
  invoices['data'].each do |inv|
    puts "#{inv['id']}: TZS #{inv['total']} (#{inv['status']})"
  end
end
```

## Get an Invoice by ID

```ruby
invoice = client.invoices.get('inv_xyz789')

if invoice['success']
  puts "Invoice: #{invoice['data']}"
end
```

## Record a Payment Against an Invoice

When a customer makes a partial or full payment, record it against the invoice:

```ruby
# Record a partial payment
partial = client.invoices.record_payment(
  invoice_id: 'inv_xyz789',
  amount: 1_000_000,
  reference: 'MPESA-TXN-ABC123',
  payment_method: 'M-Pesa',
  notes: 'Partial payment received via M-Pesa'
)

# Later, record the remaining balance
final = client.invoices.record_payment(
  invoice_id: 'inv_xyz789',
  amount: 2_746_500,
  reference: 'CRDB-TXN-DEF456',
  payment_method: 'Bank Transfer',
  notes: 'Final payment via CRDB bank transfer'
)
```

## Approve a Draft Invoice

Invoices may start as drafts. Approve them when ready to send to the customer:

```ruby
approval = client.invoices.approve_draft(invoice_id: 'inv_draft_001')

if approval['success']
  puts 'Invoice approved and ready to send.'
end
```

## Invoice Workflow

A typical invoice lifecycle:

1. **Create** the invoice with line items and tax
2. **Approve** the draft (optional, depending on your workflow)
3. **Send** the invoice to the customer (via email, SMS, or payment link)
4. **Collect** payment using a mobile money collection or payment link
5. **Record** the payment against the invoice
6. Invoice status moves to **Paid** when the full amount is received

### Combining Invoices with Payment Collection

```ruby
# Step 1: Create the invoice
invoice = client.invoices.create(
  customer_id: 'cust_abc123',
  currency: 'TZS',
  due_date: '2024-02-28',
  items: [
    { description: 'Consulting (8 hours)', quantity: 8, unit_price: 150_000 }
  ]
)

# Step 2: Collect payment via M-Pesa
collection = client.payments.collect(
  amount: 1_200_000,
  currency: 'TZS',
  phone: '255712345678',
  provider: 'M-Pesa',
  reference: 'inv_xyz789',
  description: 'Invoice #INV-2024-0042 payment'
)

# Step 3: After webhook confirms payment, record it
record = client.invoices.record_payment(
  invoice_id: 'inv_xyz789',
  amount: 1_200_000,
  reference: 'MPESA-TXN-GHI789',
  payment_method: 'M-Pesa'
)
```

## Error Handling

```ruby
begin
  invoice = client.invoices.create(
    customer_id: 'nonexistent_customer',
    currency: 'TZS',
    items: [
      { description: 'Test', quantity: 1, unit_price: 1_000 }
    ]
  )
rescue MaliPoPay::ValidationError => e
  puts "Invalid invoice data: #{e.message}"
rescue MaliPoPay::NotFoundError
  puts 'Customer not found. Create the customer first.'
rescue MaliPoPay::Error => e
  puts "Invoice error: #{e.message}"
end
```

## Next Steps

- [Payments](./payments.md) -- collect payments for your invoices
- [Customers](./customers.md) -- manage the customers you invoice
- [Webhooks](./webhooks.md) -- get notified when payments are received
