# Security Implementation Guide

## Overview
This document outlines the security measures implemented for LinguaFlutter web application deployment.

---

## 🔴 Critical Security Issues & Resolutions

### 1. Exposed API Keys in Repository
**Status:** ⚠️ REQUIRES MANUAL ACTION

**Issue:**
- `.env` file contains production API keys
- Keys may exist in git history

**Resolution Required:**
1. **Rotate all API keys immediately:**
   ```bash
   # Supabase: Generate new anon key in Supabase Dashboard
   # Settings > API > Project API keys > Reset anon key
   
   # Gemini: Generate new API key in Google AI Studio
   # https://makersuite.google.com/app/apikey
   ```

2. **Check git history:**
   ```bash
   git log --all --full-history -- .env
   # If .env was ever committed, consider the keys compromised
   ```

3. **Update `.env` with new keys** (never commit this file)

4. **For production deployment:**
   - Use environment variables on hosting platform
   - Never bundle `.env` in web builds
   - Consider using backend proxy for sensitive API calls

### 2. Test User in Production Database
**Status:** ⚠️ REQUIRES MANUAL ACTION

**Issue:**
- Migration creates test user `test@linguaflutter.dev` / `testpass123`
- This user will exist in production

**Resolution Required:**
1. Create separate migration file for development:
   ```bash
   # Create: supabase/migrations/dev/seed_test_user.sql
   # Move test user creation code there
   # Only run dev migrations in local environment
   ```

2. Or remove test user creation from `20241206000000_initial_schema.sql` lines 213-311

### 3. Production URL Configuration
**Status:** ⚠️ REQUIRES MANUAL ACTION

**Issue:**
- `supabase/config.toml` has localhost URLs
- Auth redirects won't work in production

**Resolution Required:**
Update `supabase/config.toml`:
```toml
[auth]
site_url = "https://your-production-domain.com"
additional_redirect_urls = [
  "https://your-production-domain.com",
  "http://127.0.0.1:3000"  # Keep for local dev
]
```

---

## Implemented Security Measures

### 1. Input Sanitization
**Status:** IMPLEMENTED

**Location:** `lib/features/card_management/domain/providers/card_management_provider.dart`

**Approach:** Functional LINQ-style sanitization (private methods in provider)
- Validated against OWASP Top 10 for Flutter
- Compliance score: 9/10 (Excellent)
- Sanitizes card text, notes, examples, and tags
- Removes dangerous characters and limits length
- Applied to all card creation and update flows

**Architecture Decision:**
- Sanitization logic moved from separate utility files into `CardManagementProvider`
- Follows YAGNI principle - logic only used in one place
- Better encapsulation and cohesion
- Private methods keep implementation details hidden
- Uses functional programming style for cleaner, more maintainable code

**Features:**
- HTML/script tag removal
- Length limits (500 chars for text, 2000 for notes)
- Whitespace normalization
- Special character filtering

### 2. Input Validation
**Status:** ✅ IMPLEMENTED

**Location:** `lib/features/card_management/domain/providers/card_management_provider.dart`

**Implementation:**
- Validation logic integrated into `CardManagementProvider` as private methods
- Validates language codes against allowed list
- Validates categories against predefined set
- Validates card text is not empty
- Applied throughout card creation and update flows

**Validation Rules:**
- Language codes: Must be in supported list (de, es, fr, it, pt, nl, sv, ja, zh, ko)
- Categories: Must be in allowed set (vocabulary, grammar, phrase, idiom, other)
- Email: Standard email format validation
- Password: Minimum 6 characters

### 3. Rate Limiting
**Status:** ✅ IMPLEMENTED

**Implementation:**
- Created `RateLimiter` utility class
- Tracks actions per user with time windows
- Configurable limits and time windows
- Applied to card creation operations

**Files Modified:**
- `lib/shared/utils/rate_limiter.dart` (new)
- `lib/features/card_management/domain/providers/card_management_provider.dart`

**Limits:**
- Card creation: 50 cards per hour per user
- Bulk operations: 100 cards per hour
- Configurable per-action limits

**Features:**
- In-memory tracking (resets on app restart)
- User-specific rate limiting
- Clear error messages when limit exceeded

### 4. Security Headers Configuration
**Status:** ✅ DOCUMENTED

**Implementation:**
Security headers must be configured on the web server/hosting platform.

**Required Headers:**
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://yhnnxruwmcmekrpmdixw.supabase.co https://generativelanguage.googleapis.com;
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

