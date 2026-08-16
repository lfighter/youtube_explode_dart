# Fork notes

Fork of [Hexer10/youtube_explode_dart](https://github.com/Hexer10/youtube_explode_dart)
carrying discovery fixes that upstream has not merged. Consumed by the
`gallery` app as a sibling path dependency (`path: ../youtube_explode_dart`),
the same convention it uses for `../headless_webview`.

Branch: **`gallery-fixes`**, based on upstream `master` @ `44a39a6` (v3.1.0,
2026-05-09 — the newest release).

## Why this fork exists

Upstream is effectively stalled: last commit 2026-05-09, 62 open issues, and
five open PRs (four of them fixes) with none merged. Three of the four video
discovery modes the gallery uses were broken as of 2026-08-16.

## What is applied

| Commit | Origin | Fixes |
| --- | --- | --- |
| `4ddda22` | upstream PR [#383](https://github.com/Hexer10/youtube_explode_dart/pull/383) | `channels.getUploads` returned an empty stream — YouTube moved to `lockupViewModel` |
| `d0e3b60` | upstream PR [#380](https://github.com/Hexer10/youtube_explode_dart/pull/380) | `playlists.getVideos` returned an empty stream — same `lockupViewModel` change |
| `fd14836` | written here, **unreported upstream** | `NoSuchMethodError` on any search whose results include a live stream |

The third one is worth understanding: `getT` is an extension method on `Map`,
and Dart resolves extension methods *statically*. All three call sites in
`search_page.dart` invoked it on a `dynamic` receiver (an element of a
`List<dynamic>`), so it compiled to a dynamic invocation and threw at runtime.
That branch is only reached when `viewCountText` carries `runs` instead of
`simpleText` — which is what live streams produce — so broad queries like
"music" or "news" failed every time while narrow ones worked.

## Deliberately not applied

- PR [#385](https://github.com/Hexer10/youtube_explode_dart/pull/385)
  (`getRelatedVideos`, shorts) — touches 20 files including the example app's
  Gradle setup, and conflicts with #383 in `channel_upload_page.dart`.
  `getRelatedVideos` does return results here; see the `Streamed`/`PREMIERE`
  note below for the part that actually bites.
- PR [#382](https://github.com/Hexer10/youtube_explode_dart/pull/382) (bumps
  the hardcoded WEB client version) — its own author says they could not
  reproduce the problem it fixes.

## Known remaining problems

- Upstream issue [#309](https://github.com/Hexer10/youtube_explode_dart/issues/309):
  items labelled `PREMIERE` or `Streamed …` are fed to `int.parse`, throwing
  `FormatException`. Hits `getRelatedVideos` intermittently. The gallery
  tolerates it — `YtService.relatedTracks` catches and falls back to a keyword
  search — so autoplay degrades rather than breaking.

## Updating

```bash
git fetch origin
git rebase origin/master        # replay these commits onto a newer upstream
```

Then re-run the gallery's discovery health check:

```bash
cd ../gallery
~/flutter/bin/flutter test test/yt/yt_discovery_live_test.dart --dart-define=YT_LIVE=true
```
