# Secretbox Agent Guidelines

Guidelines for agents working on the secretbox gem.

## Ruby Version Support

The gem maintains **backward compatibility** from Ruby **2.3.8** to **3.4+**.

- **2.3.8–3.3**: Fully supported (tested in CI)
- **3.4+**: Fully supported (base64 added as explicit dependency)
- **4.0, JRuby-head**: Experimental (allow-failure in CI)

When adding features or fixing bugs:
1. Test locally with `RUBY_VERSION >= 2.3.8`
2. Never use syntax newer than Ruby 2.3 (e.g., safe navigation `&.`, pattern matching)
3. All dependencies must work on Ruby 2.3.8+
4. Special handling for Ruby 3.4+ (see `secretbox.gemspec` for `base64` conditional dependency)

## Code Style & Conventions

### No Comments
Do not add comments to explain code. The code must be self-documenting through:
- Meaningful method and variable names
- Clear algorithm flow
- Tests that serve as living documentation

Existing comments are minimal by design. Keep it that way.

### Private Methods
- Use `private` keyword to mark internal methods
- Access instance state through explicit `attr_reader` (never directly access `@key` outside the class)
- See `lib/secretbox.rb` for the pattern

### Constants
- Define at class level in UPPERCASE
- Freeze strings: `.freeze`
- Group related constants together (ALGORITHM, KEY_SIZE, IV_SIZE, TAG_SIZE)

### Error Classes
- Inherit from `StandardError`
- Define nested under the main class
- Use existing: `Secretbox::InvalidKeyError`, `Secretbox::DecryptionError`
- Add only if new error condition cannot fit existing types

### Method Signatures
- Use keyword arguments for optional parameters (e.g., `auth_data: ''`)
- Default empty string `''` for `auth_data`, not `nil`
- Type validation happens early via `validate_string!`

## Testing

- Test framework: **Minitest** with `minitest-great_expectations` DSL
- Test file location: `spec/secretbox_spec.rb`
- Pattern: `describe`, `let`, `it` with `.must_*` assertions
- Cover: happy path, errors, edge cases, type validation, tampering

Run tests:
```bash
bundle exec rake spec
```

Test filtering:
```bash
bundle exec rake spec NAME=encrypts  # runs tests matching "encrypts"
bundle exec rake spec TEST=spec/secretbox_spec.rb:12  # runs line 12
```

## Version Management

Versioning follows [Semantic Versioning](https://semver.org):

- **MAJOR.MINOR.PATCH** format
- Located in `lib/secretbox/version.rb`
- `Secretbox::VERSION = '1.0.0'`

Increment:
- **MAJOR**: Breaking changes (e.g., change method signature)
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes

Update version **before** committing changes.

## Git Conventions

### Commit Messages
All commits use **Conventional Commits** format:

```
type(scope): subject

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring (no behavior change)
- `test`: Test additions/updates
- `ci`: CI/CD workflow changes
- `chore`: Dependency updates, tooling
- `docs`: Documentation (though secretbox minimizes this)

**Scope:** (optional but recommended)
- `encrypt`, `decrypt`, `validation`, `compat`, `deps`

**Subject:**
- Lowercase, imperative mood ("add" not "adds" or "added")
- No period at the end
- Max 50 characters

**Examples:**
```
feat(encrypt): add support for empty plaintext
fix(decrypt): handle tampered ciphertext edge case
refactor: rename internal variable for clarity
test(validation): add type error cases
ci: add Ruby 3.4 to test matrix
chore(deps): update minitest to 5.20
```

### Branch Naming
While not enforced, follow this convention:
- `feat/description` for features
- `fix/description` for bug fixes
- `refactor/description` for refactoring

## File Structure

```
secretbox/
├── lib/secretbox.rb             # Main class (no nested require)
├── lib/secretbox/version.rb     # Version constant only
├── spec/secretbox_spec.rb       # All tests in one file
├── spec/minitest_helper.rb      # Setup (minimal)
├── spec/coverage_helper.rb      # SimpleCov config
├── secretbox.gemspec            # Gem metadata & dependencies
├── AGENT.md                      # This file
├── README.md                     # Usage guide
├── LICENSE.txt                   # MIT
└── .github/workflows/ci.yml      # CI matrix
```

Keep nested `lib/` structure minimal — only add new files if truly modular.

## Dependencies

### Runtime
- `base64`: Ruby 3.4+ only (OpenSSL handles it < 3.4)

### Development
- `rake`, `minitest`, `minitest-great_expectations`, `minitest-colorin`, `minitest-line`, `simplecov`
- Ruby 3.4+ only: `mutex_m`, `ostruct`

When adding dependencies:
1. Add to `secretbox.gemspec`
2. Document why (comment in gemspec)
3. Ensure Ruby 2.3.8 compatibility
4. Test in CI (already covers 2.3–3.4)

## Key Implementation Details

### Ciphertext Format
Base64-encoded: `iv (12 bytes) + auth_tag (16 bytes) + encrypted_data`

This format is **not changing**. If you need to support multiple formats, add a version byte inside the raw bytes.

### Algorithm
- **Cipher:** AES-256-GCM
- **IV size:** 12 bytes (nonce) — always random
- **Key size:** 32 bytes (256 bits)
- **Auth tag size:** 16 bytes (128 bits)
- **Auth data:** Authenticated but not encrypted

### Validation
- `validate_string!`: Type check (raises `TypeError`)
- `decode_base64!`: Decoding and error wrapping (raises `InvalidKeyError` or `TypeError`)
- Never validate inside the cipher calls — do it upfront

## Before Committing

1. ✅ Run tests: `bundle exec rake spec`
2. ✅ All tests pass on Ruby 2.3.8, 3.2, 3.4
3. ✅ Update `lib/secretbox/version.rb` if behavior changes
4. ✅ Commit with **Conventional Commits** format
5. ✅ No comments added to code
6. ✅ All new methods have test coverage

## Running Locally

```bash
cd /path/to/secretbox

# Install dependencies
bundle install

# Run tests
bundle exec rake spec

# Run tests with coverage
COVERAGE=true bundle exec rake spec

# Open IRB console with secretbox loaded
bundle exec rake console
```

## Questions?

Refer to:
- Implementation: `lib/secretbox.rb`
- Tests: `spec/secretbox_spec.rb`
- Gem metadata: `secretbox.gemspec`
- CI config: `.github/workflows/ci.yml`
