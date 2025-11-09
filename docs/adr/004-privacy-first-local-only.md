# ADR-004: Privacy-First, Local-Only Data Storage

## Status

Accepted

## Context

TrackMe collects sensitive location data from users as they track their movements. Location data is highly personal and sensitive information. We needed to establish clear principles around data handling, storage, and privacy.

Key considerations:

- Users need confidence their location data is private
- Growing privacy regulations (GDPR, CCPA, etc.)
- Apple's privacy-focused ecosystem and App Store requirements
- Potential for misuse of location data if transmitted or stored remotely
- User trust is paramount for an app collecting location data

## Decision

TrackMe will be **privacy-first** and **local-only** by default:

- All location data is stored exclusively on the user's device using Core Data
- No network transmission of location data to external servers
- No analytics or tracking services integrated
- No user accounts or cloud sync (unless explicitly added with user consent in future)
- Users maintain complete control and ownership of their data
- Data can be exported for user's own use

## Consequences

### Positive

- Maximum user privacy and trust
- Compliance with privacy regulations by design
- No server infrastructure needed (reduced cost and complexity)
- No data breach risk from remote servers
- Faster app approval from Apple App Store
- App works completely offline
- Clear competitive differentiator in privacy-conscious market

### Negative

- No cross-device sync without user-managed export/import
- Cannot provide cloud backup automatically
- Limited ability to gather usage analytics for improvement
- Users responsible for their own backups
- Cannot offer server-side features (social sharing, collaborative tracking, etc.)

### Neutral

- Must clearly communicate privacy benefits to users
- Export functionality becomes critical for data portability
- Future features requiring sync need explicit user opt-in

## Alternatives Considered

**Cloud Sync**: Better user experience for multi-device users, but introduces privacy risks, server costs, and complexity.

**Opt-in Analytics**: Could help improve the app, but risks user trust and adds external dependencies.

**Hybrid (Local + Optional Cloud)**: More flexible but more complex to implement and explain to users.

## Notes

This decision aligns with Apple's privacy initiatives and our core values. Any future features requiring data transmission (e.g., share a trip with a friend) must be explicit, opt-in, and clearly explained to users.

The Copilot instructions explicitly state: "No external analytics or tracking" and "All data is local by default."

---

**Date**: 2025-11-09  
**Author**: Eric  
**Last Updated**: 2025-11-09
