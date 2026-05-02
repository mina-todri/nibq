# Flutter Architecture Reference

## Table of Contents
1. [Project Structure](#project-structure)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [State Management Patterns](#state-management-patterns)
4. [Dependency Injection](#dependency-injection)
5. [Navigation](#navigation)
6. [Common Anti-Patterns](#common-anti-patterns)

---

## Project Structure

Preferred structure for large-scale applications:

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── usecases/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── feature_name/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   └── another_feature/
├── config/
│   ├── routes/
│   └── theme/
└── main.dart
```

Rules:
- One feature = one directory with data/domain/presentation layers
- Core contains only cross-cutting concerns
- No feature imports from another feature's internal layers; use domain contracts

---

## Clean Architecture Layers

### Domain Layer (Innermost)

```dart
// entity.dart
class User extends Equatable {
  final String id;
  final String email;

  const User({required this.id, required this.email});

  @override
  List<Object?> get props => [id, email];
}

// repository_contract.dart
abstract class UserRepository {
  Future<Result<User, Failure>> getUser(String id);
}

// usecase.dart
class GetUserUseCase {
  final UserRepository repository;
  GetUserUseCase(this.repository);

  Future<Result<User, Failure>> call(String id) => repository.getUser(id);
}
```

Rules:
- Domain has NO dependencies on Flutter, data sources, or UI
- Entities use `Equatable` or `freezed` for value equality
- Usecases are single-responsibility and testable
- Return `Result<T, Failure>` (either dartz or custom sealed class) instead of throwing exceptions

### Data Layer

```dart
// model.dart
class UserModel extends User {
  const UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(id: json['id'], email: json['email']);

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}

// repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remote;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({required this.remote, required this.networkInfo});

  @override
  Future<Result<User, Failure>> getUser(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = await remote.getUser(id);
      return Right(model);
    } on ServerException {
      return const Left(ServerFailure());
    }
  }
}
```

Rules:
- Models extend domain entities, never replace them in domain contracts
- Repository implementations handle exception-to-failure mapping
- Data sources (remote/local) are implementation details hidden behind repository

### Presentation Layer

```dart
// bloc.dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUser;

  UserBloc({required this.getUser}) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await getUser(event.id);
    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) => emit(UserLoaded(user: user)),
    );
  }
}

// state.dart (sealed class or freezed)
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = UserInitial;
  const factory UserState.loading() = UserLoading;
  const factory UserState.loaded(User user) = UserLoaded;
  const factory UserState.error(String message) = UserError;
}
```

Rules:
- Bloc/Cubit holds business logic, Widgets hold UI logic only
- States are immutable and exhaustive (sealed classes preferred)
- One bloc per feature screen, not one global bloc
- UI observes states; bloc observes events

---

## State Management Patterns

### BLoC (Complex Features)

When to use:
- Complex state machines
- Multiple interacting events
- Need for event transformation (debounce, throttle)
- Business logic reuse across widgets

```dart
// Good: Event-driven, state machine
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchIdle()) {
    on<SearchQueryChanged>(_onQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }
}
```

### Provider + ChangeNotifier (Medium Complexity)

When to use:
- Simple to medium state needs
- Form state
- Local widget-tree state

```dart
class CartNotifier extends ChangeNotifier {
  final List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);

  void addItem(Item item) {
    _items.add(item);
    notifyListeners();
  }
}
```

### Riverpod (Modern Alternative)

When to use:
- Prefer compile-time safety over Provider
- Need autoDispose, family modifiers
- Want provider-to-provider dependencies

```dart
@riverpod
class AuthController extends _$AuthController {
  @override
  Future<AuthState> build() async {
    return ref.watch(authRepositoryProvider).checkAuth();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }
}
```

### setState (Local Only)

When to use:
- Truly local widget state (animations, toggles, counters)
- Never for shared or complex state

---

## Dependency Injection

Preferred: `get_it` + `injectable` or `get_it` manually.

```dart
// injection.dart
final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

// Register order matters: datasources -> repositories -> usecases -> blocs
void setup() {
  // External
  getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(baseUrl: API.baseUrl)));

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: getIt()),
  );

  // Usecases
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));

  // Blocs (factory - new instance each navigation)
  getIt.registerFactory(() => AuthBloc(loginUseCase: getIt()));
}
```

Rules:
- Register blocs as `registerFactory` (not singleton) unless truly global
- Register dependencies before UI initialization in `main.dart`
- Pass dependencies through constructor; never use `getIt()` inside business logic

---

## Navigation

### GoRouter (Recommended)

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'profile/:id',
          builder: (context, state) => ProfilePage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
```

Rules:
- Define all routes in one location
- Use path parameters for IDs, query parameters for filters
- Deep linking requires `android:host` / `associated domains` configuration
- Navigation logic belongs in presentation layer, not UI widgets directly

---

## Common Anti-Patterns

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Business logic in widgets | Untestable, rebuild triggers | Move to Bloc/Cubit/Controller |
| Direct `dio/http` calls in UI | Tight coupling, no error handling | Repository pattern with Failure types |
| `setState` for app-wide state | Prop drilling, rebuild cascades | InheritedWidget, Provider, or Bloc |
| Mutable entities | Bugs from shared references | Immutable models with `copyWith` |
| Exception throwing without handling | Crashes | Return `Result<T, Failure>` types |
| God classes (2000+ line widgets) | Unmaintainable | Extract widgets, composition |
| Nested `FutureBuilder`/`StreamBuilder` | Spaghetti async UI | Bloc with state machine |
| `BuildContext` across async gaps | `mounted` check errors | Use `mounted` guard or state management |
