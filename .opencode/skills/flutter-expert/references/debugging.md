# Flutter Debugging Reference

## Table of Contents
1. [Performance Debugging](#performance-debugging)
2. [State Management Issues](#state-management-issues)
3. [Async & Stream Issues](#async--stream-issues)
4. [Build & Compilation Issues](#build--compilation-issues)
5. [Memory Issues](#memory-issues)
6. [Firebase & API Debugging](#firebase--api-debugging)

---

## Performance Debugging

### Excessive Rebuilds

Symptom: UI lag, high CPU in DevTools.

Detection:
- Enable **Performance Overlay** (debug mode)
- Use **DevTools > Flutter Inspector > Highlight Repaints**
- Check `print` inside `build()` methods (should rarely print repeatedly)

Common causes & fixes:

| Cause | Fix |
|---|---|
| `setState()` in `build()` | Move to event handlers |
| `MediaQuery.of(context)` in large tree | Use `MediaQuery.xxxOf(context)` selective APIs |
| `BlocBuilder`/`Consumer` at top level | Move to lowest widget needing that state |
| `ListView` without `builder` | Use `ListView.builder` |
| Large images without cache constraints | Set `cacheWidth` / `cacheHeight` |

### Jank (UI Thread)

Symptom: Frame times > 16.6ms (60fps) or > 8.3ms (120fps).

Detection:
- **DevTools > Performance** > record and identify slow frames
- Red bars in performance overlay

Fix patterns:

```dart
// Bad: decode on UI thread
Image.memory(largeImageBytes)

// Good: async decode
FutureBuilder<ui.Image>(
  future: decodeImageFromList(largeImageBytes),
  builder: (context, snapshot) => /* display */,
)

// Better: isolate for heavy computation
final result = await compute(parseJson, largeJsonString);
```

Rules:
- JSON parsing > 1ms: use `compute()` or isolates
- Image decoding: use `ImageDescriptor` / `instantiateImageCodec` async APIs
- Layout calculations: cache or use `CustomPainter` for complex drawing

---

## State Management Issues

### BLoC Not Emitting

Symptom: UI doesn't update after event.

Checklist:
1. Is the same bloc instance being listened to? (Factory vs Singleton)
2. Is `emit()` being called after `await` without `yield`/`emit` in older versions?
3. Is the state class properly equatable? (Same instance won't trigger rebuild)

```dart
// Bad: emitting same instance
emit(state); // no rebuild if state == previous

// Good: new instance
emit(state.copyWith(isLoading: true));

// Good: freezed/immutable pattern
emit(state.copyWith(isLoading: true));
```

### Context Misuse

Symptom: `Looking up a deactivated widget's ancestor` / `BuildContext across async gap`.

```dart
// Bad: using context after async gap
onPressed: () async {
  await Future.delayed(Duration(seconds: 1));
  Navigator.of(context).pop(); // CRASH if widget disposed
}

// Good: check mounted
onPressed: () async {
  await Future.delayed(Duration(seconds: 1));
  if (!context.mounted) return;
  Navigator.of(context).pop();
}

// Better: use NavigationKey or state management
```

Rules:
- Always check `context.mounted` after `await` before using context
- Prefer navigation through router/state management over direct `BuildContext` passing
- Never store `BuildContext` in long-lived objects

---

## Async & Stream Issues

### Stream Leaks

Symptom: Memory leaks, callbacks after widget disposed.

```dart
// Bad: subscription never cancelled
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = stream.listen((data) => setState(() => _data = data));
  }
  // Missing dispose!
}

// Good: always cancel
@override
void dispose() {
  _sub?.cancel();
  super.dispose();
}

// Better: use StreamBuilder or Bloc (managed lifecycle)
StreamBuilder(
  stream: myStream,
  builder: (context, snapshot) => /* UI */,
)
```

Rules:
- Every `listen()` must have a corresponding `cancel()`
- Prefer framework-managed streams (`StreamBuilder`, `BlocListener`)
- Use `StreamSubscription` as nullable with null-aware cancel

### FutureBuilder Snapshots

```dart
// Bad: doesn't handle all states
FutureBuilder(
  future: apiCall,
  builder: (context, snapshot) {
    if (snapshot.hasData) return Success(data: snapshot.data!);
    return const CircularProgressIndicator(); // missing error, null data
  },
)

// Good: exhaustive states
FutureBuilder(
  future: apiCall,
  builder: (context, snapshot) {
    return switch (snapshot.connectionState) {
      ConnectionState.waiting => const LoadingWidget(),
      ConnectionState.done => switch (snapshot.hasError) {
        true => ErrorWidget(error: snapshot.error!),
        false => DataWidget(data: snapshot.data!),
      },
      _ => const SizedBox.shrink(),
    };
  },
)
```

Rules:
- Always handle `ConnectionState.waiting`, `done`, and error
- Don't assume `snapshot.data` non-null just because `hasData` is true
- Create the future in `initState` / `didChangeDependencies`, not in `build`

---

## Build & Compilation Issues

### Common Build Failures

| Error | Cause | Fix |
|---|---|---|
| `Duplicate class` / `Dex merger` | Dependency version conflict | `./gradlew app:dependencies` + exclude conflicting module |
| `CocoaPods could not find compatible versions` | iOS min version / podspec conflict | `pod update`, check `platform :ios` in Podfile |
| `AAPT2 error` | Invalid resource names | No uppercase or special chars in drawable names |
| `Entrypoint file not found` | `main.dart` moved | Update `lib/main.dart` path in build config |
| `Module was compiled with incompatible Kotlin version` | Kotlin plugin mismatch | Update `android/build.gradle` ext.kotlin_version |

### Clean Build Commands

```bash
# Android
flutter clean && flutter pub get
cd android && ./gradlew clean && cd ..

# iOS
flutter clean && flutter pub get
cd ios && rm -rf Podfile.lock Pods && pod install --repo-update && cd ..

# All platforms
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
cd ios && rm -rf Podfile.lock Pods && pod install --repo-update && cd ..
```

---

## Memory Issues

### Detection

- **DevTools > Memory**: watch for continuous growth
- **DevTools > Heap Snapshot**: identify object retention
- Enable `debugPrintRebuildDirtyWidgets` to catch excessive builds

### Common Leaks

| Cause | Fix |
|---|---|
| `Image.network` without cache eviction | Use `CachedNetworkImage` with `cacheManager` limit |
| `StreamSubscription` not cancelled | Cancel in `dispose()` |
| `ScrollController` / `PageController` | `dispose()` in state |
| Large data in global singletons | Use `clear()` / LRU eviction |
| `TickerProviderStateMixin` on widgets that navigate away | Use `SingleTickerProviderStateMixin` and dispose |

---

## Firebase & API Debugging

### Firebase

```dart
// Enable debug logging
await Firebase.initializeApp();
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// View reads/writes: Firebase Console > Firestore > Usage
```

Common issues:
- **Offline writes not syncing**: Check `Settings.persistenceEnabled`
- **Permission denied**: Check Firestore rules, not client code
- **Slow queries**: Add composite indexes (follow error link in console)

### API Debugging

```dart
// Add Dio interceptor for logging
final dio = Dio();
if (kDebugMode) {
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => debugPrint(obj.toString()),
  ));
}
```

Patterns:
- Log request/response in debug mode only
- Parse error bodies into typed Failure objects
- Retry with exponential backoff for transient failures
- Never expose API keys in client-side logs
