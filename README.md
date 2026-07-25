# Secretbox

[![Gem Version](https://badge.fury.io/rb/secretbox.svg)](https://rubygems.org/gems/secretbox)
[![CI](https://github.com/gabynaiman/secretbox/actions/workflows/ci.yml/badge.svg)](https://github.com/gabynaiman/secretbox/actions/workflows/ci.yml)

AES-256-GCM authenticated encryption for sensitive data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'secretbox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install secretbox

## Usage

### Generate a key

```ruby
key = Secretbox.generate_key # => base64 String (32 random bytes)
```

Store the key in an environment variable (e.g. `SECRETBOX_KEY`).

### Encrypt and decrypt

```ruby
secretbox = Secretbox.new(ENV.fetch('SECRETBOX_KEY'))

ciphertext = secretbox.encrypt('secret message')
secretbox.decrypt(ciphertext) # => 'secret message'
```

### With authenticated associated data (AAD)

```ruby
ciphertext = secretbox.encrypt('secret', auth_data: 'user:42')
secretbox.decrypt(ciphertext, auth_data: 'user:42') # => 'secret'

secretbox.decrypt(ciphertext, auth_data: 'user:99') # raises Secretbox::DecryptionError
```

The `auth_data` is not encrypted but is authenticated — any tampering with it
causes decryption to fail. Use it to bind ciphertext to context (e.g. a record ID).

### Encrypting structured data

```ruby
settings = { api_key: 'abc123', token: 'xyz' }
ciphertext = secretbox.encrypt(JSON.generate(settings))

JSON.parse(secretbox.decrypt(ciphertext), symbolize_names: true) # => { api_key: 'abc123', token: 'xyz' }
```

## Errors

| Error | When |
|---|---|
| `Secretbox::InvalidKeyError` | Key is not valid base64 or not 32 bytes |
| `Secretbox::DecryptionError` | Ciphertext is tampered, key is wrong, or auth_data mismatches |
| `TypeError` | plaintext/ciphertext/auth_data is not a String |

## Ciphertext format

Base64-encoded: `iv (12 bytes) + auth_tag (16 bytes) + encrypted_data`

## License

MIT
