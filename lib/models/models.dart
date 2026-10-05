class AppUser {
  final int? id;
  final String studentNumber;
  final String fullName;
  final String email;
  final String passwordHash;
  final String role;

  const AppUser({
    this.id,
    required this.studentNumber,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentNumber': studentNumber,
      'fullName': fullName,
      'email': email,
      'password': passwordHash,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      studentNumber: map['studentNumber'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['password'] ?? '',
      role: map['role'] ?? 'student',
    );
  }
}

class Meal {
  final int? id;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String image;

  const Meal({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'available': available ? 1 : 0,
      'image': image,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    final dynamic availableValue = map['available'];
    bool isAvailable;

    if (availableValue is bool) {
      isAvailable = availableValue;
    } else if (availableValue is int) {
      isAvailable = availableValue == 1;
    } else if (availableValue is String) {
      isAvailable = availableValue.toLowerCase() == 'true';
    } else {
      isAvailable = false;
    }

    return Meal(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      available: isAvailable,
      image: map['image'] ?? '🍽️',
    );
  }
}

class CartItem {
  final int mealId;
  final String mealName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.mealId,
    required this.mealName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;
}

class OrderItem {
  final int? id;
  final int mealId;
  final String mealName;
  final int quantity;
  final double price;

  const OrderItem({
    this.id,
    required this.mealId,
    required this.mealName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealId': mealId,
      'mealName': mealName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      mealId: map['mealId'] as int? ?? 0,
      mealName: map['mealName'] ?? '',
      quantity: map['quantity'] as int? ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Order {
  final int? id;
  final String orderNumber;
  final int userId;
  final double total;
  final String status;
  final DateTime createdAt;
  final String studentName;
  final String studentNumber;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.orderNumber,
    required this.userId,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.studentName,
    required this.studentNumber,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'studentName': studentName,
      'studentNumber': studentNumber,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? items}) {
    return Order(
      id: map['id'] as int?,
      orderNumber: map['orderNumber'] ?? '',
      userId: map['userId'] as int? ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      studentName: map['studentName'] ?? map['fullName'] ?? '',
      studentNumber: map['studentNumber'] ?? '',
      items: items ?? const [],
    );
  }
}

class Feedback {
  final int? id;
  final int orderId;
  final int userId;
  final int rating;
  final String comment;
  final String orderNumber;
  final String studentName;
  final DateTime createdAt;

  const Feedback({
    this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.orderNumber,
    required this.studentName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'orderNumber': orderNumber,
      'studentName': studentName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Feedback.fromMap(Map<String, dynamic> map) {
    return Feedback(
      id: map['id'] as int?,
      orderId: map['orderId'] as int? ?? 0,
      userId: map['userId'] as int? ?? 0,
      rating: map['rating'] as int? ?? 0,
      comment: map['comment'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      studentName: map['studentName'] ?? map['fullName'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class OrderStatusHelper {
  static const List<String> steps = ['Pending', 'Preparing', 'Ready', 'Collected'];

  static int indexOf(String status) {
    final normalized = status.trim();
    return steps.indexOf(normalized);
  }

  static bool canAdvance(String current, String next) {
    final currentIndex = indexOf(current);
    final nextIndex = indexOf(next);
    if (currentIndex == -1 || nextIndex == -1) {
      return false;
    }
    return nextIndex == currentIndex + 1;
  }

  static String nextStatus(String current) {
    final index = indexOf(current);
    if (index >= 0 && index < steps.length - 1) {
      return steps[index + 1];
    }
    return current;
  }

  static String formatStatus(String status) {
    return status.isEmpty ? 'Pending' : status;
  }
}
