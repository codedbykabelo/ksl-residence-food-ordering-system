import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/food_ordering_widgets.dart';
import 'student_screens.dart';

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
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final content = IndexedStack(index: currentIndex, children: _pages);
    return Scaffold(
      backgroundColor: KslColors.background,
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  extended: MediaQuery.sizeOf(context).width >= 1100,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => currentIndex = index),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22, horizontal: 10),
                    child: KslBrand(compact: true),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: Text('Orders'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.forum_outlined),
                      selectedIcon: Icon(Icons.forum_rounded),
                      label: Text('Feedback'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => currentIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  label: 'Feedback',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.allOrders;
    final statuses = const ['Pending', 'Preparing', 'Ready', 'Collected'];
    final visibleOrders = _filter == 'All'
        ? orders
        : orders.where((order) => order.status == _filter).toList();

    return Scaffold(
      backgroundColor: KslColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const KslBrand(compact: true),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: appState.refreshAllOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appState.refreshAllOrders,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 900 ? 34.0 : 18.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                22,
                horizontalPadding,
                32,
              ),
              children: [
                const Text(
                  'Kitchen dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: KslColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'A live view of today’s residence orders.',
                  style: TextStyle(color: KslColors.muted),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 13,
                  runSpacing: 13,
                  children: [
                    for (final status in statuses)
                      _DashboardSummaryCard(
                        label: status == 'Collected' ? 'Completed' : status,
                        count: orders
                            .where((order) => order.status == status)
                            .length,
                        icon: _statusIcon(status),
                        highlighted: _filter == status,
                        onTap: () => setState(
                          () => _filter = _filter == status ? 'All' : status,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _filter,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...statuses]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _filter = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visibleOrders.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: KslEmptyState(
                        icon: Icons.room_service_outlined,
                        title: 'No orders to show',
                        message: 'New student orders will appear here.',
                      ),
                    ),
                  )
                else
                  ...visibleOrders.map(
                    (order) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StaffOrderDetailsScreen(order: order),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.orderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(status: order.status),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${order.studentName}  ·  ${order.studentNumber}',
                                style: const TextStyle(
                                  color: KslColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                order.items
                                    .map(
                                      (item) =>
                                          '${item.quantity}× ${item.mealName}',
                                    )
                                    .join('  ·  '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 11),
                              Row(
                                children: [
                                  Text(
                                    'R ${order.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: KslColors.green,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd MMM · HH:mm')
                                        .format(order.createdAt),
                                    style: const TextStyle(
                                      color: KslColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _statusIcon(String status) => switch (status) {
    'Pending' => Icons.notifications_active_outlined,
    'Preparing' => Icons.soup_kitchen_outlined,
    'Ready' => Icons.room_service_outlined,
    _ => Icons.task_alt_rounded,
  };
}

class _DashboardSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const _DashboardSummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Material(
        color: highlighted ? KslColors.lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: highlighted
                      ? Colors.white
                      : KslColors.lightGreen,
                  child: Icon(icon, color: KslColors.green, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          color: KslColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status == 'Collected'
            ? KslColors.lightGreen
            : const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: KslColors.darkGreen,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class StaffOrderDetailsScreen extends StatelessWidget {
  final Order order;

  const StaffOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final statusOptions = <String>[
      order.status,
      if (OrderStatusHelper.nextStatus(order.status) != order.status)
        OrderStatusHelper.nextStatus(order.status),
    ];
    return Scaffold(
      backgroundColor: KslColors.background,
      appBar: AppBar(title: Text(order.orderNumber)),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.studentName} (${order.studentNumber})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${order.status}'),
                  const SizedBox(height: 8),
                  Text(
                    'Placed: ${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt)}',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Meals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item.quantity}x ${item.mealName}'),
                      trailing: Text(
                        'R ${(item.quantity * item.price).toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Total: R ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Update status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: order.status,
                    items: statusOptions
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      try {
                        await context.read<AppState>().updateOrderStatus(
                          order.id!,
                          order.status,
                          value,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order status updated to $value'),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Order status',
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      backgroundColor: KslColors.background,
      appBar: AppBar(
        title: const Text('Feedback'),
        automaticallyImplyLeading: false,
      ),
      body: feedback.isEmpty
          ? const KslEmptyState(
              icon: Icons.forum_outlined,
              title: 'No feedback yet',
              message: 'Student ratings and comments will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: feedback.length,
              itemBuilder: (context, index) {
                final item = feedback[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'Order ${item.orderNumber}',
                              style: const TextStyle(
                                color: KslColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: List.generate(
                            5,
                            (position) => Icon(
                              position < item.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 18,
                              color: KslColors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.comment.isNotEmpty
                              ? item.comment
                              : 'No comment provided.',
                          style: const TextStyle(
                            color: KslColors.muted,
                            height: 1.45,
                          ),
                        ),
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
      backgroundColor: KslColors.background,
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
                    child: const Icon(
                      Icons.person,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                          MaterialPageRoute(
                            builder: (_) => const StudentHomeScreen(),
                          ),
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
