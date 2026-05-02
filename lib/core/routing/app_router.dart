class AppRouter {
  // Auth
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  // Main
  static const home = '/';
  static const productList = '/products';
  static const productDetail = '/products/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';

  // Profile
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const addresses = '/addresses';
  static const favorites = '/favorites';
  static const settings = '/settings';
  static const notifications = '/notifications';

  // Admin
  static const adminDashboard = '/admin';
  static const adminProducts = '/admin/products';
  static const adminOrders = '/admin/orders';
  static const adminInventory = '/admin/inventory';
  static const adminSettings = '/admin/settings';
  static const addEditProduct = '/admin/products/:id';

  // Other
  static const about = '/about';
  static const help = '/help';

  AppRouter._();
}
