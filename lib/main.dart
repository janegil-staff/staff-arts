// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/artwork_provider.dart';
import 'providers/tab_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/upload/upload_screen.dart';
import 'screens/shows/shows_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/messages/conversations_screen.dart';
import 'screens/messages/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
  ));
  runApp(const StaffArtApp());
}

class StaffArtApp extends StatelessWidget {
  const StaffArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => ArtworkProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
      ],
      child: MaterialApp(
        title: 'Staff Art',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.state == AuthState.initial) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
              );
            }
            return const MainShell();
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int? _pendingAuthTab;

  /// Public method so child screens (e.g. UploadScreen) can switch tabs
  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  final _labels = const ['Home', 'Explore', '', 'Shows', 'Profile'];
  final _icons = const ['\u{1F3E0}', '\u{1F50D}', '+', '\u{1F3AD}', '\u{1F464}'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final tabProvider = context.watch<TabProvider>();

    // If user just authenticated and we had a pending tab, navigate there
    if (auth.isAuthenticated && _pendingAuthTab != null) {
      final tab = _pendingAuthTab!;
      _pendingAuthTab = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = tab);
      });
    }

    // If another screen requested a tab switch (e.g. upload -> home)
    if (tabProvider.currentIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = tabProvider.currentIndex);
      });
    }

    // If artworks need refreshing (e.g. after upload)
    if (tabProvider.shouldRefreshArtworks) {
      tabProvider.clearRefreshFlag();
      final artworkProvider = context.read<ArtworkProvider>();
      artworkProvider.fetchArtworks(refresh: true);
      artworkProvider.fetchFeatured();
    }
  }

  void _onTabTapped(int index) {
    final auth = context.read<AuthProvider>();

    if (index == 2) {
      if (!auth.isAuthenticated) {
        _pendingAuthTab = index;
        _pushAuthScreen();
        return;
      }
    }

    if (index == 4 && !auth.isAuthenticated) {
      _pendingAuthTab = index;
      _pushAuthScreen();
      return;
    }

    setState(() => _currentIndex = index);
    // Keep TabProvider in sync so other screens know the current tab
    context.read<TabProvider>().switchToTab(index);
  }

  void _pushAuthScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ExploreScreen();
      case 2:
        return const UploadScreen();
      case 3:
        return const ShowsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated && (_currentIndex == 2 || _currentIndex == 4)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }

    return Scaffold(
      appBar: _buildAppBar(auth),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _buildScreen),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget? _buildAppBar(AuthProvider auth) {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          title: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'STAFF ',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w300,
                    color: AppColors.text,
                    letterSpacing: 1,
                  ),
                ),
                TextSpan(
                  text: 'Arts',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w300,
                    color: AppColors.teal,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Text('\u{1F4AC}', style: TextStyle(fontSize: 22)),
              onPressed: () {
                if (!auth.isAuthenticated) {
                  _pushAuthScreen();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConversationsScreen()),
                );
              },
            ),
          ],
        );
      case 1:
        return AppBar(title: const Text('Explore'));
      case 3:
        return AppBar(title: const Text('Shows'));
      case 4:
        return AppBar(title: const Text('Profile'));
      default:
        return null;
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              if (index == 2) return _buildUploadButton();
              return _buildTabItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final focused = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _icons[index],
              style: TextStyle(
                fontSize: 22,
                color: focused ? AppColors.teal : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[index],
              style: TextStyle(
                fontSize: 11,
                color: focused ? AppColors.teal : AppColors.textMuted,
                fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            if (focused) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.teal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 28,
              color: AppColors.textInverse,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}