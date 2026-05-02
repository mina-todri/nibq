# Flutter Code Review Reference

## Table of Contents
1. [Review Workflow](#review-workflow)
2. [Architecture Checklist](#architecture-checklist)
3. [Performance Checklist](#performance-checklist)
4. [UI/UX Checklist](#uiux-checklist)
5. [Dart Style & Safety](#dart-style--safety)
6. [Review Output Format](#review-output-format)

---

## Review Workflow

When reviewing Flutter code, follow this sequence:

1. **High-level architecture**: Layer separation, dependency direction, state management choice
2. **Business logic correctness**: Logic placement, error handling, edge cases
3. **Performance**: Build efficiency, image handling, list construction
4. **UI/UX**: Responsiveness, accessibility, visual consistency
5. **Dart specifics**: Null safety, async handling, type safety
6. **Testing**: Testability, actual test coverage, mock usage

---

## Architecture Checklist

### Layer Violations

- [ ] UI widgets do not import `dart:io` or HTTP clients directly
- [ ] Data models are not used as domain entities in usecase contracts
- [ ] No `BuildContext` passed into usecases/repositories
- [ ] No `import 'package:flutter/material.dart'` in domain/data layers

### State Management

- [ ] State class is immutable (`final` fields, `copyWith` or code generation)
- [ ] Bloc/Cubit does not hold UI-specific data (focus nodes, scroll controllers)
- [ ] Events are named as past-tense actions (`UserLoaded`, `FormSubmitted`)
- [ ] `BlocListener` used for side effects; `BlocBuilder` used for UI rebuilds only
- [ ] `build()` method has no side effects (no `add()` calls)

### Dependency Injection

- [ ] Dependencies injected through constructors, not global variables
- [ ] `get_it` lookups happen at composition root, not inside business logic
- [ ] Blocs registered as factory when tied to screen lifecycle

---

## Performance Checklist

- [ ] `ListView.builder` used for dynamic/long lists
- [ ] Keys provided to list items when list can reorder
- [ ] `const` constructor used for stateless widgets where possible
- [ ] Images specify `cacheWidth`/`cacheHeight` or use `CachedNetworkImage`
- [ ] No `setState` in `build()` or inside animation listeners
- [ ] `MediaQuery.xxxOf(context)` used instead of full `MediaQuery.of(context)`
- [ ] No heavy computation on UI thread (JSON parsing, image processing)
- [ ] `Future`/`Stream` created in `initState`, not `build()`

---

## UI/UX Checklist

- [ ] Touch targets are at least 48x48 dp
- [ ] Text uses theme typography, not hardcoded sizes
- [ ] Error states show actionable messages, not raw exceptions
- [ ] Loading states prevent duplicate submissions
- [ ] Forms use correct `keyboardType` and `textInputAction`
- [ ] Accessibility labels on icons and custom interactive widgets
- [ ] Dark mode support verified (if required)
- [ ] SafeArea used where system UI can overlap

---

## Dart Style & Safety

- [ ] No `!` (bang operator) without null check; prefer `??` or early return
- [ ] `async` functions return `Future<void>`, not `void`
- [ ] `mounted` checked after `await` before using `context`
- [ ] Collections use `final` or `List.unmodifiable`
- [ ] `Equatable` or `freezed` used for value equality in states
- [ ] No implicit dynamic; explicit `dynamic` annotated when needed
- [ ] `const` used for constructors, collections, and widget constructors

---

## Review Output Format

When delivering code review feedback, use this structure:

### Severity Classification

- **Critical**: Bug, crash, or security issue. Must fix.
- **Major**: Architecture or performance problem. Should fix before merge.
- **Minor**: Style, readability, or maintainability. Fix when convenient.
- **Suggestion**: Alternative approach, not mandatory.

### Comment Format

```markdown
## [File: path/to/file.dart]

### [Severity] - [Category] - [Line Range]

**Issue:** One-line description of the problem.

**Why it matters:** Brief explanation of the risk or impact.

**Suggested fix:**
```dart
// Corrected code snippet
```

**Alternative:** If applicable, mention another valid approach.
```

### Example Review Comment

```markdown
## [File: lib/features/auth/presentation/bloc/auth_bloc.dart]

### Major - Architecture - Lines 23-30

**Issue:** `AuthBloc` directly imports `Dio` and constructs it internally.

**Why it matters:** Tight coupling to HTTP client makes testing impossible and violates Clean Architecture. Changing from Dio to HttpClient requires bloc changes.

**Suggested fix:**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase; // injected
  AuthBloc({required this.loginUseCase}) : super(AuthInitial());
}
```

**Alternative:** If simplicity is preferred, use a repository pattern at minimum.
```

---

## Common Patterns to Flag

### Flag Immediately (Critical/Major)

1. `BuildContext` used after async gap without `mounted` check
2. `setState` during `build()`
3. `ListView` (non-builder) with >20 items
4. Business logic inside `StatefulWidget`
5. Raw exceptions thrown to UI layer
6. Hardcoded strings for user-facing text (no i18n structure)
7. Missing `dispose()` for controllers, subscriptions, animations
8. Network calls without timeout or cancellation

### Flag for Discussion (Minor/Suggestion)

1. `StatefulWidget` where `StatelessWidget` + state management would suffice
2. Magic numbers without named constants
3. Deep widget nesting (>5 levels without extraction)
4. Inline `if/else` trees where `switch` or strategy pattern is clearer
5. `print()` instead of `debugPrint()` or logger
