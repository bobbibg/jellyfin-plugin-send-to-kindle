# Jellyfin Send to Kindle Plugin

A Jellyfin plugin that adds a **Send to Kindle** button to book detail pages. Each
user sets their own `@kindle.com` address; the admin configures one SMTP account
(GMX, Gmail, anything) and the plugin handles per-user delivery.

## Features

- Per-user Kindle email — each Jellyfin user has their own destination
- Admin-configured SMTP — one server credential, many users
- "Send to Kindle" button injected into the book detail page
- Format-agnostic — sends whatever Jellyfin has on disk (EPUB, PDF, MOBI, AZW3, DOC, DOCX, TXT, RTF, HTML)
- 50 MB attachment cap, configurable
- Test-send button in admin config to verify SMTP without leaving the dashboard

## Install via Jellyfin plugin repository

This is the easiest path — Jellyfin handles updates automatically.

1. Open Jellyfin → **Dashboard → Plugins → Repositories → +**
2. Repository URL: `https://raw.githubusercontent.com/bobbibg/jellyfin-plugin-send-to-kindle/main/manifest.json`
3. Repository name: `Send to Kindle`
4. Save, then go to the **Catalog** tab
5. Find **Send to Kindle** under General, click Install
6. Restart Jellyfin

## Configure (admin)

1. **Dashboard → Plugins → My Plugins → Send to Kindle**
2. Fill in your SMTP details. For GMX:
   - Host: `mail.gmx.com`
   - Port: `587`
   - Use STARTTLS: yes
   - Username / password: your GMX login (use a generated mail-app password if 2FA is enabled)
   - From address: a real GMX address you own
3. **Critical:** add the From address to your Amazon approved-senders list at
   [amazon.com/sendtokindle](https://www.amazon.com/sendtokindle) → "Personal Document Settings" →
   "Approved Personal Document E-mail List". Without this Amazon will silently drop everything.
4. Save, then click **Send test email to my Kindle** to verify.

## Configure (each user)

Each Jellyfin user does this once on their own profile:

1. Click your user avatar → **Settings**
2. Find **Send to Kindle** in the user menu (left sidebar)
3. Enter your Kindle email — find it at
   [Manage Your Content and Devices → Preferences → Personal Document Settings](https://www.amazon.com/hz/mycd/myx#/home/settings/payment).
   It looks like `your-name_abc123@kindle.com`.
4. Save.

## Use

Browse to any book in your Jellyfin library. The book detail page now has a
**Send to Kindle** button alongside Play / Mark Watched. Click it. The button
shows "Sent ✓" when Amazon accepts the email; delivery to the device usually
takes 1–5 minutes.

## How it works

```
[Book detail page]
        |
        | click button
        v
POST /SendToKindle/Send/{itemId}
        |
        v
[Plugin] -- looks up user's Kindle email
        |  -- reads book file from disk
        |  -- attaches it to a MimeMessage
        v
[MailKit] -- connects to configured SMTP
        |  -- authenticates
        |  -- sends
        v
[GMX / Gmail / etc.] --> Amazon receives --> Kindle delivery
```

The button is injected into Jellyfin's web UI by patching `index.html` to load
`/SendToKindle/Script` on every page. The script polls the URL for book detail
pages and adds the button to the actions row.

## Build locally

You need .NET 8 SDK installed.

```bash
dotnet restore Jellyfin.Plugin.SendToKindle.sln
dotnet build Jellyfin.Plugin.SendToKindle.sln --configuration Release
```

Output:
```
Jellyfin.Plugin.SendToKindle/bin/Release/net8.0/Jellyfin.Plugin.SendToKindle.dll
```

To install manually: drop the `.dll` (plus `MailKit.dll`, `MimeKit.dll`,
`BouncyCastle.Cryptography.dll` from the same folder) into your Jellyfin
`config/plugins/SendToKindle_X.Y.Z/` directory and restart.

## Release a new version

1. Bump the version in `Jellyfin.Plugin.SendToKindle/Jellyfin.Plugin.SendToKindle.csproj`
2. Commit and push
3. Tag the release: `git tag v1.2.3 && git push --tags`
4. GitHub Actions builds the `.zip`, computes the checksum, updates `manifest.json`
   on `main`, and publishes a GitHub Release. Jellyfin clients pick the new
   version up on their next plugin-catalog refresh.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Test email succeeds but nothing arrives at the Kindle | From address isn't in your Amazon approved-senders list |
| `Authentication failed` in logs | SMTP password rejected. For GMX with 2FA, generate a mail-app password |
| `File format '.cbz' is not accepted` | Amazon doesn't accept comic archives. Convert to PDF first |
| Button doesn't appear on book pages | Refresh the page once (the script tag is added on plugin start, but the browser caches `index.html`) |
| `Item has no file on disk` | The library item's `Path` field is empty — usually a Calibre/Bookshelf metadata-only entry |

Logs live in `Jellyfin/log/jellyfin*.log`; search for `SendToKindle` to filter.

## License

MIT
