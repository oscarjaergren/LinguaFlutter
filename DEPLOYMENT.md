# 🚀 Deployment Guide - Vercel

## Prerequisites

- GitHub account
- Vercel account (sign up at https://vercel.com)
- Flutter installed locally
- Project pushed to GitHub

## Quick Deployment (5 minutes)

### Option 1: GitHub Integration (Recommended)

1. **Push your code to GitHub** (if not already done)
   ```bash
   git add .
   git commit -m "Ready for deployment"
   git push origin main
   ```

2. **Connect to Vercel**
   - Go to https://vercel.com/new
   - Click "Import Project"
   - Select your GitHub repository
   - Vercel will auto-detect `vercel.json` ✅

3. **Configure Environment Variables**
   - In Vercel dashboard, go to: Settings → Environment Variables
   - Add these variables:
     ```
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     GEMINI_API_KEY=your_gemini_api_key
     ```

4. **Deploy**
   - Click "Deploy"
   - Wait 2-3 minutes
   - Your app is live! 🎉

### Option 2: CLI Deployment

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel**
   ```bash
   vercel login
   ```

3. **Build your app**
   ```bash
   flutter build web --release --dart-define=ENVIRONMENT=production
   ```

4. **Deploy**
   ```bash
   vercel --prod
   ```

5. **Add environment variables**
   ```bash
   vercel env add SUPABASE_URL
   vercel env add SUPABASE_ANON_KEY
   vercel env add GEMINI_API_KEY
   ```

## Configuration

Your `vercel.json` is already configured with:
- ✅ Security headers (CSP, X-Frame-Options, etc.)
- ✅ SPA routing (all routes → index.html)
- ✅ Automatic HTTPS
- ✅ Build settings

## Continuous Deployment

Once connected to GitHub, Vercel automatically:
- Deploys on every push to `main` branch
- Creates preview deployments for pull requests
- Runs build checks before deployment

## Custom Domain (Optional)

1. Go to Vercel dashboard → Settings → Domains
2. Add your custom domain
3. Update DNS records as instructed
4. Vercel automatically provisions SSL certificate

## Monitoring

**Vercel Dashboard provides:**
- Real-time deployment logs
- Performance analytics
- Error tracking
- Build history

**Access at:** https://vercel.com/dashboard

## Troubleshooting

### Build fails
- Check Flutter version compatibility
- Verify `vercel.json` syntax
- Review build logs in Vercel dashboard

### Environment variables not working
- Ensure variables are set in Vercel dashboard
- Redeploy after adding variables
- Check variable names match your code

### Routing issues
- Verify `vercel.json` has rewrites configured
- Clear browser cache
- Check Vercel deployment logs

## Rollback

If something goes wrong:
1. Go to Vercel dashboard → Deployments
2. Find previous working deployment
3. Click "..." → "Promote to Production"

## Support

- Vercel Docs: https://vercel.com/docs
- Vercel Support: https://vercel.com/support
- Project Issues: GitHub Issues tab

---

**Next Steps:**
1. Deploy to Vercel
2. Test all features in production
3. Set up custom domain (optional)
4. Monitor performance and errors
