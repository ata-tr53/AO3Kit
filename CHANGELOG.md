# Changelog

All notable changes to `AO3Kit` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-25

### Added
- **Core Networking & Infrastructure:** `AO3Client` with Swift 6 (`ApproachableConcurrency`) support, `AO3Version` (`0.1.0`), automatic CSRF token handling, `429` rate-limit backoff, request deduplication, `AO3Cache`, `AO3ImageStore`, `AO3StatusMonitor` (`client.status`), and complete `AO3Endpoint` URL building and `AO3Client.dissect(url:)` parsing.
- **Reader & Discovery:** Works, chapters, full-work downloads (EPUB/AZW3/MOBI/PDF/HTML), kudos lists, bookmarks, series, user/pseud profiles, collections, media/fandom directories, languages, tag details, Tag Atom feeds (`client.tags.feed`), filtered/sorted list sources, search exclusions, and all 21 autocomplete scopes.
- **Community & Moderation:** Authenticated and guest comments, comment edit/delete/moderation, unreviewed comments listing, kudos, inbox management, subscriptions, muted/blocked users, gift accept/refuse, collection people/requests, and collection join/leave.
- **Authoring CRUD:** Full Works CRUD (create, edit, edit tags, post draft, delete, import, orphan, remove co-creatorship), Chapters CRUD (add, edit, post draft, delete, reorder), Series CRUD & work reordering, collection items & invite approvals, and External Works fetch & creation.
- **Account, Skins & Challenges:** User preferences, favorite tags, site/work skins (list, details/CSS, preview, set/unset, CRUD), profile & pseuds CRUD, challenge dashboard (signups, assignments, claims, tag sets, nominations), credentials & password reset, and invite queue status/invitations.
- **Site Info & Support (`client.site`):** FAQ categories and pages, known issues, static pages, abuse reports, and support request submission.
- **Protocols:** `AO3Response`, `AO3FicModel`, `AO3SeriesModel`, `AO3AuthorModel`, `AO3CollectionModel`, `AO3TagModel`, `AO3SkinModel`, `AO3Bookmarkable`, `AO3Commentable`, `AO3Subscribable`, `AO3Blockable`/`AO3Mutable`, and `AO3IconPresentable`.
