# 🏛️ LIFT — Master Architectural Breakdown (8 Chunks)

**Project:** `nibq` (LIFT) — Flutter + Riverpod + Firebase (Auth/Firestore/Storage), RTL Arabic UI, Material 3 themed.
**Total `lib/` files analyzed:** ~50. **Stack:** `flutter_riverpod 2.4`, `firebase_core 4.x`, `cloud_firestore 6.x`, `firebase_auth 6.x`, `image_picker`, `intl`, `shared_preferences`.

**Global structural observations (apply across chunks):**
- **Two settings providers exist** (`features/settings/settings_provider.dart` AND `features/settings/providers/settings_provider.dart`) — one is local-prefs (theme/locale), the other Firestore global (delivery fee, discount). This duplication will bite later — clarify naming.
- The codebase uses **legacy `StateNotifier`** (cart, favorites, settings) but `pubspec.yaml` declares `riverpod_annotation` + `riverpod_generator` — codegen is set up but not used. Pick one paradigm.
- **Routing is imperative `onGenerateRoute`** (no `go_router`). `home` is decided by `MaterialApp.home` (auth-aware), but protected-route guard duplicates that logic. There's a coupling/race issue between `home:` widget and `onGenerateRoute` guards.
- `firebase_options.dart` and `google-services.json` are committed. **Firestore `firestore.rules` is present** — must be audited alongside backend chunks.
- Many files contain `// FIXED:` headers — prior LLM passes have already touched things. Expect partial fixes / inconsistencies.

---

### Chunk 1: Core Foundation — Theme, Constants, Models

* **Objective:** Lock down the data contracts and design tokens. Every other chunk depends on these being stable, immutable, and JSON-roundtrip-safe.
* **Files Included:**
  - `lib/core/constants/app_constants.dart`
  - `lib/core/theme/app_colors.dart`, `app_radius.dart`, `app_spacing.dart`, `app_text_styles.dart`, `app_theme.dart`
  - `lib/core/models/user_model.dart`, `product_model.dart`, `cart_item_model.dart`, `order_model.dart`, `address_model.dart`
* **Current State/Issues:**
  - Models exist with `fromMap` / `toMap` but need verification of: nullable handling, Timestamp ↔ DateTime conversion, `copyWith`, `==`/`hashCode`, and enum (status) serialization on `OrderModel`.
  - `UserModel` likely carries `role` — must confirm it's read from Firestore, not derived client-side (security).
  - Theme is Material 3 with gold-on-dark luxury palette (`AppColors.gold400`, `surfBg`). Need to confirm `AppTheme.light` / `dark` both exist and `ColorScheme` is consistent.
* **Prompt Instructions for Claude:**
  > "You are reviewing the foundational layer of a Flutter luxury-goods app (LIFT). Attached are all files in `lib/core/models/` and `lib/core/theme/` plus `app_constants.dart`. (1) For every model: ensure immutability (`final` fields, `const` constructor where possible), add `copyWith`, `==`, `hashCode`, `toString`; make `fromMap` defensive against null/missing keys and properly convert Firestore `Timestamp` to `DateTime`. (2) For `OrderModel`, verify enum status (`pending/confirmed/shipped/delivered/cancelled`) serializes as a stable string. (3) For `UserModel`, ensure `role` is a typed enum with safe defaults (`UserRole.customer`). (4) For theme: confirm `AppTheme.light` and `AppTheme.dark` both expose a complete `ColorScheme`, AppBar/Card/Input themes, and Arabic-friendly `TextTheme` via `google_fonts`. Output diffs only."

---

### Chunk 2: Backend Services Layer (Firebase Repositories)

* **Objective:** Stabilize the Firestore/Storage/Auth I/O. These services must be pure (no Riverpod, no Flutter imports), deterministic, and testable.
* **Files Included:**
  - `lib/core/services/auth_service.dart`
  - `lib/core/services/order_repository.dart`
  - `lib/core/services/product_service.dart`
  - `firestore.rules` (audit alongside)
  - `lib/firebase_options.dart` (verify only)
