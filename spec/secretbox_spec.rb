require 'minitest_helper'

describe Secretbox do

  let(:key)        { Secretbox.generate_key }
  let(:secretbox)  { Secretbox.new(key) }

  it 'encrypts and decrypts a string' do
    plaintext = 'secret message'
    secretbox.decrypt(secretbox.encrypt(plaintext)).must_equal plaintext
  end

  it 'encrypts and decrypts a JSON string' do
    plaintext = JSON.generate({ token: 'abc123', expires_at: 9999999999, expires: true })
    secretbox.decrypt(secretbox.encrypt(plaintext)).must_equal plaintext
  end

  it 'produces different ciphertexts for the same input' do
    plaintext   = 'same message'
    ciphertext1 = secretbox.encrypt(plaintext)
    ciphertext2 = secretbox.encrypt(plaintext)

    ciphertext1.wont_equal ciphertext2
  end

  it 'ciphertext does not contain the plaintext' do
    plaintext  = 'sensitive data'
    ciphertext = secretbox.encrypt(plaintext)

    ciphertext.wont_include plaintext
  end

  it 'encrypts and decrypts with auth_data' do
    plaintext  = 'secret message'
    ciphertext = secretbox.encrypt(plaintext, auth_data: 'context')

    secretbox.decrypt(ciphertext, auth_data: 'context').must_equal plaintext
  end

  it 'raises TypeError when plaintext is not a String' do
    proc { secretbox.encrypt(1) }.must_raise TypeError
    proc { secretbox.encrypt(true) }.must_raise TypeError
    proc { secretbox.encrypt(nil) }.must_raise TypeError
  end

  it 'raises TypeError when encrypt auth_data is not a String' do
    proc { secretbox.encrypt('text', auth_data: 1) }.must_raise TypeError
  end

  it 'raises TypeError when ciphertext is not a String' do
    proc { secretbox.decrypt(1) }.must_raise TypeError
  end

  it 'raises TypeError when decrypt auth_data is not a String' do
    ciphertext = secretbox.encrypt('secret')
    proc { secretbox.decrypt(ciphertext, auth_data: 1) }.must_raise TypeError
  end

  it 'raises InvalidKeyError when the key is not valid base64' do
    proc { Secretbox.new('not-valid!!!') }.must_raise Secretbox::InvalidKeyError
  end

  it 'raises InvalidKeyError when the key is not 32 bytes' do
    proc { Secretbox.new(Base64.strict_encode64('tooshort')) }.must_raise Secretbox::InvalidKeyError
  end

  it 'raises TypeError when the ciphertext is not valid base64' do
    proc { secretbox.decrypt('not-valid-base64!!!') }.must_raise TypeError
  end

  it 'raises DecryptionError when decrypting with a different key' do
    other_secretbox = Secretbox.new(Secretbox.generate_key)
    ciphertext      = secretbox.encrypt('secret')

    proc { other_secretbox.decrypt(ciphertext) }.must_raise Secretbox::DecryptionError
  end

  it 'raises DecryptionError when decrypting with a different auth_data' do
    ciphertext = secretbox.encrypt('secret', auth_data: 'context')

    proc { secretbox.decrypt(ciphertext, auth_data: 'other') }.must_raise Secretbox::DecryptionError
  end

  it 'raises DecryptionError when the ciphertext is tampered' do
    raw      = Base64.strict_decode64(secretbox.encrypt('secret'))
    raw[-1]  = (raw[-1].ord ^ 0xFF).chr
    tampered = Base64.strict_encode64(raw)

    proc { secretbox.decrypt(tampered) }.must_raise Secretbox::DecryptionError
  end

end
