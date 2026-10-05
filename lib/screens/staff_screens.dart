import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import 'auth_screens.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int currentIndex = 0;

  final List<Widget> _pages = const [
    IncomingOrdersScreen(),
    FeedbackScreen(),
    StaffProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback_outlined), label: 'Feedback'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class IncomingOrdersScreen extends StatelessWidget {
  const IncomingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().allOrders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming orders'),
        automaticallyImplyLeading: false,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No incoming orders yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(order.orderNumber),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${order.studentName} • ${order.studentNumber}'),
                        const SizedBox(height: 4),
                        Text(
                          order.items.map((item) => '${item.quantity}x ${item.mealName}').join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: R ${order.total.toStringAsFixed(2)} • ${DateFormat('dd MMM HH:mm').format(order.createdAt)}',
                        ),
                      ],
                    ),
                    trailing: Text(order.status),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => StaffOrderDetailsScreen(order: order)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class StaffOrderDetailsScreen extends StatelessWidget {
  final Order order;

  const StaffOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.studentName} (${order.studentNumber})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Status: ${order.status}'),
            const SizedBox(height: 8),
            Text('Placed: ${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt)}'),
            const SizedBox(height: 18),
            const Text('Meals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...order.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item.quantity}x ${item.mealName}'),
                trailing: Text('R ${(item.quantity * item.price).toStringAsFixed(2)}'),
              ),
            ),
            const Divider(),
            Text(
              'Total: R ${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            const Text('Update status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: order.status,
              items: OrderStatusHelper.steps
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                await context.read<AppState>().updateOrderStatus(
                  order.id!,
                  order.status,
                  value,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order status updated to $value')),
                  );
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedback = context.watch<AppState>().feedback;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        automaticallyImplyLeading: false,
      ),
      body: feedback.isEmpty
          ? const Center(child: Text('No feedback submitted yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedback.length,
              itemBuilder: (context, index) {
                final item = feedback[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(item.studentName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ${item.orderNumber}'),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(
                            5,
                            (position) => Icon(
                              position < item.rating ? Icons.star : Icons.star_border,
                              size: 18,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(item.comment.isNotEmpty ? item.comment : 'No comment provided.'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: user == null
          ? const Center(child: Text('No user logged in.'))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.person, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(user.email),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppState>().logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
