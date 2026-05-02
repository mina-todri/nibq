// lib/core/routing/app_router.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/addresses/addresses_screen.dart';
import '../../features/help/help_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/about/about_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static ProviderContainer? container;

  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String forgot = '/forgot';
  static const String home = '/home';
  static const String product = '/product';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String orders = '/orders';
  static const String addresses = '/addresses';
  static const String notifications = '/notifications';
  static const String about = '/about';
  static const String help = '/help';
  static const String admin = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final isAuthenticated = container?.read(isAuthenticatedProvider) ?? false;
    final isAdminUser = container?.read(isAdminProvider) ?? false;

    switch (s.name) {
      case login:        return _fade(const LoginScreen(), name: login);
      case signup:       return _fade(const SignupScreen(), name: signup);
      case otp:          return _fade(const OtpScreen(), name: otp);
      case forgot:       return _fade(const ForgotPasswordScreen(), name: forgot);
      case home:         return _fade(const HomeScreen(), name: home);
      case product:      return _fade(const ProductDetailScreen(), name: product, arguments: s.arguments);
      
      case cart:         
        return _guarded(const CartScreen(), name: cart, isAuthenticated: isAuthenticated);
      case checkout:     
        return _guarded(const CheckoutScreen(), name: checkout, isAuthenticated: isAuthenticated);
      case orderSuccess: 
        return _guarded(const OrderSuccessScreen(), name: orderSuccess, isAuthenticated: isAuthenticated, arguments: s.arguments);
      case profile:      
        return _guarded(const ProfileScreen(), name: profile, isAuthenticated: isAuthenticated);
      case editProfile:  
        return _guarded(const EditProfileScreen(), name: editProfile, isAuthenticated: isAuthenticated);
      case AppRouter.settings: 
        return _fade(const SettingsScreen(), name: AppRouter.settings);
      case search:       return _fade(const SearchScreen(), name: search);
      case favorites:    
        return _guarded(const FavoritesScreen(), name: favorites, isAuthenticated: isAuthenticated);
      case orders:       
        return _guarded(const OrdersScreen(), name: orders, isAuthenticated: isAuthenticated);
      case addresses:    
        return _guarded(const AddressesScreen(), name: addresses, isAuthenticated: isAuthenticated);
      case notifications:
        return _guarded(const NotificationsScreen(), name: notifications, isAuthenticated: isAuthenticated);
      case about:        return _fade(const AboutScreen(), name: about);
      case help:         return _fade(const HelpScreen(), name: help);
      case admin:        
        return _guarded(const AdminDashboardScreen(), name: admin, isAuthenticated: isAuthenticated, requiresAdmin: true, isAdmin: isAdminUser);
      
      default:           
        debugPrint('[AppRouter] Unknown route: ${s.name}');
        return _fade(const LoginScreen(), name: login);
    }
  }

  static Route<dynamic> _guarded(
    Widget page, {
    required String name,
    required bool isAuthenticated,
    bool requiresAdmin = false,
    bool isAdmin = false,
    Object? arguments,
  }) {
    if (!isAuthenticated) {
      return _fade(const LoginScreen(), name: login);
    }
    if (requiresAdmin && !isAdmin) {
      return _fade(const HomeScreen(), name: home);
    }
    return _fade(page, name: name, arguments: arguments);
  }

  static PageRouteBuilder _fade(Widget page, {String? name, Object? arguments}) =>
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secondAnim) => page,
        settings: RouteSettings(name: name, arguments: arguments),
        transitionsBuilder: (ctx, anim, secondAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  static String getInitialRoute(bool isAuthenticated) =>
      isAuthenticated ? home : login;

  static void navigateToHome(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(home, (_) => false);

  static void navigateToLogin(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(login, (_) => false);
}