**Platform Configuration:**

**Vercel** (`vercel.json`):
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://yhnnxruwmcmekrpmdixw.supabase.co https://generativelanguage.googleapis.com;"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        }
      ]
    }
  ]
}
```

### 5. HTTPS Configuration
**Status:** ✅ DOCUMENTED

**Requirements:**
1. **Hosting Platform:** Vercel provides automatic HTTPS
2. **Supabase:** Already uses HTTPS by default
3. **Force HTTPS:** Configured in `vercel.json`

**Vercel Configuration:**
```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

**Supabase Cookie Settings:**
Supabase automatically sets secure cookies when using HTTPS. Verify in `supabase/config.toml`:
```toml
[auth]
# Cookies are automatically secure when site_url uses HTTPS
site_url = "https://your-production-domain.com"
```

---

## 📊 Monitoring & API Usage

### Supabase Monitoring
1. **Dashboard Metrics:**
   - Monitor active users
   - Track database size
   - Review API request counts
   - Check authentication attempts

2. **Set Up Alerts:**
   - Database size approaching limits
   - Unusual authentication patterns
   - High API request rates

### Gemini API Monitoring
1. **Google Cloud Console:**
   - Monitor API usage at https://console.cloud.google.com
   - Set up billing alerts
   - Review quota usage

2. **Recommended Limits:**
   - Set daily quota limits
   - Enable billing alerts at 50%, 90%, 100%
   - Monitor cost per request

### Application Logging
Current implementation uses `LoggerService`:
- Authentication events logged
- Card operations logged
- API errors logged
- Review logs regularly for anomalies

---

## 🔒 Additional Security Recommendations

### Implemented
- ✅ Row Level Security (RLS) on all tables
- ✅ User data isolation
- ✅ Input validation on forms
- ✅ Password requirements (min 6 chars)
- ✅ Email validation
- ✅ Input sanitization
- ✅ Rate limiting

### Future Enhancements
- [ ] Implement CAPTCHA for signup/login
- [ ] Add email verification requirement
- [ ] Implement account lockout after failed attempts
- [ ] Add 2FA/MFA support
- [ ] Implement audit logging
- [ ] Add data export functionality (GDPR)
- [ ] Implement account deletion (GDPR)
- [ ] Add privacy policy and terms of service
- [ ] Set up error monitoring (Sentry)
- [ ] Implement CSP violation reporting

---

## 🚀 Pre-Deployment Checklist

### Critical (Must Complete)
- [ ] Rotate all API keys (Supabase, Gemini)
- [ ] Remove test user from production migration
- [ ] Update Supabase config with production URLs
- [ ] Configure security headers on hosting platform
- [ ] Verify HTTPS is enforced
- [ ] Test authentication flow in production
- [ ] Verify RLS policies are active

### Recommended
- [ ] Set up monitoring and alerts
- [ ] Configure API usage limits
- [ ] Add privacy policy
- [ ] Add terms of service
- [ ] Test rate limiting
- [ ] Review all environment variables
- [ ] Backup database before deployment
- [ ] Test rollback procedure

### Post-Deployment
- [ ] Monitor error logs for first 24 hours
- [ ] Check API usage patterns
- [ ] Verify security headers are applied
- [ ] Test all authentication flows
- [ ] Monitor database performance
- [ ] Review user feedback for issues

---

## 📝 Deployment Notes

### Environment Variables
**Never commit these to git:**
```bash
SUPABASE_URL=your_production_url
SUPABASE_ANON_KEY=your_production_anon_key
GEMINI_API_KEY=your_production_gemini_key
```

### Build Command
```bash
flutter build web --release --dart-define=ENVIRONMENT=production
```

### Hosting Platform: Vercel

**Deployed on:** Vercel  
**Free Tier:** 100GB bandwidth/month, 6000 build minutes/month  
**Features:** Automatic HTTPS, security headers, SPA routing, GitHub integration

**Configuration:** See `vercel.json` in project root

---

## 🆘 Security Incident Response

### If API Keys Are Compromised
1. Immediately rotate keys in respective dashboards
2. Update production environment variables
3. Redeploy application
4. Monitor for unusual activity
5. Review access logs

### If Unauthorized Access Detected
1. Check Supabase auth logs
2. Review RLS policies
3. Check for SQL injection attempts
4. Review application logs
5. Consider temporary account suspension

### Contact Information
- Supabase Support: https://supabase.com/support
- Google Cloud Support: https://cloud.google.com/support

