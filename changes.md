# changes

What shipped in malipopay-ruby and why, newest first, one entry per merged PR.

## 2026-11-08 · #2 · Release 1.1.1
**Why.** The webhook signature fix (#1) was merged to main but RubyGems still served 1.1.0, so merchants installing the gem kept the bug.
**What changed.** `Malipopay::VERSION` is 1.1.1. The gem's changelog link now points at this file (it pointed at a CHANGELOG.md that never existed).
**Related:** malipopay-ruby#1

## 2026-10-29 · #1 · Accept the sha256= prefix on X-Malipopay-Signature
**Why.** central-api sends `X-Malipopay-Signature: sha256=<hex>`, and the verifier compared the whole header against the bare hex digest, so every genuine webhook failed verification.
**What changed.** The verifier strips an optional `sha256=` prefix before the constant-time compare; a bare hex header still verifies.
**Memory:** ../memory/project_malipopay_webhook_signature.md