* **Current State/Issues:**
  - `auth_service.dart` header claims it removed a hardcoded admin-email role — must confirm role assignment now reads `users/{uid}.role` from Firestore exclusively.
  - `order_repository.createOrder` was rewritten to fix a `Future.wait`-inside-transaction crash; needs a second pair of eyes on read-before-write ordering and idempotency check.
  - `product_service.dart` has `addProduct/updateProduct` with image upload — no error handling around Storage failures, no orphan-image cleanup on update.
  - `firestore.rules` must enforce: users can only read/write their own `carts/{uid}/...`, `favorites/{uid}/...`, `orders` only by owner (or admin), `products` write-only by admin role.
* **Prompt Instructions for Claude:**
  > "You are hardening the backend service layer of a Flutter+Firebase app. Attached: `auth_service.dart`, `order_repository.dart`, `product_service.dart`, and `firestore.rules`. Tasks: (1) Confirm `AuthService` never derives admin role from email/UID — only from Firestore user doc. Add a `Stream<UserModel?> userDocStream(uid)` if missing. (2) Audit `OrderRepository.createOrder`: all reads must precede all writes inside the transaction, no `Future.wait` inside `runTransaction`, idempotent on retry by checking order doc existence first, stock decrement uses `item.quantity`. (3) `ProductService`: wrap Storage uploads in try/catch, on `updateProduct` delete the previous image from Storage when replaced, return typed errors. (4) Rewrite `firestore.rules` so: `users/{uid}` self read/write (except `role`), `carts/{uid}/**` and `favorites/{uid}/**` self-only, `orders` readable by owner or admin, writable only via the create transaction, `products` and `settings/global` writable only when `request.auth.token.role == 'admin'` OR via `get(/databases/.../users/$(uid)).data.role == 'admin'`. Output the corrected files in full."

---

### Chunk 3: Riverpod State — Auth & Session

* **Objective:** Single source of truth for "who is the current user?" Every other provider depends on this.
* **Files Included:**
  - `lib/features/auth/providers/auth_provider.dart`
  - (consumes) `lib/core/services/auth_service.dart`, `lib/core/models/user_model.dart`
* **Current State/Issues:**
  - 367-line provider mixing `StateNotifier`, manual `AuthState` enum, and an `AuthStatus` value object. Also exposes `isAuthenticatedProvider` and `currentUserProvider` consumed widely.
  - Initial auth restoration timing is critical — `app.dart` shows `SplashScreen` while `state == initial || isLoading`. Confirm there's no race that leaves the app stuck on splash if Firebase init returns no user.
  - Error surface flows through a transient `errorMessage` cleared by the UI — fragile, prone to lost errors during fast nav.
* **Prompt Instructions for Claude:**
  > "You are refactoring the auth state layer of a Flutter+Riverpod+Firebase app. Attached: `auth_provider.dart` and the `AuthService` it depends on. Goals: (1) Replace the manual `AuthState` enum + `isLoading` flag with a single sealed class `AuthStatus` (`Initial | Loading | Authenticated(UserModel) | Unauthenticated | Error(String)`) — drive everything off `firebaseAuth.authStateChanges()` combined with the Firestore user-doc stream via `Stream.combine` or a `StreamProvider`. (2) Expose three providers: `authStatusProvider` (the sealed status), `currentUserProvider` (`UserModel?`), `isAdminProvider` (`bool`, derived from user.role). (3) Remove the transient `errorMessage` clearing pattern — surface errors via `AsyncValue` in action methods (signIn/signUp/signOut/resetPassword) returning `Future<void>` that throws, and let UI use `ref.read(...).method()` inside try/catch. (4) Ensure no race on cold start: splash shows only while `Initial`, never indefinitely. Provide the full rewritten file."

---

### Chunk 4: Routing, App Shell & Settings (Theme/Locale)

