import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const String _kUsers = 'ksl_users';
  static const String _kMeals = 'ksl_meals';
  static const String _kOrders = 'ksl_orders';
  static const String _kFeedback = 'ksl_feedback';
  static const String _kCurrentUserId = 'ksl_current_user_id';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList(_kMeals) == null || prefs.getStringList(_kMeals)!.isEmpty) {
      final meals = _defaultMeals();
      await _writeMeals(meals);
    }

    if (prefs.getStringList(_kUsers) == null || prefs.getStringList(_kUsers)!.isEmpty) {
      final staff = AppUser(
        studentNumber: '',
        fullName: 'Residence Manager',
        email: 'staff@kslresidence.co.za',
        passwordHash: hashPassword('KSLstaff@2025'),
        role: 'staff',
      );
      await prefs.setStringList(_kUsers, [jsonEncode(staff.toMap())]);
    }
  }

  Future<List<AppUser>> _readUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_kUsers) ?? const <String>[];

    return items
        .map((item) => AppUser.fromMap(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList();
  }

  Future<void> _writeUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kUsers,
      users.map((user) => jsonEncode(user.toMap())).toList(),
    );
  }

  Future<List<Meal>> _readMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_kMeals) ?? const <String>[];

    return items
        .map((item) => Meal.fromMap(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList();
  }

  Future<void> _writeMeals(List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kMeals,
      meals.map((meal) => jsonEncode(meal.toMap())).toList(),
    );
  }

  Future<List<Order>> _readOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_kOrders) ?? const <String>[];

    return items
        .map((item) => Order.fromMap(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList();
  }

  Future<void> _writeOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kOrders,
      orders.map((order) => jsonEncode(order.toMap())).toList(),
    );
  }

  Future<List<Feedback>> _readFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_kFeedback) ?? const <String>[];

    return items
        .map((item) => Feedback.fromMap(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList();
  }

  Future<void> _writeFeedback(List<Feedback> feedbacks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kFeedback,
      feedbacks.map((feedback) => jsonEncode(feedback.toMap())).toList(),
    );
  }

  Future<void> persistCurrentUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCurrentUserId, user.id ?? 0);
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_kCurrentUserId);
    if (userId == null || userId == 0) {
      return null;
    }

    final users = await _readUsers();
    for (final user in users) {
      if ((user.id ?? 0) == userId) {
        return user;
      }
    }
    return null;
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUserId);
  }

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }

  Future<AppUser?> getUserById(int id) async {
    final users = await _readUsers();
    for (final user in users) {
      if ((user.id ?? 0) == id) {
        return user;
      }
    }
    return null;
  }

  Future<AppUser?> registerStudent({
    required String studentNumber,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final users = await _readUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedNumber = studentNumber.trim();

    for (final user in users) {
      if (user.email.trim().toLowerCase() == normalizedEmail ||
          user.studentNumber.trim() == normalizedNumber) {
        return null;
      }
    }

    final nextId = (users.map((user) => user.id ?? 0).fold(0, (max, value) => value > max ? value : max)) + 1;
    final user = AppUser(
      id: nextId,
      studentNumber: normalizedNumber,
      fullName: fullName.trim(),
      email: normalizedEmail,
      passwordHash: hashPassword(password),
      role: 'student',
    );

    users.add(user);
    await _writeUsers(users);
    return user;
  }

  Future<AppUser?> loginStudent(String email, String password) async {
    final users = await _readUsers();
    final normalizedEmail = email.trim().toLowerCase();

    for (final user in users) {
      if (user.role == 'student' && user.email.trim().toLowerCase() == normalizedEmail) {
        if (user.passwordHash == hashPassword(password)) {
          return user;
        }
        return null;
      }
    }
    return null;
  }

  Future<AppUser?> loginStaff(String email, String password) async {
    final users = await _readUsers();
    final normalizedEmail = email.trim().toLowerCase();

    for (final user in users) {
      if (user.role == 'staff' && user.email.trim().toLowerCase() == normalizedEmail) {
        if (user.passwordHash == hashPassword(password)) {
          return user;
        }
        return null;
      }
    }
    return null;
  }

  Future<List<Meal>> getMeals() async {
    return _readMeals();
  }

  Future<Order> createOrder({
    required int userId,
    required List<CartItem> items,
  }) async {
    final user = await getUserById(userId);
    if (user == null) {
      throw StateError('User not found.');
    }

    final orders = await _readOrders();
    final orderNumber = await generateOrderNumber();
    final total = items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
    final id = (orders.map((order) => order.id ?? 0).fold(0, (max, value) => value > max ? value : max)) + 1;

    final order = Order(
      id: id,
      orderNumber: orderNumber,
      userId: userId,
      total: total,
      status: 'Pending',
      createdAt: DateTime.now(),
      studentName: user.fullName,
      studentNumber: user.studentNumber,
      items: items
          .map(
            (item) => OrderItem(
              mealId: item.mealId,
              mealName: item.mealName,
              quantity: item.quantity,
              price: item.unitPrice,
            ),
          )
          .toList(),
    );

    orders.insert(0, order);
    await _writeOrders(orders);
    return order;
  }

  Future<List<Order>> getOrdersForUser(int userId) async {
    final orders = await _readOrders();
    final userOrders = orders.where((order) => order.userId == userId).toList();
    userOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userOrders;
  }

  Future<List<Order>> getAllOrders() async {
    final orders = await _readOrders();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final orders = await _readOrders();
    final index = orders.indexWhere((order) => (order.id ?? 0) == orderId);
    if (index == -1) {
      return;
    }

    final updatedOrders = List<Order>.from(orders);
    updatedOrders[index] = Order(
      id: updatedOrders[index].id,
      orderNumber: updatedOrders[index].orderNumber,
      userId: updatedOrders[index].userId,
      total: updatedOrders[index].total,
      status: status,
      createdAt: updatedOrders[index].createdAt,
      studentName: updatedOrders[index].studentName,
      studentNumber: updatedOrders[index].studentNumber,
      items: updatedOrders[index].items,
    );
    await _writeOrders(updatedOrders);
  }

  Future<void> saveFeedback({
    required int orderId,
    required int userId,
    required int rating,
    required String comment,
  }) async {
    final feedbacks = await _readFeedback();
    final exists = feedbacks.any((entry) => entry.orderId == orderId && entry.userId == userId);
    if (exists) {
      throw Exception('Feedback for this order has already been submitted.');
    }

    final order = (await getOrdersForUser(userId)).firstWhere(
      (entry) => (entry.id ?? 0) == orderId,
      orElse: () => throw StateError('Order not found.'),
    );
    final user = await getUserById(userId);

    final newFeedback = Feedback(
      orderId: orderId,
      userId: userId,
      rating: rating,
      comment: comment.trim(),
      orderNumber: order.orderNumber,
      studentName: user?.fullName ?? order.studentName,
      createdAt: DateTime.now(),
    );

    feedbacks.insert(0, newFeedback);
    await _writeFeedback(feedbacks);
  }

  Future<List<Feedback>> getFeedback() async {
    final feedbacks = await _readFeedback();
    feedbacks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return feedbacks;
  }

  Future<String> generateOrderNumber() async {
    final random = math.Random();
    final number = random.nextInt(9000) + 1000;
    return 'KSL-$number';
  }

  List<Meal> _defaultMeals() {
    return [
      Meal(
        name: 'Chicken Burger',
        description: 'Grilled chicken patty with lettuce, tomato and house sauce.',
        price: 52.0,
        available: true,
        image: '🍔',
      ),
      Meal(
        name: 'Chicken and Chips',
        description: 'Golden fries with crispy chicken and a spicy dip.',
        price: 68.0,
        available: true,
        image: '🍟',
      ),
      Meal(
        name: 'Beef Burger',
        description: 'Juicy beef burger with melted cheese and relish.',
        price: 58.0,
        available: true,
        image: '🍔',
      ),
      Meal(
        name: 'Pizza',
        description: 'Classic cheese pizza with tomato and herb seasoning.',
        price: 72.0,
        available: true,
        image: '🍕',
      ),
      Meal(
        name: 'Sandwich',
        description: 'Fresh sandwich with chicken, salad and aioli.',
        price: 45.0,
        available: true,
        image: '🥪',
      ),
      Meal(
        name: 'Pasta',
        description: 'Creamy pasta tossed with herbs and roasted vegetables.',
        price: 64.0,
        available: true,
        image: '🍝',
      ),
      Meal(
        name: 'Rice and Chicken',
        description: 'Comforting rice and chicken with peri-peri seasoning.',
        price: 70.0,
        available: true,
        image: '🍛',
      ),
      Meal(
        name: 'Breakfast Meal',
        description: 'Eggs, toast, grilled tomato and a fruit cup.',
        price: 48.0,
        available: true,
        image: '🍳',
      ),
      Meal(
        name: 'Vegetarian Meal',
        description: 'Savoury vegetarian bowl with beans, rice and greens.',
        price: 56.0,
        available: true,
        image: '🥗',
      ),
    ];
  }
}
