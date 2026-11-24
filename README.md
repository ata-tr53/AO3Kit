#   AO3Kit

A modern, Swift 6 native client library for [Archive of Our Own (AO3)](https://archiveofourown.org), built with strict concurrency (`ApproachableConcurrency`), structured caching, adaptive rate limiting, and full route coverage.

> **Disclaimer:** AO3Kit is an unofficial, independent library and is not affiliated with, endorsed by, or maintained by the Organization for Transformative Works (OTW) or Archive of Our Own.

## Features

* **13 Typed API Scopes** on `AO3Client` covering reading, search, discovery, community moderation, authoring CRUD, account management, site info, images, and system status.
* **Swift 6 Concurrency:** Full `Sendable` conformance across models, drafts, parsers, and API scopes with `async`/`await` throughout.
* **Resilient Networking:** Automatic CSRF token management, `429 Too Many Requests` `Retry-After` backoff, exponential retry for `GET` requests, in-flight request deduplication, and optional request culling during OTW outages.
* **Multi-Layer Caching:** Configurable memory/disk `AO3Cache` for responses and `AO3ImageStore` for avatars, icons, and embedded art.
* **URL Dissection & Routing:** `AO3Client.dissect(url:)` recognizes all AO3 mirror domains and maps AO3 web URLs into strongly typed `AO3Endpoint` values.

## Requirements

* Swift 6.4+
* iOS 18.0+ / macOS 15.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 1.0+

## Installation

Add `AO3Kit` to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ata-tr53/AO3Kit.git", from: "0.1.0")
]
```

Then add "AO3Kit" to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["AO3Kit"]
)
```

## Quick Start

### Create a Client

```swift
import AO3Kit

let client = AO3Client()
```

### Fetch a Work and Its Chapters

```swift
let fic = try await client.works.metadata(for: 12345678)
let chapters = try await client.works.allChapters(for: fic)
let epub = try await client.works.download(fic, format: .epub)
```

### Search & Filter Works

```swift
var filter = AO3WorkSearchFilter(
    fandoms: ["Original Work"],
    rating: .teenAndUpAudiences,
    sortColumn: .kudos
)
filter.complete = true
filter.excludedRatings = [.explicit]
filter.excludedTags = ["Major Character Death"]

// Global search
let searchPage = try await client.search.worksPage(filter: filter, page: 1)

// Or apply the same filter to a tag, user, pseud, or collection listing
let tagPage = try await client.works.page(from: .tag(name: "Fluff", filter: filter))
```

### Authenticate & Interact

```swift
try await client.account.login(username: username, password: password)

// Leave kudos, bookmark, or comment
try await client.works.leaveKudos(for: fic)
try await client.bookmarks.create(for: fic, draft: AO3BookmarkDraft(notes: "Loved this!", isRec: true))
try await client.works.postComment(on: fic, content: "Great chapter!", pseudName: pseudName)

// Fetch reading history & inbox
let markedForLater = try await client.account.historyPage(showMarkedForLater: true)
let inbox = try await client.account.inboxPage()
```

### Dissect AO3 URLs & Monitor Status

```swift
if let url = URL(string: "https://archiveofourown.org/works/12345678") {
    let endpoint = AO3Client.dissect(url: url)
    // .work(id: 12345678, route: .main)
}

let status = try await client.status.currentStatus()
```

## API Scopes Overview

| Scope | Description |
| --- | --- |
|  client.works| Work metadata, chapters, full works, downloads, kudos, comments (including guest & unreviewed moderation), hit counts, external works, and Work/Chapter CRUD (post, edit, edit tags, post draft, delete, import, orphan, reorder). |
| client.bookmarks | Paginated bookmarks (user, pseud, collection, tag, series, external work, global recent, filtered), work bookmark previews, single bookmark fetch, CRUD, and adding bookmarks to collections. |
| client.users | Public user profiles, pseuds, user & pseud series, and user collections. |
| client.collections | Collection profiles, subcollections, browsing, open challenges, fandoms, tags, people/participants, prompts/requests, and join/leave. |
| client.series | Series metadata, edit, delete, work reordering, and co-creatorship removal. |
| client.search | Works, bookmarks, tags, and people search plus all 21 AO3 autocomplete endpoints. |
| client.tags | Canonical tag details (parents, synonyms, metatags, subtags, children) and Tag Atom feeds. |
| client.browse | Top-level media categories, fandom directories, unassigned fandoms, and supported languages. |
| client.news | AO3 Admin Posts (news and announcements). |
| client.account | Auth/session, inbox, history/marked-for-later, subscriptions, muted/blocked users, favorite tags, site/work skins (list, details/CSS, preview, set/unset, CRUD), preferences, profile & pseuds CRUD, drafts, collected works, related works, co-creator requests, gift accept/refuse, collection item invites, challenge dashboard (signups, assignments, claims, tag sets, nominations), credentials/password reset, and invitations. |
| client.site | FAQ categories & pages, known issues, static pages (ToS, Privacy, About, etc.), abuse reports, and support requests. |
| client.images | Fetching and memory/disk caching for avatars, icons, and embedded images. |
| client.status | OTW/AO3 operational status, uptime history, and recent incidents from [otwstatus.org](https://www.otwstatus.org). |

## License

MIT - See [LICENSE](LICENSE) for details.