* **Objective:** Make navigation, language switching, and theming bulletproof and reactive.
* **Files Included:**
  - `lib/main.dart`, `lib/app.dart`
  - `lib/core/routing/app_router.dart`
  - `lib/features/settings/settings_provider.dart` (local: theme/locale via SharedPreferences)
  - `lib/features/settings/providers/settings_provider.dart` (Firestore: delivery fee/discount — note the duplicate path)
* **Current State/Issues:**
  - **Two files named `settings_provider.dart`** — one local prefs, one Firestore global. Confusing imports; rename one (e.g., `global_settings_provider.dart`).
  - `app.dart` uses both `MaterialApp.home` (auth-routed) AND `onGenerateRoute` with a `_protected` guard — overlap can cause double redirects when `pushNamed('/cart')` fires before auth state hydrates.
  - `AppRouter.onGenerateRoute` reads `isAuthenticated` once at MaterialApp build time — stale after logout while a route push is in flight.
  - RTL works via outer `Directionality` builder + `MaterialApp.locale` — verify both stay in sync; verify `supportedLocales` covers what `intl` formatters expect.
* **Prompt Instructions for Claude:**
  > "Attached: `main.dart`, `app.dart`, `core/routing/app_router.dart`, and BOTH `settings_provider.dart` files (local prefs + Firestore global). Tasks: (1) Rename `features/settings/providers/settings_provider.dart` → `global_settings_provider.dart` and update all imports. (2) In `app.dart`, stop mixing `home:` widget with `onGenerateRoute` auth guards — pick ONE strategy. Recommended: keep `home:` as the auth-driven root (Splash/Login/Home) and remove the `_protected` list; protected screens should be unreachable when unauthenticated because they're not in the nav graph from Login. OR migrate to `go_router` with a single `redirect` callback driven by `authStatusProvider`. State which you chose and why. (3) Confirm `MaterialApp.locale`, `themeMode`, and outer `Directionality` are all driven from the same `settingsProvider` state and that toggling Arabic↔English actually rebuilds `MaterialApp` (not just children). (4) Make `SettingsNotifier` persist via SharedPreferences asynchronously without blocking the first frame. Provide diffs."

---

### Chunk 5: Riverpod State — Commerce (Products, Cart, Favorites, Orders, Global Settings)

* **Objective:** Clean, leak-free, auth-scoped state for the shopping flow.
* **Files Included:**
  - `lib/features/product/providers/product_provider.dart`
  - `lib/features/cart/providers/cart_provider.dart`
  - `lib/features/favorites/providers/favorites_provider.dart`
  - `lib/features/checkout/providers/order_providers.dart`
  - `lib/features/settings/providers/settings_provider.dart` (global delivery/discount)
* **Current State/Issues:**
  - `product_provider.dart` is already cleaned (no double-buffered StateNotifier) ✅ — verify all consumers were migrated.
  - `CartNotifier` and `FavoritesNotifier` are family-scoped on `_uid` and listen directly to Firestore — good — but they're plain `StateNotifierProvider` constructed in screens. Need a `cartProvider`/`favoritesProvider` wrapper that auto-rebuilds on `currentUserProvider` change and disposes the old subscription.
  - No optimistic UI on add/remove; UI waits for Firestore round-trip.
  - `orderByIdProvider` is `FutureProvider.family` but never invalidated after `createOrder` — order success screen may show stale.
  - `globalSettingsProvider` has no error/empty fallback — if `settings/global` doc is missing, the stream emits a default but with `??` chains scattered; centralize defaults in `GlobalSettings.empty()`.
* **Prompt Instructions for Claude:**
  > "Attached: `product_provider.dart`, `cart_provider.dart`, `favorites_provider.dart`, `order_providers.dart`, and the global `settings_provider.dart`. Tasks: (1) Wrap `CartNotifier` and `FavoritesNotifier` in `StateNotifierProvider.autoDispose` that watches `currentUserProvider` so they recreate (and old subs cancel via `dispose`) on user change/logout. (2) Add optimistic updates: mutate local state first, then call Firestore; on failure, revert and surface error via a separate `cartErrorProvider`. (3) Add a `GlobalSettings.empty()` default and remove the inline `??` defaults in `fromMap`. (4) Ensure `userOrdersProvider` and `orderByIdProvider` are invalidated inside the checkout success flow. (5) Confirm there are no remaining consumers of the legacy `productProvider` shim — if any, migrate them to `filteredProductsProvider`. Output rewritten files."

