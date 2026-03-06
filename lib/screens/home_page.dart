import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/cart_provider.dart';
import 'reservation_page.dart';  // Access to ReservationPage if needed
import '../models/cafe.dart'; // To access cafe data if needed
import '../providers/theme_provider.dart';
import 'app_drawer.dart';
import 'cafe_detail_page.dart';
import 'register_page.dart';
import 'search_page.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentCarouselIndex = 0;

  List<Map<String, dynamic>> _carouselItems = [];
  bool _isLoadingSliders = true;

  @override
  void initState() {
    super.initState();
    _loadSliders();
  }

  Future<void> _loadSliders() async {
    try {
      final sliders = await ApiService.getSliders();
      if (mounted) {
        setState(() {
          _carouselItems = sliders;
          _isLoadingSliders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSliders = false);
      }
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'BOISSONS\nCHAUDES', 'icon': Icons.coffee},
    {'name': 'BOISSONS\nFRAICHES', 'icon': Icons.local_drink},
    {'name': 'PETIT\nDÉJEUNER', 'icon': Icons.bakery_dining},
    {'name': 'GLACES', 'icon': Icons.icecream},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(142 + MediaQuery.of(context).padding.top),
        child: Container(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 10),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png', 
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  
                  Row(
                    children: [
                      // Theme Toggle
                      IconButton(
                        icon: const Icon(Icons.brightness_6, color: Colors.white),
                        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                      ),
                      const SizedBox(width: 8),
                      // Notifications
                      Stack(
                        children: [
                          const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                          hintText: 'Rechercher un produit...',
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
            if (_isLoadingSliders)
              const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
            else if (_carouselItems.isNotEmpty)
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  children: [
                    PageView.builder(
                    itemCount: _carouselItems.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _carouselItems[index];
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
                                      : Image.network(item['url']!, fit: BoxFit.cover)), 
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
                                      onPressed: () => _editSliderItem(index),
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
                      children: List.generate(_carouselItems.length, (index) => Container(
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
            ),

            // "Marques" style section (using cafe locations)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Nos Établissements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 120,
              child: FutureBuilder<List<Cafe>>(
                future: ApiService.getCafes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cafes = snapshot.data ?? [];
                  if (cafes.isEmpty) {
                    return const Center(child: Text('Aucun café disponible'));
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
                      'L\'EXPÉRIENCE\n6ÈME CAFÉ',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Plus qu\'un simple café, un lieu de rencontre où la passion du goût rencontre l\'art de vivre. Découvrez une sélection exceptionnelle de grains et une ambiance unique.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Notre Histoire'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Commitments Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nos Engagements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCommitmentItem(context, Icons.verified_user_outlined, 'Qualité', 'Grains sélectionnés'),
                  _buildCommitmentItem(context, Icons.access_time, 'Service', 'Rapide & Souriant'),
                  _buildCommitmentItem(context, Icons.local_cafe_outlined, 'Fraîcheur', 'Torréfaction locale'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Loyalty / Banner
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isAuthenticated) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rejoignez le Club',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cumulez des points et profitez d\'offres exclusives.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('S\'inscrire'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

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
              backgroundImage: cafe.imageUrl.isNotEmpty ? NetworkImage(cafe.imageUrl) : null,
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

  void _editSliderItem(int index) {
    // Show dialog to edit slider item
    final item = _carouselItems[index];
    final titleController = TextEditingController(text: item['title']);
    final subtitleController = TextEditingController(text: item['subtitle']);
    
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
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
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
                  );
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    _loadSliders(); // Reload all sliders to get the new URLs
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
