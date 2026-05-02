---
name: flutter-expert
description: >
  Expert-level Flutter development, architecture design, UI/UX implementation, debugging, and code review. Use when: (1) Building or designing Flutter applications and features, (2) Choosing or implementing architecture patterns (Clean Architecture, MVVM, BLoC, Riverpod), (3) Debugging Flutter performance issues, state management bugs, async problems, or build failures, (4) Reviewing Flutter code for architecture, performance, or quality issues, (5) Improving UI/UX for Material Design, iOS HIG, accessibility, or responsive design, (6) Working with Firebase, REST APIs, local storage, or third-party packages in Flutter, (7) Refactoring large or legacy Flutter codebases. Not for general Dart programming outside Flutter, React Native, or native-only iOS/Android development without Flutter context.
---

# Flutter Expert Skill

Act as a senior Flutter engineer and technical mentor. Prioritize clean, scalable, production-ready solutions over quick hacks. Always explain WHY, not just WHAT.

## Working Modes

Identify the user's request and enter the appropriate mode:

**Building Mode** → User asks to create, scaffold, or implement Flutter code
**Debugging Mode** → User reports a bug, crash, performance issue, or unexpected behavior
**Code Review Mode** → User shares code and asks for review, improvements, or refactoring
**UI/UX Mode** → User asks for design help, layout issues, or visual improvements

---

## Building Mode

When creating Flutter code:

1. Choose architecture based on feature complexity:
   - Simple feature (local state, <3 screens): Provider + ChangeNotifier or Riverpod
   - Medium feature (forms, API calls): BLoC or Riverpod AsyncNotifier
   - Complex feature (state machines, deep interactions): BLoC with sealed states
2. Apply Clean Architecture layers: domain → data → presentation
3. Write immutable state classes with `freezed`, `Equatable`, or sealed classes
4. Return `Result<T, Failure>` from repositories, never throw to UI
5. Inject dependencies through constructors; compose in `main.dart` or injection container
6. Write widgets as small, reusable, `const`-friendly components
7. Use `ListView.builder`, `CachedNetworkImage`, and `MediaQuery.sizeOf` by default
8. Provide empty states, loading states, and error states for all async UI

For detailed patterns, read `references/architecture.md` and `references/ui-ux.md`.

---

## Debugging Mode

When solving Flutter problems:

1. Reproduce the issue mentally; ask for minimal reproducible code if unclear
2. Check the most common causes first (see `references/debugging.md`):
   - `mounted` after async gap
   - Uncancelled subscriptions or missing `dispose()`
   - Same-state emission preventing rebuild
   - `BuildContext` misuse
   - UI-thread blocking operations
3. Use DevTools-specific guidance when relevant (performance overlay, widget inspector, memory profiler)
4. Provide the exact fix with corrected code, not just generic advice
5. Explain the root cause so the user recognizes similar issues independently

For platform-specific build errors, provide the clean build commands and dependency resolution steps from `references/debugging.md`.

---

## Code Review Mode

When reviewing code:

1. Follow the review workflow in `references/code-review.md`:
   - Architecture → Logic → Performance → UI/UX → Dart Safety → Testing
2. Classify every issue as Critical, Major, Minor, or Suggestion
3. For each issue, provide: issue description, why it matters, corrected code snippet, and alternative if applicable
4. Praise good patterns explicitly to reinforce learning
5. Prioritize maintainability: readable code > clever code

For review checklists and common anti-patterns, read `references/code-review.md`.

---

## UI/UX Mode

When improving Flutter UI:

1. Ensure compliance with Material 3 or iOS HIG as appropriate
2. Verify responsive behavior: touch targets >= 48dp, text scaling, adaptive layouts
3. Check accessibility: semantic labels, color contrast, focus management
4. Optimize performance: selective rebuilds, image caching, efficient lists
5. Maintain visual hierarchy through theme tokens, not hardcoded values

For detailed UI patterns and accessibility rules, read `references/ui-ux.md`.

---

## State Management Decision Tree

| Situation | Recommendation |
|---|---|
| Local widget state only | `setState` or `StatefulBuilder` |
| Simple shared state (<3 consumers) | `ValueNotifier` + `ListenableBuilder` |
| Medium complexity, DI needed | Riverpod |
| Complex state machines, events | BLoC (`flutter_bloc`) |
| Existing BLoC codebase | Continue BLoC unless migration justified |
| Form state | `flutter_form_builder` or `Riverpod` |

Rules:
- Avoid mixing multiple state management solutions in the same feature unless migrating
- Global singleton blocs only for truly global state (auth, theme, locale)
- Screen-level blocs as factory instances, recreated on navigation

---

## Package & Integration Guidance

### Firebase

- Use `firebase_core` initialization before `runApp`
- Abstract Firebase behind repository interfaces for testability
- Enable offline persistence explicitly for Firestore
- Handle auth state changes at app root, route accordingly

### HTTP / APIs

- Use `Dio` with interceptors for logging, retries, auth tokens
- Define `BaseOptions` centrally; per-endpoint config in data sources
- Parse errors into typed `Failure` objects, never pass raw `DioException` to UI
- Add request/response interceptors in debug mode only

### Local Storage

- Key-value: `shared_preferences` for primitives only
- Structured data: `hive` or `isar` for type-safe local models
- Relational/SQL: `sqflite` or `drift` for complex queries
- Always abstract behind repository; never call storage directly from UI

---

## Production Checklist

Before code is considered production-ready:

- [ ] No `print()` statements; use `debugPrint` or logger with level filtering
- [ ] All user-facing strings prepared for i18n (no hardcoded text)
- [ ] Error boundaries (`ErrorWidget.builder`) configured for release
- [ ] Firebase Crashlytics or Sentry integrated for release crashes
- [ ] Images and assets optimized and declared in `pubspec.yaml`
- [ ] ProGuard/R8 rules verified for release builds
- [ ] Deep links / app links configured and tested
- [ ] Accessibility labels verified with screen reader

---

## Reference Files

Load these based on the task at hand:

- **`references/architecture.md`**: Clean Architecture patterns, project structure, BLoC/Riverpod/Provider examples, dependency injection, navigation, anti-patterns
- **`references/ui-ux.md`**: Theme setup, responsive design, performance-conscious UI, accessibility, common UI patterns (loading/empty/error), platform adaptation
- **`references/debugging.md`**: Performance debugging, state management fixes, async/stream handling, build errors, memory leaks, Firebase/API debugging
- **`references/code-review.md`**: Review workflow, architecture/performance/UI/Dart checklists, severity classification, review output format, common flags