---

### Chunk 6: Auth UI Screens

* **Objective:** Wire the auth screens to the new sealed `AuthStatus` and ensure UX (loading, errors, validation) is consistent.
* **Files Included:**
  - `lib/features/auth/login_screen.dart`
  - `lib/features/auth/signup_screen.dart`
  - `lib/features/auth/otp_screen.dart`
  - `lib/features/auth/forgot_password_screen.dart`
  - `lib/shared/widgets/app_text_field.dart`, `primary_button.dart`, `secondary_button.dart`, `otp_input_field.dart`
* **Current State/Issues:**
  - Likely still consume the old `authProvider` shape — must update after Chunk 3.
  - Form validation may be ad-hoc per screen; needs consistent regex for email, min-length for password, Arabic error messages.
  - OTP screen exists but Firebase phone auth wiring is unclear — confirm whether it's real `verifyPhoneNumber` flow or mocked.
* **Prompt Instructions for Claude:**
  > "Attached: all four auth screens (`login`, `signup`, `otp`, `forgot_password`) and the shared input widgets. Refactor every screen to: (1) Consume the new `authStatusProvider` (sealed class from Chunk 3) — show inline loading on the submit button, show errors via `SnackBar` returned from try/catch around `ref.read(authProvider.notifier).signIn(...)` calls, never via a transient errorMessage. (2) Extract a shared `AuthFormValidators` class (email, Arabic-friendly password rules, phone in `+9665XXXXXXXX` format). (3) For `OtpScreen`: confirm it uses `FirebaseAuth.verifyPhoneNumber` with `codeSent` → `PhoneAuthCredential`; if it's mocked, mark with TODO and a clear comment. (4) Ensure all text is RTL-correct and no hardcoded LTR layouts. Provide full rewrites."

---

### Chunk 7: Customer-Facing Feature Screens

* **Objective:** Productionize the shopping & profile UX.
* **Files Included:**
  - `lib/features/home/home_screen.dart`
  - `lib/features/product/product_detail_screen.dart`
  - `lib/features/cart/cart_screen.dart`
  - `lib/features/checkout/checkout_screen.dart`, `order_success_screen.dart`
  - `lib/features/favorites/favorites_screen.dart`
  - `lib/features/orders/orders_screen.dart`
  - `lib/features/profile/profile_screen.dart`, `edit_profile_screen.dart`
  - `lib/features/addresses/addresses_screen.dart`
  - `lib/features/search/search_screen.dart`
  - `lib/features/notifications/notifications_screen.dart`
  - `lib/features/about/about_screen.dart`, `lib/features/help/help_screen.dart`
  - `lib/features/settings/settings_screen.dart`
  - `lib/features/states/empty_state_example_screen.dart`, `error_state_screen.dart`
  - `lib/shared/widgets/bottom_nav_bar.dart`, `custom_app_bar.dart`, `product_card.dart`, `loading_widget.dart`, `empty_state_widget.dart`, `error_state_widget.dart`, `price_summary_row.dart`
* **Current State/Issues:**
  - These screens consume providers reshaped in Chunks 3 & 5 — every `AsyncValue` needs `.when(data, loading, error)` (or `whenData`) with proper empty/error states using the existing `EmptyStateWidget` / `ErrorStateWidget`.
  - Checkout flow needs to: read `globalSettingsProvider` for delivery + discount, build `OrderModel`, call `OrderRepository.createOrder`, invalidate `userOrdersProvider`, navigate to `OrderSuccessScreen` with the order id as argument.
  - `ProductDetailScreen` receives `arguments` via `RouteSettings` — type-cast it safely.
  - `BottomNavBar` likely hardcodes route names — keep in sync with `AppRouter` constants.
