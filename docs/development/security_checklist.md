# Security Checklist - Prevent Secret Leaks

## Overview

This document provides mandatory security checks to prevent accidental exposure of credentials, API keys, passwords, and other sensitive information in the codebase.

## ❌ GitGuardian Alert History

### January 7, 2025 - SMTP Credentials False Positive
- **Alert**: GitGuardian flagged "SMTP credentials" in repository
- **Root Cause**: Documentation placeholder `SMTP_PASSWORD=sendgrid_api_key_here` triggered pattern matching
- **Resolution**: Updated to `<YOUR_SENDGRID_API_KEY_HERE>` format
- **Impact**: No real credentials were exposed - false positive on example text

## 🔒 MANDATORY Pre-Push Security Checks

**EVERY AI assistant and developer MUST run these checks before `git push`:**

### 1. Staged Changes Scan
```bash
# Check for credentials in files being committed
git diff --cached | grep -iE "(password|secret|key|token|credential|smtp|api_key)" || echo "✅ No secrets in staged files"

# Check for email addresses that might be real
git diff --cached | grep -iE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" | grep -v "example.com\|proteinprices.com\|noreply@\|admin@" && echo "❌ Check real email addresses" || echo "✅ No real emails"
```

### 2. Commit Message Scan  
```bash
# Ensure commit messages don't contain secrets
git log --oneline -1 | grep -iE "(password|secret|key|token|credential)" && echo "❌ Credentials in commit message" || echo "✅ Clean commit message"
```

### 3. Documentation Placeholder Validation
```bash
# Verify docs use proper placeholder format
grep -r "password.*=.*[a-z_]*here" docs/ && echo "❌ Use <YOUR_*_HERE> format" || echo "✅ Proper placeholders"

# Check for SendGrid patterns specifically (GitGuardian sensitive)
grep -r "sendgrid.*key.*here" . && echo "❌ Update SendGrid placeholders" || echo "✅ SendGrid placeholders safe"
```

### 4. Environment File Verification
```bash
# Check for .env files accidentally staged
git diff --cached --name-only | grep -E "\.env$|\.env\..*$" && echo "❌ .env files should not be committed" || echo "✅ No .env files"
```

## 📝 Placeholder Standards

### ✅ CORRECT Formats (GitGuardian Safe)
```bash
# Database credentials
DB_PASSWORD=<YOUR_SECURE_DATABASE_PASSWORD>
DB_USER=<YOUR_DATABASE_USERNAME>

# API Keys  
SENDGRID_API_KEY=<YOUR_SENDGRID_API_KEY>
OPENAI_API_KEY=<YOUR_OPENAI_API_KEY>

# OAuth Credentials
GOOGLE_CLIENT_SECRET=<YOUR_GOOGLE_CLIENT_SECRET>
GITHUB_CLIENT_SECRET=<YOUR_GITHUB_CLIENT_SECRET>

# SMTP Configuration
SMTP_PASSWORD=<YOUR_SENDGRID_API_KEY_HERE>
SMTP_USERNAME=<YOUR_SMTP_USERNAME>

# JWT Secrets
JWT_SECRET=<YOUR_JWT_SECRET_KEY>
REFRESH_TOKEN_SECRET=<YOUR_REFRESH_TOKEN_SECRET>
```

### ❌ WRONG Formats (GitGuardian Triggers)
```bash
# These patterns trigger false positives:
DB_PASSWORD=secure_password_here          # ❌ Looks like real credential
SENDGRID_API_KEY=sendgrid_api_key_here    # ❌ Triggers SMTP detection
GOOGLE_CLIENT_SECRET=your_secret_here     # ❌ Pattern matches real format
JWT_SECRET=your_jwt_secret               # ❌ Looks like weak real secret

# Avoid example emails that look real:
ADMIN_EMAIL=admin@yourcompany.com         # ❌ Use admin@example.com instead
SUPPORT_EMAIL=support@myapp.io           # ❌ Use support@example.com instead
```

## 🛡️ Pre-commit Hook Configuration

Add this to `.pre-commit-config.yaml` to automate secret detection:

```yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: main
    hooks:
      - id: trufflehog
        name: TruffleHog Secret Detection
        args: ['--regex', '--entropy=False', '--exclude_paths=.trufflehog-exclude']
        
  - repo: local
    hooks:
      - id: credential-check
        name: Documentation Credential Check
        entry: bash -c 'grep -r "password.*=.*[a-z_]*here" docs/ && exit 1 || exit 0'
        language: system
        files: ^docs/.*\.md$
```

Create `.trufflehog-exclude` file:
```
# Exclude legitimate files
docs/development/security_checklist.md
*.test.go
```

## 🔍 GitGuardian Integration

### Understanding GitGuardian Alerts
- **True Positive**: Real credentials accidentally committed
- **False Positive**: Pattern matching on documentation examples
- **Common Triggers**: 
  - `SMTP_USERNAME=apikey` + `SMTP_HOST=smtp.sendgrid.net` (SendGrid pattern)
  - `password=anything_with_here` (looks like placeholder leak)
  - Email patterns: `admin@domain.com` in configuration examples

### Alert Response Process
1. **Immediate**: Check if credentials are real or placeholder
2. **If Real**: Rotate credentials immediately, check access logs
3. **If Placeholder**: Update to safe format `<YOUR_*_HERE>`
4. **Document**: Update this file with alert details and resolution

## 🚀 AI Assistant Guidelines

### Before ANY Code Changes
1. Scan existing files for credential patterns
2. Use only approved placeholder formats
3. Never commit real API keys, even for testing

### Documentation Writing
1. Always use `<YOUR_*_HERE>` format for secrets
2. Use `example.com` for email examples
3. Comment clearly: `# Replace with actual values in production`

### Environment Variables
1. Use `.env.example` files with placeholders
2. Never commit actual `.env` files
3. Document all required environment variables

## 📊 Security Metrics

Track these metrics to improve security posture:

- **GitGuardian Alerts**: Target 0 true positives per month
- **Pre-commit Hook Coverage**: 100% of commits scanned
- **Documentation Compliance**: 100% use correct placeholder format
- **False Positive Rate**: <1% of total alerts

## 🔧 Tools & Automation

### Required Tools
- **TruffleHog**: Local secret scanning
- **GitGuardian**: Repository monitoring (already enabled)
- **pre-commit**: Automated validation hooks
- **GitHub Secret Scanning**: Built-in GitHub protection

### IDE Integration
Configure your IDE to highlight potential secrets:
- VS Code: Install "Secrets Finder" extension
- JetBrains: Enable "Sensitive Data" inspection
- Vim: Use `secretlint` plugin

## 📞 Incident Response

### If Real Credentials Are Exposed
1. **Immediate** (0-5 minutes):
   - Rotate/revoke exposed credentials
   - Remove from all systems using them
   
2. **Short-term** (5-30 minutes):
   - Check access logs for unauthorized usage
   - Rewrite Git history if possible (`git filter-branch`)
   - Update all systems with new credentials

3. **Follow-up** (1-24 hours):
   - Review and strengthen secret management
   - Update this documentation with lessons learned
   - Implement additional preventive measures

## ✅ Quick Reference Checklist

Before every `git push`, verify:

- [ ] No real credentials in staged changes
- [ ] Placeholder format uses `<YOUR_*_HERE>` pattern  
- [ ] No real email addresses in configuration examples
- [ ] Commit message doesn't contain sensitive information
- [ ] .env files are not being committed
- [ ] Pre-commit hooks have run successfully

**Remember**: It's better to be overly cautious than to expose credentials. When in doubt, ask for review before pushing.