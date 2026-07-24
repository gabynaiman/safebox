# Safebox

[![Gem Version](https://badge.fury.io/rb/safebox.svg)](https://rubygems.org/gems/safebox)
[![CI](https://github.com/gabynaiman/safebox/actions/workflows/ci.yml/badge.svg)](https://github.com/gabynaiman/safebox/actions/workflows/ci.yml)

AES-256-GCM authenticated encryption for sensitive data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'safebox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install safebox

## Usage

### Generate a key

```ruby
key = Safebox.generate_key # => base64 String (32 random bytes)
```

Store the key in an environment variable (e.g. `SAFEBOX_KEY`).

### Encrypt and decrypt

```ruby
safebox = Safebox.new(ENV.fetch('SAFEBOX_KEY'))

ciphertext = safebox.encrypt('secret message')
safebox.decrypt(ciphertext) # => 'secret message'
```

### With authenticated associated data (AAD)

```ruby
ciphertext = safebox.encrypt('secret', auth_data: 'user:42')
safebox.decrypt(ciphertext, auth_data: 'user:42') # => 'secret'

safebox.decrypt(ciphertext, auth_data: 'user:99') # raises Safebox::DecryptionError
```

The `auth_data` is not encrypted but is authenticated — any tampering with it
causes decryption to fail. Use it to bind ciphertext to context (e.g. a record ID).

### Encrypting structured data

```ruby
settings = { api_key: 'abc123', token: 'xyz' }
ciphertext = safebox.encrypt(JSON.generate(settings))

JSON.parse(safebox.decrypt(ciphertext), symbolize_names: true) # => { api_key: 'abc123', token: 'xyz' }
```

## Errors

| Error | When |
|---|---|
| `Safebox::InvalidKeyError` | Key is not valid base64 or not 32 bytes |
| `Safebox::DecryptionError` | Ciphertext is tampered, key is wrong, or auth_data mismatches |
| `TypeError` | plaintext/ciphertext/auth_data is not a String |

## Ciphertext format

Base64-encoded: `iv (12 bytes) + auth_tag (16 bytes) + encrypted_data`

## License

MIT
