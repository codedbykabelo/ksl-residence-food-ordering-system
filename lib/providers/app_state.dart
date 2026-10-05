import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  AppUser? currentUser;
  List<Meal> meals = [];
  List<CartItem> cart = [];
  List<Order> myOrders = [];
  List<Order> allOrders = [];
  List<Feedback> feedback = [];
  bool isLoading = false;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    await _databaseService.initialize();
    currentUser = await _databaseService.getCurrentUser();
    await refreshMeals();

    if (currentUser != null) {
      if (currentUser!.role == 'student') {
        await refreshOrders();
      } else if (currentUser!.role == 'staff') {
        await refreshAllOrders();
        await refreshFeedback();
      }
    }

    isLoading = false;
    notifyListeners();
  }

  double get cartTotal => cart.fold(
        0.0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );

  int get cartItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  Future<void> refreshMeals() async {
    meals = await _databaseService.getMeals();
    notifyListeners();
  }

  void addToCart(Meal meal, int quantity) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }
    if (!meal.available) {
      throw ArgumentError('This meal is currently unavailable.');
    }

    final existing = cart.where((item) => item.mealId == (meal.id ?? 0)).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += quantity;
    } else {
      cart.add(CartItem(
        mealId: meal.id ?? 0,
        mealName: meal.name,
        unitPrice: meal.price,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(int mealId, int delta) {
    final index = cart.indexWhere((item) => item.mealId == mealId);
    if (index == -1) return;

    final item = cart[index];
    final newQuantity = item.quantity + delta;
    if (newQuantity <= 0) {
      cart.removeAt(index);
    } else {
      item.quantity = newQuantity;
    }
    notifyListeners();
  }

  void removeFromCart(int mealId) {
    cart.removeWhere((item) => item.mealId == mealId);
    notifyListeners();
  }

  void clearCart() {
    cart = [];
    notifyListeners();
  }

  Future<void> registerStudent({
    required String studentNumber,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final createdUser = await _databaseService.registerStudent(
      studentNumber: studentNumber,
      fullName: fullName,
      email: email,
      password: password,
    );

    if (createdUser == null) {
      throw Exception('A student with that number or email already exists.');
    }

    notifyListeners();
  }

  Future<void> loginStudent(String email, String password) async {
    final user = await _databaseService.loginStudent(email, password);
    if (user == null) {
      throw Exception('Invalid email or password.');
    }

    currentUser = user;
    await _databaseService.persistCurrentUser(user);
    await refreshMeals();
    await refreshOrders();
    notifyListeners();
  }

  Future<void> loginStaff(String email, String password) async {
    final user = await _databaseService.loginStaff(email, password);
    if (user == null) {
      throw Exception('Invalid staff email or password.');
    }

    currentUser = user;
    await _databaseService.persistCurrentUser(user);
    await refreshAllOrders();
    await refreshFeedback();
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    cart = [];
    myOrders = [];
    allOrders = [];
    feedback = [];
    await _databaseService.clearCurrentUser();
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    if (currentUser == null || currentUser!.role != 'student') {
      myOrders = [];
      notifyListeners();
      return;
    }

    myOrders = await _databaseService.getOrdersForUser(currentUser!.id ?? 0);
    notifyListeners();
  }

  Future<void> refreshAllOrders() async {
    allOrders = await _databaseService.getAllOrders();
    notifyListeners();
  }

  Future<void> refreshFeedback() async {
    feedback = await _databaseService.getFeedback();
    notifyListeners();
  }

  Future<Order> placeOrder() async {
    if (currentUser == null) {
      throw Exception('You must be logged in to place an order.');
    }
    if (currentUser!.role != 'student') {
      throw Exception('Only student accounts can place orders.');
    }
    if (cart.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final order = await _databaseService.createOrder(
      userId: currentUser!.id ?? 0,
      items: cart,
    );

    clearCart();
    await refreshOrders();
    await refreshAllOrders();
    return order;
  }

  Future<void> updateOrderStatus(int orderId, String currentStatus, String nextStatus) async {
    if (!OrderStatusHelper.canAdvance(currentStatus, nextStatus)) {
      throw Exception('This status change is not allowed.');
    }

    await _databaseService.updateOrderStatus(orderId, nextStatus);
    await refreshAllOrders();
    await refreshOrders();
  }

  Future<void> submitFeedback({
    required int orderId,
    required int rating,
    required String comment,
  }) async {
    if (currentUser == null) {
      throw Exception('You must be logged in to rate an order.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5 stars.');
    }

    final existing = feedback.any((entry) => entry.orderId == orderId && entry.userId == currentUser!.id);
    if (existing) {
      throw Exception('Feedback has already been submitted for this order.');
    }

    await _databaseService.saveFeedback(
      orderId: orderId,
      userId: currentUser!.id ?? 0,
      rating: rating,
      comment: comment.trim(),
    );
    await refreshFeedback();
    await refreshOrders();
  }

  bool hasSubmittedFeedback(int orderId) {
    if (currentUser == null) {
      return false;
    }
    return feedback.any((entry) => entry.orderId == orderId && entry.userId == currentUser!.id);
  }

  bool canRateOrder(Order order) {
    return order.status == 'Collected';
  }
}
