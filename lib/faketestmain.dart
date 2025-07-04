import 'package:e_commerce/data/services/cart_repo.dart';
import 'package:e_commerce/data/services/firebase_auth_service.dart';
import 'package:e_commerce/data/services/item_repo.dart';
import 'package:e_commerce/data/services/order_item_repo.dart';
import 'package:e_commerce/data/services/payment_repo.dart';
import 'package:e_commerce/data/services/user_repo.dart';
import 'package:e_commerce/data/usecases/auth/signin.dart';
import 'package:e_commerce/data/usecases/auth/signout.dart';
import 'package:e_commerce/data/usecases/auth/signup.dart';
import 'package:e_commerce/data/usecases/items/add_item_to_cart_usecase.dart';
import 'package:e_commerce/data/usecases/items/get_all_item_usecase.dart';
import 'package:e_commerce/data/usecases/orders/place_order_usecase.dart';
import 'package:e_commerce/presentation/authscreen.dart';
import 'package:e_commerce/presentation/testhome.dart';
import 'package:e_commerce/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as firebase_auth; // Alias for Firebase Auth's User
import 'package:provider/provider.dart'; // For Provider, Consumer, Selector

// Firebase options
import 'firebase_options.dart';

// Models


// Utils
import 'package:e_commerce/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize all your concrete services (Data Layer implementations)
    // These are often instantiated once and provided throughout the app.
    final UserRepo firebaseUserService = UserRepo();
    final ItemRepo firebaseItemService = ItemRepo();
    final CartRepo firebaseCartService = CartRepo();
    final OrderItemRepo firebaseOrderService = OrderItemRepo();
    final PaymentRepo firebasePaymentService =
        PaymentRepo(); // Unused for now, but available

    // Initialize your FirebaseAuthService, injecting its dependencies
    final FirebaseAuthService firebaseAuthService = FirebaseAuthService(
      firebaseUserService,
    );

    // Initialize all Use Cases, injecting their dependencies (repositories/other services)
    final SignUpUseCase signUpUseCase = SignUpUseCase(firebaseAuthService);
    final SignInUseCase signInUseCase = SignInUseCase(firebaseAuthService);
    final SignOutUseCase signOutUseCase = SignOutUseCase(firebaseAuthService);
    final AddItemToCartUseCase addItemToCartUseCase = AddItemToCartUseCase(
      firebaseCartService,
      firebaseItemService,
    );
    final PlaceOrderUseCase placeOrderUseCase = PlaceOrderUseCase(
      firebaseCartService,
      firebaseOrderService,
      firebaseItemService,
      firebaseUserService,
    );
    final GetAllItemsUseCase getAllProductsUseCase = GetAllItemsUseCase(
      firebaseItemService,
    ); // Used by ItemListViewModel

    return MultiProvider(
      providers: [
        // Provide concrete Repository implementations (as their abstract types)
        // This is crucial for dependency injection into ViewModels.
        Provider<UserRepo>(create: (_) => firebaseUserService),
        Provider<ItemRepo>(create: (_) => firebaseItemService),
        Provider<CartRepo>(create: (_) => firebaseCartService),
        Provider<OrderItemRepo>(create: (_) => firebaseOrderService),
        Provider<PaymentRepo>(create: (_) => firebasePaymentService),

        // Provide Services (like FirebaseAuthService)
        Provider<FirebaseAuthService>(create: (_) => firebaseAuthService),

        // Provide Use Cases
        Provider<SignUpUseCase>(create: (_) => signUpUseCase),
        Provider<SignInUseCase>(create: (_) => signInUseCase),
        Provider<SignOutUseCase>(create: (_) => signOutUseCase),
        Provider<AddItemToCartUseCase>(create: (_) => addItemToCartUseCase),
        Provider<PlaceOrderUseCase>(create: (_) => placeOrderUseCase),
        Provider<GetAllItemsUseCase>(create: (_) => getAllProductsUseCase),

        // Add more providers here if you have other global services or view models that aren't tied to a specific route.
        // Page-specific ViewModels will be provided in onGenerateRoute as shown in app_router.dart
      ],
      child: MaterialApp(
        title: 'E-commerce App',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
        ),
        // Use onGenerateRoute for centralized routing
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.authRoute, // Start at the authentication screen
        // Wrap the home property in a builder to access providers from the tree
        builder: (context, child) {
          // Listen to Firebase Auth state changes
          return StreamBuilder<firebase_auth.User?>(
            stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                appLogger.i(
                  'User ${snapshot.data!.email} is signed in. Navigating to home.',
                );
                // User is signed in, navigate to home screen.
                // We use Navigator.pushReplacementNamed to clear the auth screen from stack
                // This will be called once after login.
                // If already on homescreen, it won't re-navigate.
                return const HomeScreen(); // Or Navigator.pushReplacementNamed(context, AppRoutes.homeRoute);
                // but directly setting home is simpler for root navigation
              } else {
                appLogger.i('No user signed in. Navigating to auth screen.');
                // User is signed out, navigate to auth screen.
                return const AuthScreen(); // Or Navigator.pushReplacementNamed(context, AppRoutes.authRoute);
              }
            },
          );
        },
      ),
    );
  }
}
