# UIB AMS — Agency Management System

The Agency Management System for Universal Insurance Brokers: clients,
policies, documents, renewals, ACORD forms and Certificates of Liability
Insurance. It deploys to Vercel as a static site.

Its sibling is the **Binder Book**
([amanzor/uib-binderbook](https://github.com/amanzor/uib-binderbook)),
where agents enter new business.

## The two apps share one database

Both apps read and write the same Supabase project — the same
`app_store` rows. That shared data *is* the connection between them: a
client entered in the Binder Book appears here because this app re-reads
that row, not because the two share anything in the browser.

They used to be served from one domain and shared the browser's
`localStorage`, which made Binder Book entries appear here instantly. On
separate domains that shortcut is gone, so this app re-pulls the shared
rows on a timer and whenever its tab returns to the foreground. Expect a
new client to show up within a minute, or immediately on switching back
to the tab.

Two consequences worth knowing:

- **Agents sign in once per app.** A browser session belongs to one
  domain, so signing into the Binder Book does not sign you in here.
- **Nothing is stored only in the browser.** The data, the logins and the
  uploaded documents live in Supabase.

## Shared files — edit them in the Binder Book, not here

The files listed in [`shared-files.txt`](shared-files.txt) are **copies**.
They are maintained in `amanzor/uib-binderbook` and copied here verbatim.

This matters more than it looks. `uib-binder-sync.js` is the layer that
merges the shared book of business before writing it. If the two apps ever
carry different versions of that file, they write the same row by
different rules — which is precisely how entries get overwritten and lost.

So:

- **Never edit a shared file in this repository.** A change made here is
  overwritten by the next sync, and until then the two apps disagree.
- Make the change in the Binder Book repo. A scheduled GitHub Action
  copies it here and opens a pull request.
- To sync by hand, against a local checkout of the Binder Book:

  ```bash
  scripts/sync-shared.sh ../uib-binderbook          # copy
  scripts/sync-shared.sh --check ../uib-binderbook  # report drift only
  ```

Everything *not* in `shared-files.txt` belongs to this repository:
`index.html`, `ams.js`, `acord25-map.js`, `certificates.js`,
`certificates-ui.js` and `forms/`.

## Certificates of Liability Insurance

`forms/acord25.pdf` is the agency's own ACORD 25 (2025/12), a genuine
AcroForm. Certificates are produced by filling that file's own 129 fields
— the form that reaches a certificate holder is the real ACORD document,
not a redrawn copy that could drift from the official layout.

`acord25-map.js` maps every one of those fields to the data the AMS
stores. If the agency adopts a newer ACORD 25 edition, replace the PDF and
re-check the map against it: field names change between editions, and a
field name that no longer exists fails silently.

A certificate is a legal statement about coverage in force. The app is
built around that: values Claude reads off a declaration page are
highlighted until an agent has looked at them, a field nobody filled
prints blank rather than guessed, and each certificate lists what it still
needs before it can be issued. Certificates are voided rather than
deleted, so an issued one stays auditable.

> ACORD forms are published by ACORD Corporation and carry their own
> licensing terms. This repository stores the agency's own copy of a form
> it is entitled to use; it is not a redistribution of ACORD's library.

## Deploying

Vercel, as a static site:

- Framework preset: **Other**
- Build command, output directory, install command: leave empty
- `vercel.json` sets the cache and security headers, including the
  Content-Security-Policy that allows the Supabase project and the CDNs
  the app loads from

`index.html` is the AMS itself, so the site root is the app.

## Configuration

- **Supabase project** — `uib-config.js` (a shared file; change it in the
  Binder Book repo so both apps move together). Point both apps at the
  same project or they stop sharing data.
- **Link back to the Binder Book** — one absolute URL near the top of
  `index.html`, on the login screen. Change it if the Binder Book moves to
  its own domain.
- **Agency details on certificates** — set in the app, under Certificate
  Master ▸ Agency details. Stored per browser, not in this repo.