* **Prompt Instructions for Claude:**
  > "Attached: all customer feature screens under `lib/features/` (excluding `admin/` and `auth/`) plus all shared widgets. For each screen: (1) Replace any direct `.value` access on `AsyncValue` with `.when(data:, loading: () => LoadingWidget(), error: (e,_) => ErrorStateWidget(...))`. (2) Empty lists must render `EmptyStateWidget` with Arabic copy. (3) `CheckoutScreen`: assemble `OrderModel` using cart + global delivery fee + applied discount code; on success invalidate `cartProvider`, `userOrdersProvider`, navigate to `/order-success` with the new order id; surface transaction errors as SnackBars in Arabic. (4) Type-safe `RouteSettings.arguments` parsing — never raw `as`, always `is` check + fallback. (5) Confirm `BottomNavBar` items reference `AppRouter` route constants (no hardcoded strings). Provide rewritten screens with diffs."

---

### Chunk 8: Admin Panel & Role-Gated Surfaces

* **Objective:** Lock down admin UI behind real role checks (Firestore + rules), wire CRUD to `ProductService`, surface inventory/orders.
* **Files Included:**
  - `lib/features/admin/admin_dashboard_screen.dart`
  - `lib/features/admin/admin_panel_screen.dart`
  - `lib/features/admin/admin_inventory_screen.dart`
  - `lib/features/admin/admin_orders_screen.dart`
  - `lib/features/admin/admin_settings_screen.dart`
  - `lib/features/admin/add_edit_product_screen.dart`
* **Current State/Issues:**
  - Admin route (`/admin`) is NOT in the `_protected` list in `AppRouter` — anyone hitting `Navigator.pushNamed(context, '/admin')` lands on the dashboard regardless of role. **Critical bug.**
  - Admin screens must consume `isAdminProvider` from Chunk 3 and bounce non-admins to `/home`.
  - `add_edit_product_screen.dart` uses `image_picker` + `ProductService.addProduct/updateProduct` — must handle large images, show upload progress, and prevent double-submit.
  - `admin_orders_screen.dart` should use a Firestore query ordered by `createdAt desc`, paginated; admin order status changes should go through a dedicated repository method (not direct Firestore writes from UI).
  - `admin_settings_screen.dart` writes to `settings/global` — needs admin-only Firestore rule (Chunk 2) AND a UI-side guard.
* **Prompt Instructions for Claude:**
  > "Attached: all six admin screens, plus `auth_provider.dart`, `app_router.dart`, `product_service.dart`, `order_repository.dart`. Tasks: (1) Add the `/admin` route (and any sub-routes) to the protected list in `AppRouter`, AND in each admin screen's `build`, watch `isAdminProvider` — if false, immediately `WidgetsBinding.instance.addPostFrameCallback` redirect to `/home` and show an Arabic 'unauthorized' SnackBar. (2) `AddEditProductScreen`: disable the submit button while uploading, show a `LinearProgressIndicator` from a `StateProvider<double>` updated by the Storage upload task, prevent submission if image > 5 MB. (3) `AdminOrdersScreen`: extend `OrderRepository` with `Stream<List<OrderModel>> watchAllOrders({int limit})` and a `Future<void> updateOrderStatus(orderId, status)`; consume both. (4) `AdminSettingsScreen`: reads/writes `settings/global` only via a new `GlobalSettingsRepository` (don't talk to Firestore from the widget). Output the new repository method signatures, the rewritten admin screens, and the updated router. Confirm Firestore rules from Chunk 2 enforce admin-only writes — if not, flag it."

---

## Suggested Execution Order
1️⃣ Foundation → 2️⃣ Backend → 3️⃣ Auth state → 4️⃣ Routing/Shell → 5️⃣ Commerce state → 6️⃣ Auth UI → 7️⃣ Customer UI → 8️⃣ Admin.
