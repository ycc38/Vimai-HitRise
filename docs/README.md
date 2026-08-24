# Vimai HitRise GitHub Pages

This directory contains the public product, support, privacy, terms, and data-request pages for Vimai HitRise.

## GitHub Pages deployment

The `.github/workflows/pages.yml` workflow publishes this directory whenever it changes on `main`.

For the first deployment, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions**. After deployment, the expected URLs are:
   - Marketing: `https://ycc38.github.io/Vimai-HitRise/`
   - Support: `https://ycc38.github.io/Vimai-HitRise/support.html`
   - Privacy: `https://ycc38.github.io/Vimai-HitRise/privacy.html`
   - Terms: `https://ycc38.github.io/Vimai-HitRise/terms.html`
   - Privacy choices: `https://ycc38.github.io/Vimai-HitRise/data-deletion.html`

The pages are plain static HTML and require no build step. Confirm that the support and privacy URLs return HTTP 200 before submitting them to App Store Connect.
