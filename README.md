# fayoum_doctors_list

A new Flutter project.

## Deploy Web on GitHub Pages (Custom Domain)

This repo includes a GitHub Actions workflow that builds Flutter Web and publishes it to the `gh-pages` branch.

### 1) Enable GitHub Pages

- Go to **Settings → Pages**
- **Build and deployment**: choose **Deploy from a branch**
- Select branch: `gh-pages` and folder: `/ (root)`

### 2) (Optional) Set a custom domain

- Go to **Settings → Pages → Custom domain** and enter your domain.
- Also set a repository variable:
	- **Settings → Secrets and variables → Actions → Variables**
	- Add `CUSTOM_DOMAIN` with value like `example.com` or `www.example.com`

DNS notes:
- If you use `www.example.com`: create a **CNAME** record to `<your-username>.github.io`.
- If you use the root domain `example.com`: create **A** records to GitHub Pages IPs (from GitHub docs) and optionally a `www` CNAME.

### 3) Important: BASE_HREF

- For a **custom domain** (site served at `/`): leave it as default or set `BASE_HREF` to `/`.
- For **project pages** (served at `https://<user>.github.io/<repo>/`): set `BASE_HREF` to `/<repo>/`.

Set it here:
- **Settings → Secrets and variables → Actions → Variables**
- Add `BASE_HREF` (example: `/fayoum_doctors_list/`)

### 4) Deploy

- Push to `main` (or `master`) and the workflow will publish automatically.
- Or run it manually from **Actions → Deploy Flutter Web (GitHub Pages)**.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
