// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ksl_residence_food_ordering_system/models/meal_images.dart';
import 'package:ksl_residence_food_ordering_system/screens/auth_screens.dart';
import 'package:ksl_residence_food_ordering_system/screens/student_screens.dart';
import 'package:ksl_residence_food_ordering_system/models/models.dart';
import 'package:ksl_residence_food_ordering_system/providers/app_state.dart';
import 'package:ksl_residence_food_ordering_system/services/database_service.dart';
import 'package:ksl_residence_food_ordering_system/widgets/food_ordering_widgets.dart';
import 'package:ksl_residence_food_ordering_system/widgets/residence_favourites_slideshow.dart';
import 'package:provider/provider.dart';

void main() {
  test('staff routes are recognized from path and hash fragments', () {
    expect(
      staffRouteFromUri(Uri.parse('http://localhost:19106/#/staff')),
      '/staff',
    );
    expect(
      staffRouteFromUri(Uri.parse('http://localhost:19106/#/staff-login')),
      '/staff-login',
    );
    expect(
      staffRouteFromUri(Uri.parse('http://localhost:19106/staff/')),
      '/staff',
    );
    expect(staffRouteFromUri(Uri.parse('http://localhost:19106/')), isNull);
  });

  test(
    'default meals use local photos and legacy emoji images are migrated',
    () async {
      SharedPreferences.setMockInitialValues({});
      final database = DatabaseService.instance;

      await database.initialize();
      final defaultMeals = await database.getMeals();

      expect(defaultMeals, hasLength(9));
      expect(
        defaultMeals.every((meal) => meal.image.startsWith('assets/images/')),
        isTrue,
      );

      SharedPreferences.setMockInitialValues({
        'ksl_meals': [
          jsonEncode({
            'id': 17,
            'name': 'Chicken Burger',
            'description': 'Existing description',
            'price': 52.0,
            'available': 1,
            'image': '🍔',
          }),
          jsonEncode({
            'id': 18,
            'name': 'Custom Meal',
            'description': 'Custom meal description',
            'price': 46.0,
            'available': 1,
            'image': '🍲',
          }),
        ],
      });

      await database.initialize();
      final migratedMeals = await database.getMeals();

      expect(migratedMeals[0].id, 17);
      expect(migratedMeals[0].description, 'Existing description');
      expect(migratedMeals[0].price, 52.0);
      expect(migratedMeals[0].available, isTrue);
      expect(migratedMeals[0].image, MealImages.byMealName['chicken burger']);
      expect(migratedMeals[1].id, 18);
      expect(migratedMeals[1].image, MealImages.fallback);
    },
  );

  test('requested staff credentials can log in after initialization', () async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();

    await appState.initialize();
    await appState.loginStaff('ksl@gmail.com', '123456');

    expect(appState.currentUser?.email, 'ksl@gmail.com');
    expect(appState.currentUser?.role, 'staff');
    await expectLater(
      appState.loginStaff('ksl@gmail.com', 'wrong'),
      throwsA(isA<Exception>()),
    );
  });

  testWidgets('meal artwork uses a local photo when its image cannot load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 220,
            child: KslMealArtwork(image: 'assets/images/food/missing.webp'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == MealImages.fallback,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'residence favourites slideshow advances, loops, and can be selected',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ResidenceFavouritesSlideshow()),
      );

      expect(
        find.byKey(const ValueKey('assets/images/residence_favourite_1.png')),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.byKey(const ValueKey('assets/images/residence_favourite_2.png')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Show food image 3'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.byKey(const ValueKey('assets/images/residence_favourite_3.png')),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.byKey(const ValueKey('assets/images/residence_favourite_1.png')),
        findsOneWidget,
      );
      expect(find.text('Residence favourites'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('student sign-in and registration remain accessible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('KSL RESIDENCE'), findsOneWidget);
    expect(find.text('FOOD ORDERING'), findsOneWidget);
    expect(find.text('Student sign in'), findsOneWidget);
    expect(find.text('Create student account'), findsOneWidget);
  });

  testWidgets('a student session sees staff login, not the staff dashboard', (
    WidgetTester tester,
  ) async {
    final appState = AppState()
      ..currentUser = const AppUser(
        id: 1,
        studentNumber: 'S123',
        fullName: 'KSL Student',
        email: 'student@example.com',
        passwordHash: '',
        role: 'student',
      );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(home: StaffDashboardRoute()),
      ),
    );

    expect(find.text('Staff Login'), findsOneWidget);
    expect(find.text('Kitchen dashboard'), findsNothing);
  });

  testWidgets('an authenticated staff session can open the staff dashboard', (
    WidgetTester tester,
  ) async {
    final appState = AppState()
      ..currentUser = const AppUser(
        id: 1,
        studentNumber: '',
        fullName: 'Residence Manager',
        email: 'staff@example.com',
        passwordHash: '',
        role: 'staff',
      );
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(home: StaffDashboardRoute()),
      ),
    );

    expect(find.text('Kitchen dashboard'), findsOneWidget);
  });

  testWidgets('student home opens on the food discovery experience', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState()
      ..meals = const [
        Meal(
          id: 1,
          name: 'Chicken Burger',
          description: 'Grilled chicken with lettuce and tomato.',
          price: 52,
          available: true,
          image: 'assets/images/food/chicken-burger.webp',
        ),
      ];
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(home: StudentHomeScreen()),
      ),
    );

    expect(find.text('What are you\ncraving today?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Explore by category'), findsOneWidget);
    expect(find.text('Chicken Burger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student registration retains all required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StudentRegistrationScreen()),
    );

    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Student Number'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
  });

  testWidgets('cart controls fit on a phone-sized viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = AppState()
      ..meals = const [
        Meal(
          id: 1,
          name: 'Chicken Burger',
          description: 'Grilled chicken with lettuce and tomato.',
          price: 52,
          available: true,
          image: 'assets/images/food/chicken-burger.webp',
        ),
      ]
      ..cart = [
        CartItem(
          mealId: 1,
          mealName: 'Chicken Burger',
          unitPrice: 52,
          quantity: 1,
        ),
      ];

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    expect(find.text('Chicken Burger'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
