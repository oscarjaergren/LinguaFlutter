# Production Deployment Guide

This guide covers deploying LinguaFlutter with Sentry error tracking to production.

## Overview

Your app now has comprehensive Sentry integration that will:
- Automatically capture all errors and exceptions
- Track user context and navigation
- Create releases tied to deployments
- Provide detailed debugging information

## Quick Setup

1. **Create Sentry Project**: Get your DSN from [sentry.io](https://sentry.io)
2. **Add GitHub Secrets**: `SENTRY_DSN` and `SENTRY_AUTH_TOKEN`
3. **Update .env**: Add `SENTRY_DSN` for local development

That's it! Sentry docs cover everything else.

## Required Setup

### 1. Sentry Project Setup

1. Create a Sentry account at [sentry.io](https://sentry.io)
2. Create a new Flutter project
3. Get your **DSN** from project settings → Client Keys (DSN)
4. Get your **Organization Slug** from settings
5. Get your **Project Slug** from project settings
6. Create an **Auth Token** at account → API → Auth Tokens

### 2. GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
SENTRY_DSN=your_sentry_dsn_here
SENTRY_AUTH_TOKEN=your_sentry_auth_token_here
SENTRY_ORG=your_organization_slug
SENTRY_PROJECT=your_project_slug
```

### 3. Environment Variables

For local development, update your `.env` file:

```env
# Sentry Configuration
SENTRY_DSN=https://your-sentry-dsn@sentry.io/your-project-id
```

## Deployment Process

### Automatic Deployment (Recommended)

When you push to `master` branch:

1. **CI/CD Pipeline** runs tests and builds
2. **Vercel Deployment** builds and deploys to production
3. **Sentry Release** creates release with commit tracking
4. **Error Tracking** begins immediately

### Manual Steps (if needed)

```bash
# 1. Install dependencies
flutter pub get

# 2. Build for production with Sentry DSN
flutter build web --release --dart-define=SENTRY_DSN=your_dsn_here

# 3. Deploy to Vercel
vercel --prod

# 4. Create Sentry release (optional)
npx @sentry/cli releases new lingua_flutter@1.0.0
```

## What Gets Tracked

### Automatic Error Capture
- All unhandled exceptions
- Flutter framework errors
- Network failures
- Authentication errors
- Any errors logged through `LoggerService.error()`

### User Context
- User ID and email (when signed in)
- Platform information
- Environment (development/production)

### Navigation Tracking
- Route changes via `SentryNavigatorObserver`
- Helps understand user flow before errors

### Release Tracking
- Version-specific error tracking
- Commit association
- Deployment correlation

## Monitoring Your Production App

### Sentry Dashboard

1. **Issues Tab**: View all errors grouped by type
2. **Releases Tab**: Track errors by version
3. **Performance Tab**: Monitor slow operations
4. **Users Tab**: See affected users

### Key Metrics to Watch

- **Error Rate**: Percentage of sessions with errors
- **Crash Rate**: App crashes vs total sessions
- **Performance**: Slow operations and bottlenecks
- **User Impact**: How many users affected by each issue

## Debugging Production Issues

### When Vercel Fails

If your Vercel deployment has issues:

1. **Check Sentry Issues** first - errors often explain deployment failures
2. **Look at Release Health** - see if new version introduced problems
3. **Review Breadcrumbs** - understand user actions before errors
4. **Check Environment** - verify production vs development differences

### Common Error Patterns

- **Network Errors**: Supabase connection issues, API failures
- **Auth Errors**: Token expiration, invalid credentials
- **Build Errors**: Missing environment variables, dependency issues
- **Runtime Errors**: Null references, type mismatches

## Cost Management

### Sentry Limits (Free Tier)
- **5,000 errors/month**
- **10,000 transactions/month**

### Optimization Tips
- Adjust `tracesSampleRate` in `sentry_service.dart` (currently 20% in production)
- Use Sentry filters to ignore common errors
- Monitor your quota regularly

### When to Upgrade
- Consistently hitting error limits
- Need advanced features like alerts
- Want longer data retention

## Security Considerations

### Data Privacy
- User emails are sent to Sentry for context
- No passwords or sensitive tokens logged
- You can add data filtering in `beforeSend` callback

### CSP Headers
Your `vercel.json` already includes Sentry domains in CSP:
```json
"connect-src": "... https://*.ingest.sentry.io"
```

## Troubleshooting

### Sentry Not Working

1. **Check DSN**: Verify your Sentry DSN is correct
2. **Environment**: Ensure secrets are set in GitHub
3. **Build Logs**: Check for Sentry initialization messages
4. **Network**: Verify Sentry domains are accessible

### Common Issues

- **"DSN not found"**: Check `.env` file or GitHub secrets
- **No errors in Sentry**: Check if Sentry is initializing (look for console logs)
- **Missing user context**: Verify auth provider integration
- **Release not created**: Check GitHub Actions logs for Sentry CLI errors

## Best Practices

### Development
- Use `.env` file for local Sentry DSN
- Test error capture in development
- Check console for Sentry initialization logs

### Production
- Monitor Sentry dashboard regularly
- Set up alerts for critical errors
- Review new issues daily
- Use release tracking for debugging

### Code Quality
- Use `LoggerService.error()` for error tracking
- Add context when capturing exceptions
- Use breadcrumbs for complex flows
- Set user context after authentication

## Emergency Response

### Critical Error Spikes

1. **Identify affected release**: Check if new version caused issues
2. **Rollback if needed**: Deploy previous working version
3. **Investigate**: Use Sentry breadcrumbs and context
4. **Fix and redeploy**: Test thoroughly before deploying

### Service Outages

If Sentry or other services are down:
- Your app continues to work (Sentry is non-blocking)
- Local logging via Talker still works
- Errors will queue and send when service is available

## Support Resources

- **Sentry Documentation**: https://docs.sentry.io/platforms/flutter/
- **Flutter Debugging**: https://docs.flutter.dev/testing/debugging
- **Vercel Support**: https://vercel.com/docs
- **GitHub Actions**: https://docs.github.com/en/actions

---

Your app is now production-ready with comprehensive error tracking. Monitor your Sentry dashboard regularly to catch issues before they affect users!
