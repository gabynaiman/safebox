require 'base64'
require 'openssl'
require 'securerandom'

require_relative 'secretbox/version'

class Secretbox

  ALGORITHM = 'aes-256-gcm'.freeze
  KEY_SIZE  = 32
  IV_SIZE   = 12
  TAG_SIZE  = 16

  class InvalidKeyError < StandardError; end
  class DecryptionError < StandardError; end

  def self.generate_key
    Base64.strict_encode64(SecureRandom.random_bytes(KEY_SIZE))
  end

  def initialize(key)
    validate_string! key, :key
    @key = decode_base64! key, :key, error: InvalidKeyError
    raise InvalidKeyError, "key must be #{KEY_SIZE} bytes" unless @key.bytesize == KEY_SIZE
  end

  def encrypt(plaintext, auth_data: '')
    validate_string! plaintext, :plaintext
    validate_string! auth_data, :auth_data

    cipher = OpenSSL::Cipher.new(ALGORITHM).tap(&:encrypt)
    iv     = cipher.random_iv
    cipher.key       = key
    cipher.auth_data = auth_data

    encrypted = cipher.update(plaintext) + cipher.final

    Base64.strict_encode64(iv + cipher.auth_tag + encrypted)
  end

  def decrypt(ciphertext, auth_data: '')
    validate_string! ciphertext, :ciphertext
    validate_string! auth_data,  :auth_data

    raw       = decode_base64! ciphertext, :ciphertext
    iv        = raw[0, IV_SIZE]
    auth_tag  = raw[IV_SIZE, TAG_SIZE]
    encrypted = raw[(IV_SIZE + TAG_SIZE)..-1]

    cipher = OpenSSL::Cipher.new(ALGORITHM).tap(&:decrypt)
    cipher.key       = key
    cipher.iv        = iv
    cipher.auth_tag  = auth_tag
    cipher.auth_data = auth_data

    cipher.update(encrypted) + cipher.final
  rescue OpenSSL::Cipher::CipherError => e
    raise DecryptionError, e.message
  end

  private

  attr_reader :key

  def validate_string!(value, name)
    raise TypeError, "#{name} must be a String, got #{value.class}" unless value.is_a?(String)
  end

  def decode_base64!(value, name, error: TypeError)
    Base64.strict_decode64(value)
  rescue ArgumentError
    raise error, "#{name} is not valid base64"
  end

end
