import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../models/meal_images.dart';
import '../providers/app_state.dart';
import '../widgets/food_ordering_widgets.dart';
import '../widgets/residence_favourites_slideshow.dart';
import 'auth_screens.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AppState>().currentUser != null) {
        context.read<AppState>().refreshOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isWide = MediaQuery.sizeOf(context).width >= 820;
    final pages = [
      MealCatalogueScreen(isHome: true, onNavigate: _selectTab),
      MealCatalogueScreen(onNavigate: _selectTab),
      const OrdersScreen(),
      CartScreen(onBrowse: () => _selectTab(1)),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: KslColors.background,
      appBar: AppBar(
        toolbarHeight: isWide ? 76 : 66,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: isWide ? 28 : 16,
        title: KslBrand(compact: !isWide),
        actions: [
          if (isWide)
            for (int index = 0; index < _studentTabs.length; index++)
              TextButton(
                onPressed: () => _selectTab(index),
                style: TextButton.styleFrom(
                  foregroundColor: _currentIndex == index
                      ? KslColors.green
                      : KslColors.muted,
                  textStyle: TextStyle(
                    fontWeight: _currentIndex == index
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                child: Text(_studentTabs[index]),
              ),
          const SizedBox(width: 8),
          if (appState.currentUser == null)
            TextButton(
              onPressed: () => _openLogin(context),
              child: const Text('Sign in'),
            )
          else
            IconButton(
              tooltip: 'Profile',
              onPressed: () => _selectTab(4),
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: KslColors.lightGreen,
                child: Text(
                  appState.currentUser!.fullName.isEmpty
                      ? 'S'
                      : appState.currentUser!.fullName
                            .substring(0, 1)
                            .toUpperCase(),
                  style: const TextStyle(
                    color: KslColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE9ECE8)),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Meals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: 'Cart',
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

const _studentTabs = ['Home', 'Meals', 'Orders', 'Cart', 'Profile'];

void _openLogin(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const StudentLoginScreen()));
}

void _openRegistration(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()));
}

class MealCatalogueScreen extends StatefulWidget {
  final bool isHome;
  final ValueChanged<int>? onNavigate;

  const MealCatalogueScreen({super.key, this.isHome = false, this.onNavigate});

  @override
  State<MealCatalogueScreen> createState() => _MealCatalogueScreenState();
}

class _MealCatalogueScreenState extends State<MealCatalogueScreen> {
  final _searchController = TextEditingController();
  String _category = 'Popular';
  static const _categories = [
    'Popular',
    'Breakfast',
    'Lunch',
    'Chicken',
    'Burgers',
    'Snacks',
    'Drinks',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading && appState.meals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = _searchController.text.trim().toLowerCase();
        final availableMeals = appState.meals
            .where((meal) => meal.available)
            .toList();
        final filtered = availableMeals.where((meal) {
          final matchesSearch =
              query.isEmpty ||
              meal.name.toLowerCase().contains(query) ||
              meal.description.toLowerCase().contains(query);
          final matchesCategory =
              _category == 'Popular' || _mealCategoryMatches(meal, _category);
          return matchesSearch && matchesCategory;
        }).toList();
        final shownMeals =
            widget.isHome && query.isEmpty && _category == 'Popular'
            ? filtered.take(4).toList()
            : filtered;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isHome) _buildHero(context),
              _content(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isHome) ...[
                      _sectionHeading(
                        'Explore by category',
                        'A little something for every craving',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.isHome) ...[
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search meals, ingredients...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 9),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final selected = category == _category;
                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _category = category),
                            showCheckmark: false,
                            selectedColor: KslColors.green,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : KslColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? KslColors.green
                                  : const Color(0xFFE6EAE5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionHeading(
                      widget.isHome && _category == 'Popular'
                          ? 'Popular right now'
                          : 'Our menu',
                      query.isEmpty
                          ? 'Made fresh at the residence'
                          : '${filtered.length} meals found',
                      trailing:
                          widget.isHome &&
                              query.isEmpty &&
                              _category == 'Popular'
                          ? TextButton(
                              onPressed: () => widget.onNavigate?.call(1),
                              child: const Text('View full menu'),
                            )
                          : null,
                    ),
                    const SizedBox(height: 17),
                    if (shownMeals.isEmpty)
                      appState.initializationError == null
                          ? const KslEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No meals found',
                              message: 'Try another search or choose a different category.',
                            )
                          : KslEmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'We couldn’t load the menu',
                              message: appState.initializationError!,
                              action: FilledButton(
                                onPressed: appState.initialize,
                                child: const Text('Try again'),
                              ),
                            )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1050
                              ? 4
                              : constraints.maxWidth >= 700
                              ? 3
                              : constraints.maxWidth >= 460
                              ? 2
                              : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: shownMeals.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  mainAxisExtent: columns == 1 ? 340 : 360,
                                ),
                            itemBuilder: (context, index) =>
                                _MealCard(meal: shownMeals[index]),
                          );
                        },
                      ),
                    if (widget.isHome) ...[
                      const SizedBox(height: 42),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: KslColors.green,
                              size: 30,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order ahead, skip the queue',
                                    style: TextStyle(
                                      color: KslColors.darkGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Track your meal from the kitchen to collection.',
                                    style: TextStyle(color: KslColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (MediaQuery.sizeOf(context).width > 580)
                              TextButton(
                                onPressed: () => widget.onNavigate?.call(2),
                                child: const Text('My orders'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onNavigate != null)
                KslStudentFooter(onNavigate: widget.onNavigate!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return Container(
          width: double.infinity,
          color: const Color(0xFFEEF4EA),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 600 ? 22 : 36,
                  vertical: wide ? 42 : 30,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'YOUR RESIDENCE, YOUR FAVOURITES',
                              style: TextStyle(
                                color: KslColors.green,
                                fontSize: 10,
                                letterSpacing: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'What are you\ncraving today?',
                            style: TextStyle(
                              height: 1.08,
                              fontSize: wide ? 40 : 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              color: KslColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Good food is just a few taps away. Find your next campus favourite.',
                            style: TextStyle(
                              color: KslColors.muted,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Search meals, ingredients...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 20,
                            runSpacing: 8,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 15,
                                        color: KslColors.green,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '  Freshly prepared',
                                      style: TextStyle(
                                        color: KslColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 15,
                                        color: KslColors.green,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '  Made for residence life',
                                      style: TextStyle(
                                        color: KslColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (wide) ...[
                      const SizedBox(width: 36),
                      Expanded(
                        flex: 4,
                        child: const ResidenceFavouritesSlideshow(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _content({required Widget child}) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1200),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: child,
    ),
  ),
);

Widget _sectionHeading(String title, String subtitle, {Widget? trailing}) =>
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: KslColors.darkGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: KslColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );

bool _mealCategoryMatches(Meal meal, String category) {
  final value = '${meal.name} ${meal.description}'.toLowerCase();
  switch (category) {
    case 'Breakfast':
      return value.contains('breakfast') ||
          value.contains('egg') ||
          value.contains('toast');
    case 'Lunch':
      return value.contains('rice') ||
          value.contains('pasta') ||
          value.contains('meal') ||
          value.contains('sandwich');
    case 'Chicken':
      return value.contains('chicken');
    case 'Burgers':
      return value.contains('burger');
    case 'Snacks':
      return value.contains('chip') ||
          value.contains('pizza') ||
          value.contains('sandwich');
    case 'Drinks':
      return value.contains('drink') ||
          value.contains('juice') ||
          value.contains('water');
    default:
      return true;
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MealDetailsScreen(meal: meal)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  KslMealArtwork(image: meal.image, height: 164),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: KslColors.orange,
                          ),
                          SizedBox(width: 3),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KslColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'R ${meal.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: KslColors.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  meal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KslColors.muted,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.restaurant_rounded,
                    size: 15,
                    color: KslColors.green,
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'KSL Cafeteria',
                      style: TextStyle(color: KslColors.muted, fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<AppState>().addToCart(meal, 1);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('${meal.name} added to your cart'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                      },
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: KslColors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealDetailsScreen extends StatefulWidget {
  final Meal meal;

  const MealDetailsScreen({super.key, required this.meal});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    return Scaffold(
      backgroundColor: KslColors.background,
      appBar: AppBar(title: Text(meal.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 580;
                final artwork = KslMealArtwork(
                  image: meal.image,
                  height: wide ? 380 : 260,
                  borderRadius: BorderRadius.circular(24),
                );
                final details = _buildDetails(meal);
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: artwork),
                          const SizedBox(width: 32),
                          Expanded(child: details),
                        ],
                      )
                    : ListView(
                        children: [
                          artwork,
                          const SizedBox(height: 24),
                          details,
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Meal meal) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Row(
        children: [
          Icon(Icons.star_rounded, color: KslColors.orange, size: 20),
          SizedBox(width: 5),
          Text('4.8', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(width: 7),
          Text('Residence favourite', style: TextStyle(color: KslColors.muted)),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        meal.name,
        style: const TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w900,
          color: KslColors.darkGreen,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        meal.description,
        style: const TextStyle(
          color: KslColors.muted,
          height: 1.6,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'R ${meal.price.toStringAsFixed(2)}',
        style: const TextStyle(
          color: KslColors.green,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          IconButton.filledTonal(
            onPressed: () =>
                setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: meal.available
              ? () {
                  context.read<AppState>().addToCart(meal, _quantity);
                  Navigator.pop(context);
                }
              : null,
          child: Text(
            'Add to cart · R ${(meal.price * _quantity).toStringAsFixed(2)}',
          ),
        ),
      ),
    ],
  );
}

class CartScreen extends StatelessWidget {
  final VoidCallback? onBrowse;

  const CartScreen({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.cart.isEmpty) {
          return KslEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Your cart is waiting',
            message: 'Add a residence favourite from the menu and it will show up here.',
            action: onBrowse == null
                ? null
                : FilledButton(
                    onPressed: onBrowse,
                    child: const Text('Explore meals'),
                  ),
          );
        }
        return SingleChildScrollView(
          child: _content(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Your cart',
                  '${appState.cartItemCount} items selected',
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 760;
                    final items = Column(
                      children: [
                        for (final item in appState.cart)
                          _CartItemCard(item: item, appState: appState),
                      ],
                    );
                    final summary = _CartSummary(appState: appState);
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: items),
                              const SizedBox(width: 24),
                              Expanded(flex: 4, child: summary),
                            ],
                          )
                        : Column(
                            children: [
                              items,
                              const SizedBox(height: 8),
                              summary,
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final AppState appState;

  const _CartItemCard({required this.item, required this.appState});

  @override
  Widget build(BuildContext context) {
    final meal = appState.meals
        .where((entry) => entry.id == item.mealId)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final artwork = SizedBox(
          width: 82,
          height: 82,
          child: KslMealArtwork(
            image: meal?.image ?? MealImages.fallback,
            height: 82,
            borderRadius: BorderRadius.circular(14),
          ),
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.mealName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'R ${item.unitPrice.toStringAsFixed(2)} each',
              style: const TextStyle(color: KslColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 7),
            Text(
              'R ${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: KslColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Decrease quantity',
              visualDensity: VisualDensity.compact,
              onPressed: () => appState.updateCartItemQuantity(item.mealId, -1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            IconButton(
              tooltip: 'Increase quantity',
              visualDensity: VisualDensity.compact,
              onPressed: () => appState.updateCartItemQuantity(item.mealId, 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Remove item',
              onPressed: () => appState.removeFromCart(item.mealId),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFB23B3B),
              ),
            ),
          ],
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 13),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
          ),
          child: compact
              ? Column(
                  children: [
                    Row(
                      children: [
                        artwork,
                        const SizedBox(width: 14),
                        Expanded(child: details),
                      ],
                    ),
                    Align(alignment: Alignment.centerRight, child: controls),
                  ],
                )
              : Row(
                  children: [
                    artwork,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                    controls,
                  ],
                ),
        );
      },
    );
  }
}

class _CartSummary extends StatelessWidget {
  final AppState appState;

  const _CartSummary({required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: KslColors.darkGreen,
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subtotal',
                  style: TextStyle(color: KslColors.muted),
                ),
              ),
              Expanded(
                child: Text(
                  'R ${appState.cartTotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: Text(
                  'R ${appState.cartTotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: KslColors.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (appState.currentUser == null) {
                  _openLogin(context);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConfirmOrderScreen()),
                );
              },
              child: const Text('Confirm order'),
            ),
          ),
          const SizedBox(height: 11),
          const Center(
            child: Text(
              'Payment is handled at collection.',
              style: TextStyle(color: KslColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmOrderScreen extends StatelessWidget {
  const ConfirmOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: KslColors.background,
          appBar: AppBar(title: const Text('Review your order')),
          body: _content(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading('Almost there', 'Review your meal selection'),
                const SizedBox(height: 18),
                for (final item in appState.cart)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    title: Text('${item.quantity} × ${item.mealName}'),
                    trailing: Text('R ${item.subtotal.toStringAsFixed(2)}'),
                  ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'R ${appState.cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 21,
                        color: KslColors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        appState.cart.isEmpty || appState.currentUser == null
                        ? null
                        : () async {
                            try {
                              final order = await appState.placeOrder();
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderConfirmationScreen(order: order),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
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
                          },
                    child: const Text('Confirm order'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final Order? order;

  const OrderConfirmationScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final confirmedOrder =
        order ?? context.watch<AppState>().myOrders.firstOrNull;
    return Scaffold(
      backgroundColor: KslColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: KslColors.lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 48,
                      color: KslColors.green,
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Text(
                    'Order confirmed!',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      color: KslColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The kitchen has your order. We’ll keep you updated as it’s prepared.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KslColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  if (confirmedOrder != null)
                    Text(
                      confirmedOrder.orderNumber,
                      style: const TextStyle(
                        color: KslColors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const StudentHomeScreen(),
                        ),
                        (route) => false,
                      ),
                      child: const Text('Back to menu'),
                    ),
                  ),
                  if (confirmedOrder != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderTrackingScreen(order: confirmedOrder),
                        ),
                      ),
                      child: const Text('Track this order'),
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

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.myOrders;
    if (appState.currentUser == null) {
      return KslEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Your orders live here',
        message: 'Sign in to see order updates and track your meals.',
        action: FilledButton(
          onPressed: () => _openLogin(context),
          child: const Text('Student sign in'),
        ),
      );
    }
    if (orders.isEmpty) {
      return KslEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Once you place an order, you can follow its progress here.',
      );
    }
    return _content(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Your orders',
            'Follow every order from kitchen to collection',
          ),
          const SizedBox(height: 20),
          for (final order in orders)
            _OrderCard(
              order: order,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(order: order),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentIndex = OrderStatusHelper.indexOf(order.status)
        .clamp(0, 3)
        .toInt();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(19),
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
                  _StatusPill(status: order.status),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                '${DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt)}  ·  R ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(color: KslColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 15),
              _OrderProgress(currentIndex: currentIndex),
              const SizedBox(height: 12),
              Text(
                order.items
                    .map((item) => '${item.quantity}× ${item.mealName}')
                    .join('  ·  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: KslColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'Collected';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? KslColors.lightGreen : const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isDone ? KslColors.green : const Color(0xFF98610D),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  final int currentIndex;

  const _OrderProgress({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final labels = ['Order Placed', 'Preparing', 'Ready', 'Collected'];
    return Row(
      children: [
        for (int index = 0; index < labels.length; index++) ...[
          Column(
            children: [
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: index <= currentIndex
                      ? KslColors.green
                      : const Color(0xFFE6EAE5),
                  shape: BoxShape.circle,
                ),
                child: index <= currentIndex
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                labels[index],
                style: TextStyle(
                  color: index <= currentIndex
                      ? KslColors.darkGreen
                      : KslColors.muted,
                  fontSize: 9,
                  fontWeight: index == currentIndex
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
          if (index < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 17, left: 4, right: 4),
                color: index < currentIndex
                    ? KslColors.green
                    : const Color(0xFFE6EAE5),
              ),
            ),
        ],
      ],
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currentIndex = OrderStatusHelper.indexOf(order.status)
        .clamp(0, 3)
        .toInt();
    return Scaffold(
      backgroundColor: KslColors.background,
      appBar: AppBar(title: const Text('Order tracking')),
      body: _content(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(
                color: KslColors.darkGreen,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Placed ${DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt)}',
              style: const TextStyle(color: KslColors.muted),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your order progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _OrderProgress(currentIndex: currentIndex),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _sectionHeading(
              'Order details',
              '${order.items.length} meal types',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity} × ${item.mealName}',
                              ),
                            ),
                            Text(
                              'R ${(item.quantity * item.price).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'R ${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: KslColors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (order.status == 'Collected') ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RatingScreen(order: order)),
                ),
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('Rate this order'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RatingScreen extends StatefulWidget {
  final Order order;

  const RatingScreen({super.key, required this.order});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order.status != 'Collected') {
      return Scaffold(
        appBar: AppBar(title: const Text('Rating unavailable')),
        body: const KslEmptyState(
          icon: Icons.star_outline_rounded,
          title: 'Not collected yet',
          message: 'You can leave feedback after collecting your order.',
        ),
      );
    }
    return Scaffold(
      backgroundColor: KslColors.background,
      appBar: AppBar(title: const Text('Rate your meal')),
      body: _content(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your meal?',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: KslColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your feedback helps the residence kitchen.',
              style: TextStyle(color: KslColors.muted),
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 35,
                    color: KslColors.orange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Optional feedback',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      try {
                        await context.read<AppState>().submitFeedback(
                          orderId: widget.order.id!,
                          rating: _rating,
                          comment: _commentController.text,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your feedback.'),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              child: Text(_submitting ? 'Submitting…' : 'Submit feedback'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      return KslEmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Your profile',
        message: 'Sign in to access your student profile and order history.',
        action: Wrap(
          spacing: 10,
          children: [
            FilledButton(
              onPressed: () => _openLogin(context),
              child: const Text('Sign in'),
            ),
            OutlinedButton(
              onPressed: () => _openRegistration(context),
              child: const Text('Create account'),
            ),
          ],
        ),
      );
    }
    return _content(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: KslColors.lightGreen,
                    child: Text(
                      user.fullName.isEmpty
                          ? 'S'
                          : user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w800,
                        color: KslColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'KSL Residence student',
                    style: TextStyle(color: KslColors.muted),
                  ),
                  const Divider(height: 32),
                  _profileRow(
                    Icons.badge_outlined,
                    'Student number',
                    user.studentNumber,
                  ),
                  _profileRow(Icons.email_outlined, 'Email', user.email),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await appState.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const StudentHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: KslColors.green),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: KslColors.muted)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
