import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Access to ReservationPage if needed
import '../models/cafe.dart'; // To access cafe data if needed
import 'app_drawer.dart';
import 'cafe_detail_page.dart';
import 'login_page.dart';
import 'search_page.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'dart:async';
import 'notifications_page.dart';
import '../providers/notification_provider.dart';
import 'package:store_app/l10n/app_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentCarouselIndex = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
      context.read<NotificationProvider>().loadNotifications();
    });
    // Refresh notifications every minute
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _claimWelcomeGift() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.login)),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      }

      final result = await ApiService.claimFirstTryCoupon(auth.user!.id.toString(), deviceId);
      
      if (mounted) {
        final hasCoupons = result['coupons'] != null || result['coupon'] != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (hasCoupons ? l10n.congratsGift : l10n.alreadyClaimed)),
            backgroundColor: hasCoupons ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> categories = [
      {'name': l10n.cafes, 'icon': Icons.coffee},
      {'name': l10n.coldDrinks, 'icon': Icons.local_drink},
      {'name': l10n.breakfast, 'icon': Icons.bakery_dining},
      {'name': l10n.iceCream, 'icon': Icons.icecream},
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(135 + MediaQuery.of(context).padding.top),
        child: Container(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    }, 
                  ),
                  // Logo
                  Image.asset(
                    'assets/images/logo.png', 
                    height: 80, // Even bigger as requested
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                  
                  Row(
                    children: [
                      // Combined Notifications & Theme Toggle
                     
                      const SizedBox(width: 4),
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return IconButton(
                            onPressed: () {
                              notifProvider.clearUnread();
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
                            },
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                                if (notifProvider.unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      child: Text(
                                        '${notifProvider.unreadCount}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        onSubmitted: (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SearchPage(initialQuery: value)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel / Banner (moved up for better flow)
            Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                if (homeProvider.isLoadingSliders) {
                  return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                }
                
                final sliders = homeProvider.sliders;
                if (sliders.isEmpty) {
                  if (homeProvider.sliderError != null) {
                    return SizedBox(height: 220, child: Center(child: Text('Erreur: ${homeProvider.sliderError}')));
                  }
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: sliders.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCarouselIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = sliders[index];
                          return Container(
                            width: double.infinity,
                            color: Colors.black,
                            child: Stack(
                              children: [
                                // Background media
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 1.0,
                                    child: item['type'] == 'video'
                                      ? _VideoBackground(url: item['url']!)
                                      : (item['url']!.startsWith('assets/') 
                                          ? Image.asset(item['url']!, fit: BoxFit.cover)
                                          : CachedNetworkImage(
                                              imageUrl: ApiService.getFullImageUrl(item['url']), 
                                              fit: BoxFit.cover,
                                              httpHeaders: const {
                                                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                                              },
                                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                            )), 
                                  ),
                                ),
                                // Text Overlay (Title & Subtitle)
                                if (item['show_text'] == true || item['show_text'] == 1 || item['show_text'] == '1')
                                  Positioned(
                                    bottom: 40,
                                    left: 20,
                                    right: 20,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                                          ),
                                        ),
                                        Text(
                                          item['subtitle'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Edit button for Content Manager
                                Consumer<AuthProvider>(
                                  builder: (context, auth, child) {
                                    if (auth.user?.isContentManager ?? false) {
                                      return Positioned(
                                        top: 10,
                                        right: 10,
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white),
                                          onPressed: () => _editSliderItem(item),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(sliders.length, (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentCarouselIndex == index ? Theme.of(context).primaryColor : Colors.grey[600],
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Welcome Gift Banner
            _buildWelcomeGiftBanner(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(l10n.ourEstablishments, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 120,
              child: Consumer<HomeProvider>(
                builder: (context, homeProvider, child) {
                  if (homeProvider.isLoadingCafes && homeProvider.cafes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final cafes = homeProvider.cafes;
                  if (cafes.isEmpty) {
                    if (homeProvider.cafeError != null) {
                      return Center(child: Text('${l10n.error}: ${homeProvider.cafeError}'));
                    }
                    return Center(child: Text(l10n.noCafesAvailable));
                  }
                  
                  if (cafes.length <= 3) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: cafes.map((cafe) => _buildLocationItem(cafe)).toList(),
                    );
                  }
                  
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cafes.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return _buildLocationItem(cafes[index]);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Lifestyle / Concept Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=1470&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                    opacity: 0.4,
                  ),
                  color: Colors.black,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.experienceTitle,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.experienceSubtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(l10n.ourHistory),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Commitments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.ourCommitments, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCommitmentItem(context, Icons.verified_user_outlined, l10n.quality, l10n.qualitySubtitle),
                  _buildCommitmentItem(context, Icons.access_time, l10n.service, l10n.serviceSubtitle),
                  _buildCommitmentItem(context, Icons.local_cafe_outlined, l10n.freshness, l10n.freshnessSubtitle),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Loyalty / Banner
          

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Widget _buildLocationItem(Cafe cafe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CafeDetailPage(cafe: cafe),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2), // Gold border effect
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: cafe.imageUrl.isNotEmpty 
                  ? CachedNetworkImageProvider(
                      ApiService.getFullImageUrl(cafe.imageUrl),
                      headers: const {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                      },
                    ) 
                  : null,
              child: cafe.imageUrl.isEmpty 
                  ? Icon(Icons.location_on, color: Theme.of(context).primaryColor.withOpacity(0.7))
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(cafe.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _editSliderItem(Map<String, dynamic> item) {
    final titleController = TextEditingController(text: item['title']);
    final subtitleController = TextEditingController(text: item['subtitle']);
    bool showText = item['show_text'] == true || item['show_text'] == 1 || item['show_text'] == '1';
    
    File? pickedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier le slider'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
                  TextField(controller: subtitleController, decoration: const InputDecoration(labelText: 'Sous-titre')),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("Afficher le texte", style: TextStyle(fontSize: 14)),
                    value: showText,
                    onChanged: (val) {
                      setDialogState(() {
                        showText = val ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                      );
                      if (image != null) {
                        setDialogState(() {
                          pickedImage = File(image.path);
                        });
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: pickedImage != null
                          ? Image.file(pickedImage!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate, color: Colors.grey),
                                Text(item['url'] != null && item['url'].toString().isNotEmpty ? "Changer l'image/vidéo" : "Ajouter une image", style: const TextStyle(fontSize: 12, color: Colors.grey))
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  
                  final success = await ApiService.updateSliderItem(
                    item['id'], 
                    titleController.text, 
                    subtitleController.text,
                    imageFile: pickedImage,
                    showText: showText,
                  );
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    context.read<HomeProvider>().loadSliders(); // Reload all sliders to get the new URLs
                  } else {
                    setDialogState(() => isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la modification')));
                    }
                  }
                },
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Enregistrer'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildWelcomeGiftBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.card_giftcard, size: 80, color: Colors.white.withOpacity(0.1)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.welcomeGift,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '15 DH Off on your first order!',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _claimWelcomeGift,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(l10n.claimNow, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoBackground extends StatefulWidget {
  final String url;
  const _VideoBackground({required this.url});

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return VideoPlayer(_controller);
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
