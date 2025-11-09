# Architecture Decision Records (ADR)

This directory contains Architecture Decision Records (ADRs) for the TrackMe project. ADRs document important architectural decisions, their context, rationale, and consequences.

## What is an ADR?

An Architecture Decision Record captures a single architectural decision. Each ADR describes the context, the decision made, and the consequences of that decision.

## ADR Index

| Number | Title | Status | Date |
|--------|-------|--------|------|
| [001](001-adopt-swiftui-only.md) | Adopt SwiftUI-Only for User Interface | Accepted | 2025-11-09 |
| [002](002-core-data-persistence.md) | Use Core Data for Local Persistence | Accepted | 2025-11-09 |
| [003](003-mvvm-architecture.md) | Adopt MVVM Architecture Pattern | Accepted | 2025-11-09 |
| [004](004-privacy-first-local-only.md) | Privacy-First, Local-Only Data Storage | Accepted | 2025-11-09 |
| [005](005-centralized-location-management.md) | Centralized Location Management | Accepted | 2025-11-09 |
| [006](006-centralized-configuration-management.md) | Centralized Configuration Management | Accepted | 2025-11-09 |
| [007](007-dependency-injection-repositories.md) | Adopt Dependency Injection with Protocol-Based Repositories | Accepted | 2025-11-09 |

## Creating a New ADR

1. Copy the [template.md](template.md) file
2. Name it with the next sequential number: `NNN-brief-title.md`
3. Fill in all sections with relevant information
4. Update this index file to include the new ADR
5. Commit both the new ADR and updated index

## ADR Lifecycle

- **Proposed**: Under discussion, not yet decided
- **Accepted**: Decision has been made and is current
- **Deprecated**: No longer relevant but kept for historical context
- **Superseded**: Replaced by a newer ADR (reference the new one)

## Format

Each ADR follows a consistent structure:

- **Status**: Current state of the decision
- **Context**: The situation and problem being addressed
- **Decision**: What was decided and why
- **Consequences**: Impact of the decision (positive, negative, neutral)
- **Alternatives Considered**: Other options that were evaluated
- **Notes**: Additional relevant information

## Related Documentation

- [Project README](../../README.md) - Project overview and setup instructions
- [Copilot Instructions](../../.github/copilot-instructions.md) - Development patterns and conventions
- [Things Todo](../../Things-todo.txt) - Current project tasks

## References

- [Michael Nygard's ADR template](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/templates/decision-record-template-by-michael-nygard/index.md)
- [ADR GitHub Organization](https://adr.github.io/)
