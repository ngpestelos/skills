---
name: cloudflare-pages-static-site
description: "Deploy single-page static sites to Cloudflare Pages with custom domains. No framework, no build step. Trigger keywords: static site, Cloudflare Pages, landing page, deploy website, custom domain, pages.dev."
metadata:
  version: "1.0.1"
---

# Deploying Static Sites to Cloudflare Pages

Ship static HTML/CSS with custom domain in under an hour.

## Workflow

1. **Create repo**: `mkdir ~/src/<site> && cd ~/src/<site> && git init`
2. **Write files**: `index.html` + `style.css` (no framework for single-page sites)
3. **Push to GitHub**: `gh repo create <site> --public --source=. --push`
4. **Cloudflare Pages**: Workers & Pages → Create application → Pages tab → Connect to Git → select repo
5. **Build settings**: Framework = None, Build command = empty, Output directory = `/`
6. **Custom domain**: Pages project → Custom domains → add domain → update DNS
7. **Iterate**: Every `git push` auto-deploys in ~30 seconds

## DNS Setup

- Delete old A records pointing to previous host
- Add CNAME: `@` → `<project>.pages.dev`
- For `www`: add as Pages custom domain AND add `www` CNAME in DNS (both required)
- Don't use wildcard (`*`) CNAME — causes 522 errors on undefined subdomains

**Domain transfer**: Change nameservers to Cloudflare's NS at old registrar, enter auth/EPP code at Cloudflare, ~$10/year at cost.

## Anti-Patterns

- **Over-engineering v1**: Single-page site doesn't need React/Tailwind/CMS. `index.html` + `style.css` ships in 30 minutes.
- **Workers vs Pages**: For static sites, use Pages/Connect to Git flow, not Workers/wrangler.
