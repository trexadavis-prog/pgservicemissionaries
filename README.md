# PG Service Missionaries — Zone Hub

This repository contains the complete **Zone Hub** web application (`index.html`) and database schema (`supabase_setup.sql`).

---

## Setting Up Your Own Separate Database (Supabase)

Because this app is a single static HTML file, all data, shared site/admin passwords, and missionary photos live in a free **Supabase** project. Follow these 4 steps to connect this copy to its own isolated database:

### Step 1: Create a Free Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **New Project**, choose an organization, give it a name (e.g., `pg-service-missionaries`), set a database password, and wait ~1 minute for the project to finish provisioning.

### Step 2: Run the Database Schema Script
1. In your new Supabase project dashboard, open **SQL Editor** from the left sidebar and click **New query**.
2. Copy the entire contents of [`supabase_setup.sql`](./supabase_setup.sql), paste it into the editor, and click **Run**.
   - This creates all 11 tables, Row-Level Security (RLS) policies, cookie counter functions, and the `missionary-photos` storage bucket.

### Step 3: Create the Site & Admin Password Accounts
The site uses two shared accounts so everyone in the zone can sign in with a single site password, and leaders can unlock Admin Mode with an admin password:

1. In the Supabase dashboard, go to **Authentication** → **Users** → click **Add user** → **Create new user**:
   - **User 1 (Site Password):**
     - **Email:** `missionary@zonehub.pgmissionaries.internal`
     - **Password:** *(Choose the site password you want missionaries to enter)*
     - **Auto Confirm User:** Checked ✅
   - **User 2 (Admin Password):**
     - **Email:** `admin@zonehub.pgmissionaries.internal`
     - **Password:** *(Choose the admin password for unlocking Admin Mode)*
     - **Auto Confirm User:** Checked ✅

*(Both the database RLS policies in `supabase_setup.sql` and `index.html` automatically recognize `admin@zonehub.pgmissionaries.internal` as an admin—no extra linking required!)*

### Step 4: Put Your Project URL & Anon Key in `index.html`
1. In Supabase, go to **Project Settings** (gear icon) → **API** (or **Data API** / **API Keys**).
2. Copy your **Project URL** and your **`anon` `public` key**.
3. Open [`index.html`](./index.html) and update lines `1524–1525`:
   ```javascript
   const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
   const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
   ```
4. Commit and push!

---

## Sharing & Hosting the Repository

- **Sharing the private repo with collaborators:**
  Go to `https://github.com/trexadavis-prog/pgservicemissionaries/settings/access` (or run `gh repo edit --add-collaborator <username>`) to invite others.
- **Hosting the live site:**
  - **GitHub Pages:** Requires a public repository on GitHub Free, or GitHub Pro/Team for private repos.
  - **Cloudflare Pages / Netlify / Vercel (Free with Private GitHub Repos):** You can connect this private repository directly to Cloudflare Pages, Netlify, or Vercel at no cost, and it will automatically deploy `index.html` to a shareable URL every time you push to `main`.
