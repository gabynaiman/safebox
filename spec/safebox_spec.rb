require 'minitest_helper'

describe Safebox do

  let(:key)     { Safebox.generate_key }
  let(:safebox) { Safebox.new(key) }

  it 'encrypts and decrypts a string' do
    plaintext = 'secret message'
    safebox.decrypt(safebox.encrypt(plaintext)).must_equal plaintext
  end

  it 'encrypts and decrypts a JSON string' do
    plaintext = JSON.generate({ token: 'abc123', expires_at: 9999999999, expires: true })
    safebox.decrypt(safebox.encrypt(plaintext)).must_equal plaintext
  end

  it 'produces different ciphertexts for the same input' do
    plaintext   = 'same message'
    ciphertext1 = safebox.encrypt(plaintext)
    ciphertext2 = safebox.encrypt(plaintext)

    ciphertext1.wont_equal ciphertext2
  end

  it 'ciphertext does not contain the plaintext' do
    plaintext  = 'sensitive data'
    ciphertext = safebox.encrypt(plaintext)

    ciphertext.wont_include plaintext
  end

  it 'encrypts and decrypts with auth_data' do
    plaintext  = 'secret message'
    ciphertext = safebox.encrypt(plaintext, auth_data: 'context')

    safebox.decrypt(ciphertext, auth_data: 'context').must_equal plaintext
  end

  it 'raises TypeError when plaintext is not a String' do
    proc { safebox.encrypt(1) }.must_raise TypeError
    proc { safebox.encrypt(true) }.must_raise TypeError
    proc { safebox.encrypt(nil) }.must_raise TypeError
  end

  it 'raises TypeError when encrypt auth_data is not a String' do
    proc { safebox.encrypt('text', auth_data: 1) }.must_raise TypeError
  end

  it 'raises TypeError when ciphertext is not a String' do
    proc { safebox.decrypt(1) }.must_raise TypeError
  end

  it 'raises TypeError when decrypt auth_data is not a String' do
    ciphertext = safebox.encrypt('secret')
    proc { safebox.decrypt(ciphertext, auth_data: 1) }.must_raise TypeError
  end

  it 'raises InvalidKeyError when the key is not valid base64' do
    proc { Safebox.new('not-valid!!!') }.must_raise Safebox::InvalidKeyError
  end

  it 'raises InvalidKeyError when the key is not 32 bytes' do
    proc { Safebox.new(Base64.strict_encode64('tooshort')) }.must_raise Safebox::InvalidKeyError
  end

  it 'raises TypeError when the ciphertext is not valid base64' do
    proc { safebox.decrypt('not-valid-base64!!!') }.must_raise TypeError
  end

  it 'raises DecryptionError when decrypting with a different key' do
    other_safebox = Safebox.new(Safebox.generate_key)
    ciphertext    = safebox.encrypt('secret')

    proc { other_safebox.decrypt(ciphertext) }.must_raise Safebox::DecryptionError
  end

  it 'raises DecryptionError when decrypting with a different auth_data' do
    ciphertext = safebox.encrypt('secret', auth_data: 'context')

    proc { safebox.decrypt(ciphertext, auth_data: 'other') }.must_raise Safebox::DecryptionError
  end

  it 'raises DecryptionError when the ciphertext is tampered' do
    raw      = Base64.strict_decode64(safebox.encrypt('secret'))
    raw[-1]  = (raw[-1].ord ^ 0xFF).chr
    tampered = Base64.strict_encode64(raw)

    proc { safebox.decrypt(tampered) }.must_raise Safebox::DecryptionError
  end

end
