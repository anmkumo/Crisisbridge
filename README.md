# NGTCORE Crisis Bridge v2

Open-source community incident reporting prototype.

## Included
- Responsive dark dashboard and login/registration screen.
- Registration by email and password **without OTP**.
- Supabase Auth enforces unique email accounts in the same project; `profiles.email` is also unique.
- Interactive Leaflet/OpenStreetMap pin, with optional browser geolocation.
- General users see only their own reports.
- Support/admin can see the operational queue and update statuses.
- Only admins can promote registered users to support.
- Footer icons for GitHub, Telegram, TikTok, Instagram, and X.

## Configure backend
1. Create a Supabase project at https://supabase.com/.
2. Copy the Project URL and anon/public key into `config.js`.
3. In Supabase Authentication settings, turn OFF **Confirm email** if registration must work without sending a verification email/OTP. This means an email address is not verified, only unique in the project; use CAPTCHA/rate limits to reduce abuse.
4. Run `supabase-schema.sql` in the Supabase SQL Editor.
5. Register your own account through the app. In Authentication → Users, copy your account UUID. Run `update public.profiles set role='admin' where id='YOUR-VERIFIED-USER-UUID';` in SQL Editor, replacing the placeholder.
6. Log out and log back in to load admin permissions.

Never put a service_role key or admin password in `config.js` or public GitHub.

## Test before public launch
Use separate general, support, and admin accounts. Test direct API calls, not just the visible UI. The sample staff update policy currently allows staff to update report columns generally; add database-side field restrictions/audit logging before production. Do not use for real incidents until tested.

## Social links
- GitHub: https://github.com/anmkumo/Crisisbridge
- Telegram: https://t.me/ngtcore
- TikTok: https://www.tiktok.com/@Core_ngt
- Instagram: https://www.instagram.com/anmkumo/
- X: https://x.com/anmkumo

If a social profile URL is different, edit the footer href in `index.html`.

## Publish
Upload the files to the repository root. GitHub Pages can host the frontend, but Supabase must be configured separately. Browser geolocation requires HTTPS or localhost.

## License
MIT.
