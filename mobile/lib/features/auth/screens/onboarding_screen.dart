import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.local_shipping,
      title: 'Free Truck Navigation',
      subtitle: 'Professional routing for trucks.\nNo ads. No subscription. Forever free.',
    ),
    OnboardingPage(
      icon: Icons.people,
      title: 'Built by Drivers, for Drivers',
      subtitle: 'Report hazards, review warehouses,\nhelp fellow drivers across Europe.',
    ),
    OnboardingPage(
      icon: Icons.timer,
      title: 'Driving Time Compliance',
      subtitle: 'Track EC 561/2006 automatically.\nNever miss a required break.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Language selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showLanguageSelector(context);
                    },
                    icon: const Icon(Icons.language),
                    label: const Text('English'),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _LanguageTile(flag: '🇬🇧', name: 'English', code: 'en', selected: true),
          _LanguageTile(flag: '🇵🇱', name: 'Polski', code: 'pl'),
          _LanguageTile(flag: '🇷🇴', name: 'Română', code: 'ro'),
          _LanguageTile(flag: '🇩🇪', name: 'Deutsch', code: 'de'),
          _LanguageTile(flag: '🇪🇸', name: 'Español', code: 'es'),
          _LanguageTile(flag: '🇧🇬', name: 'Български', code: 'bg'),
          _LanguageTile(flag: '🇱🇹', name: 'Lietuvių', code: 'lt'),
          _LanguageTile(flag: '🇹🇷', name: 'Türkçe', code: 'tr'),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String name;
  final String code;
  final bool selected;

  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.code,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () => Navigator.pop(context),
    );
  }
}
