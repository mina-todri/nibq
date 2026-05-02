# Flutter UI/UX Reference

## Table of Contents
1. [Design System Setup](#design-system-setup)
2. [Responsive & Adaptive Design](#responsive--adaptive-design)
3. [Performance-Conscious UI](#performance-conscious-ui)
4. [Accessibility](#accessibility)
5. [Common UI Patterns](#common-ui-patterns)
6. [Platform Adaptation](#platform-adaptation)

---

## Design System Setup

### Theme Configuration

Define all design tokens in `ThemeData`:

```dart
class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A73E8),
        secondary: Color(0xFF00C853),
        surface: Colors.white,
        error: Color(0xFFD50000),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: const Color(0xFF202124),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
```

Rules:
- Never hardcode colors/sizes in widgets; always reference theme
- Use `ColorScheme` (Material 3) over individual color properties
- Define component-level themes (ButtonTheme, InputDecorationTheme) for consistency
- Support dark mode with a parallel `dark` theme

### Custom Widgets

```dart
// Reusable card component
class InfoCard extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onTap;

  const InfoCard({
    required this.title,
    required this.content,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
```

Rules:
- Every custom widget accepts `super.key`
- Extract reusable components early; avoid copy-paste UI
- Pass callbacks, not logic; keep widgets declarative

---

## Responsive & Adaptive Design

### Layout Patterns

```dart
// Adaptive layout: master-detail on tablet, single on phone
class AdaptiveLayout extends StatelessWidget {
  final Widget listPane;
  final Widget detailPane;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) {
      return Row(
        children: [
          SizedBox(width: 360, child: listPane),
          Expanded(child: detailPane),
        ],
      );
    }
    return listPane; // Use navigation to detail on phone
  }
}
```

Rules:
- Use `LayoutBuilder` or `MediaQuery.sizeOf` (avoids rebuild on system UI changes)
- Prefer `MediaQuery.sizeOf(context)` over `MediaQuery.of(context).size` (selective rebuilds)
- Breakpoints: compact < 600, medium 600-840, expanded > 840

### Text Scaling

```dart
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineSmall,
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)
```

Rules:
- All text uses theme typography scales (not fixed sizes)
- Test with largest font size (Settings > Accessibility > Font size)
- Constrain max lines and handle overflow with ellipsis

---

## Performance-Conscious UI

### List Optimization

```dart
ListView.builder(
  itemCount: items.length,
  // Essential for large lists
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      key: ValueKey(item.id), // Stable keys for animations
      title: Text(item.name),
    );
  },
)
```

Rules:
- Always use `ListView.builder` (or `SliverList`) for >20 items
- Provide stable `key` for reordering/animations
- Never nest scrollable widgets of same direction without `shrinkWrap: true` + constraints

### Image Optimization

```dart
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 600, // Resize to display size
  placeholder: (context, url) => const SkeletonPlaceholder(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
)
```

Rules:
- Use `CachedNetworkImage` for remote images
- Specify `memCacheWidth`/`memCacheHeight` to reduce memory
- Provide placeholder and error widgets
- Use `Image.file` / `Image.memory` with `cacheWidth`/`cacheHeight` for local images

### Rebuild Optimization

```dart
// Bad: entire tree rebuilds when counter changes
Column(
  children: [
    const Header(), // rebuilds unnecessarily
    Text('$counter'), // only this needs rebuild
  ],
)

// Good: selective rebuild
Column(
  children: [
    const Header(), // constant, never rebuilds
    CounterText(value: counter), // localized rebuild
  ],
)
```

Rules:
- Extract `const` widgets to prevent rebuilds
- Use `Consumer`/`BlocBuilder`/`Selector` at the lowest possible level
- Prefer `Selector` or `BlocListener` when only action (not rebuild) needed

---

## Accessibility

### Semantics

```dart
Semantics(
  label: 'Submit payment form',
  button: true,
  child: ElevatedButton(
    onPressed: submit,
    child: const Text('Pay Now'),
  ),
)
```

Rules:
- All interactive elements have semantic labels
- Use `MergeSemantics` to group related text
- Test with TalkBack (Android) and VoiceOver (iOS)

### Contrast & Touch

- Minimum touch target: 48x48 dp (Material) / 44x44 pt (iOS)
- Text contrast ratio: 4.5:1 for normal text, 3:1 for large text
- Never rely on color alone to convey meaning; use icons + text

### Form Accessibility

```dart
TextField(
  decoration: const InputDecoration(
    labelText: 'Email',
    helperText: 'We will never share your email.',
    errorText: 'Please enter a valid email address.',
  ),
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
)
```

Rules:
- Always provide `labelText` or `hintText`
- Use correct `keyboardType` and `textInputAction`
- Show `errorText` with clear, actionable messages

---

## Common UI Patterns

### Loading States

```dart
class AsyncButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
```

Rules:
- Disable button during loading; show inline indicator
- Never show blocking dialog for short operations (<300ms)
- Use skeleton screens for initial page loads

### Empty & Error States

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

Rules:
- Empty states explain WHY it's empty and what to do next
- Error states distinguish retryable vs fatal errors
- Use consistent empty/error widgets across the app

---

## Platform Adaptation

### Material vs. Cupertino

```dart
class PlatformAdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoButton(onPressed: onPressed, child: child);
    }
    return ElevatedButton(onPressed: onPressed, child: child);
  }
}
```

Rules:
- Use Material 3 as default; adapt to Cupertino only when justified
- Platform-specific adaptations belong in core/widgets, not scattered in features
- Respect `Theme.of(context).platform` for testing/simulator contexts

### Safe Area & System UI

```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    ),
  ),
)
```

Rules:
- Always wrap content in `SafeArea` unless intended to bleed into status bar
- Use `SystemUiOverlayStyle` to set light/dark status bar icons
- Handle keyboard insets with `MediaQuery.viewInsetsOf(context)` or `KeyboardVisibilityBuilder`
