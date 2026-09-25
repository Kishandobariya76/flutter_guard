# Changelog

All notable changes to this project are documented in this file.

## 0.1.3

* Support links hide the UPI ID. Phones open a UPI app; desktops show a QR.

## 0.1.2

* README now includes developer details and UPI support (QR on desktop, `upi://` on phone).

## 0.1.1

* README documentation, contributing, security, and license entries now open the files on GitHub.

## 0.1.0

* Initial public release, published as `flutter_guard_sdk` because `flutter_guard` is too similar to the existing `flutter_guards` package on pub.dev.
* Network client with GET, POST, PUT, PATCH, DELETE, HEAD, custom methods, multipart upload, download, typed parsing, interceptors, timeouts, and cancellation.
* Retry engine with exponential backoff, jitter, and idempotent defaults.
* Concurrency-safe token refresh.
* In-flight request deduplication.
* Memory and persistent cache with TTL, tags, and cache policies including stale-while-revalidate.
* Offline queue, automatic sync, and conflict resolution strategies.
* Page, offset, and cursor pagination with duplicate `loadMore` protection.
* Diagnostics, structured logging, redaction, and performance metrics.
* In-app debug inspector.
* Local feature flags with rollout and targeting.
* Environment presets, lifecycle monitoring, debouncer, throttler, and `Result`.
* Complete example application that runs without a production backend.
