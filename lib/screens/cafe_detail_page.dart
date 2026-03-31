import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cafe.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'login_page.dart';
import 'reservation_page.dart';
import 'product_detail_page.dart';
import 'package:store_app/l10n/app_localizations.dart';

class CafeDetailPage extends StatefulWidget {
  final Cafe cafe;

  const CafeDetailPage({super.key, required this.cafe});

  @override
  State<CafeDetailPage> createState() => _CafeDetailPageState();
}

class _CafeDetailPageState extends State<CafeDetailPage> {
  String? _selectedCategory;
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    try {
      final items = await ApiService.getMenuItems(cafeId: int.parse(widget.cafe.id));
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> get _categories {
    final l10n = AppLocalizations.of(context)!;
    final cats = _menuItems.map((item) => item.category).toSet().toList();
    return [l10n.all, ...cats];
  }

  List<MenuItem> get _filteredItems {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final category = _selectedCategory ?? l10n.all;
    
    final canSeeUnavailable = auth.user?.isAdmin == true || auth.user?.isContentManager == true || auth.user?.isManager == true;
    var list = _menuItems;
    if (!canSeeUnavailable) {
      list = list.where((item) => item.available).toList();
    }
    
    if (category == l10n.all) return list;
    return list.where((item) => item.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.cafe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              background: widget.cafe.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ApiService.getFullImageUrl(widget.cafe.imageUrl),
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                      },
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/cafe.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).primaryColor,
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 80, color: Colors.white54),
                          ),
                        ),
                      ),
                    )
                  : Image.asset(
                      'assets/images/cafe.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).primaryColor,
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 80, color: Colors.white54),
                        ),
                      ),
                    ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cafe.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  
                  // Reserve button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.cafe.reservationsBlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les réservations sont actuellement suspendues pour cet établissement.'), backgroundColor: Colors.orange));
                          return;
                        }
                        final auth = context.read<AuthProvider>();
                        if (auth.isAuthenticated && auth.user?.role != 'client') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En tant que personnel, vous ne pouvez pas réserver.'), duration: Duration(seconds: 2)));
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationPage(cafe: widget.cafe),
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_seat),
                      label: Text(AppLocalizations.of(context)!.reserveTable),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.user?.isAdmin == true || (auth.user?.isManager == true && auth.user?.cafeId.toString() == widget.cafe.id.toString())) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final newStatus = !widget.cafe.reservationsBlocked;
                                final success = await ApiService.toggleReservationsBlock(widget.cafe.id, newStatus);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Réservations ${newStatus ? "bloquées" : "débloquées"}')));
                                  setState(() {
                                    widget.cafe.reservationsBlocked = newStatus;
                                  });
                                }
                              },
                              icon: Icon(widget.cafe.reservationsBlocked ? Icons.lock_open : Icons.lock),
                              label: Text(widget.cafe.reservationsBlocked ? 'Débloquer les réservations' : 'Bloquer les réservations'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: widget.cafe.reservationsBlocked ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.menu,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Category filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final l10n = AppLocalizations.of(context)!;
                  final currentSelected = _selectedCategory ?? l10n.all;
                  final isSelected = category == currentSelected;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Menu items
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading 
              ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              : _filteredItems.isEmpty
                ? SliverToBoxAdapter(child: Center(child: Text(AppLocalizations.of(context)!.noItemsFound)))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildMenuItem(_filteredItems[index]);
                      },
                      childCount: _filteredItems.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Open the product detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(item: item),
            ),
          );
        },
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ApiService.getFullImageUrl(item.imageUrl),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    httpHeaders: const {
                      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                    },
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
          ),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                '${item.price.toStringAsFixed(0)} DH',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (auth.user?.isAdmin == true || auth.user?.isContentManager == true || (auth.user?.isManager == true && auth.user?.cafeId.toString() == widget.cafe.id.toString()))
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editMenuItem(item),
                ),
              Consumer<FavoriteProvider>(
                builder: (context, favoriteProvider, _) {
                  final isFavorite = favoriteProvider.isFavorite(item.id);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                        onPressed: () {
                          if (!item.available) return;
                          if (!auth.isAuthenticated) {
                            Provider.of<NavigationProvider>(context, listen: false).pushOnCurrentTab(context, const LoginPage());
                            return;
                          }
                          if (auth.user?.role != 'client') {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En tant que personnel, vous ne pouvez pas commander.'), duration: Duration(seconds: 2)));
                             return;
                          }
                          if (auth.user!.role == 'client' && !auth.user!.isEmailVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vérifier votre email'), duration: Duration(seconds: 2)));
                            return;
                          }
                          context.read<CartProvider>().addItem(item);
                          
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          if (auth.isAuthenticated) {
                            favoriteProvider.toggleFavorite(item);
                          } else {
                            auth.setPendingFavorite(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(l10n.login), duration: const Duration(seconds: 2)),
                            );
                            Provider.of<NavigationProvider>(context, listen: false).pushOnCurrentTab(context, const LoginPage());
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  void _editMenuItem(MenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final categoryController = TextEditingController(text: item.category);
    File? pickedImage;
    bool isSaving = false;
    bool isAvailable = item.available;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.modifyProduct),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Prix (DH)'), keyboardType: TextInputType.number),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Catégorie')),
                  SwitchListTile(
                    title: const Text('Disponible (Rupture de stock)'),
                    value: isAvailable,
                    onChanged: (val) => setDialogState(() => isAvailable = val),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() => pickedImage = File(image.path));
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: pickedImage != null 
                        ? Image.file(pickedImage!, fit: BoxFit.cover) 
                        : const Icon(Icons.add_a_photo),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmer la suppression'),
                      content: const Text('Êtes-vous sûr de vouloir supprimer cet article définitevement ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    setDialogState(() => isSaving = true);
                    final auth = context.read<AuthProvider>();
                    final success = await ApiService.deleteMenuItem(int.parse(item.id), int.parse(auth.user!.id), token: auth.token);
                    if (success) {
                      _fetchMenuItems();
                      if (context.mounted) {
                        Navigator.pop(context); // close edit dialog
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Article supprimé avec succès'), backgroundColor: Colors.green));
                      }
                    } else {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression'), backgroundColor: Colors.red));
                      }
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  final success = await ApiService.updateMenuItem(
                    item.id,
                    name: nameController.text,
                    description: descController.text,
                    price: double.tryParse(priceController.text),
                    category: categoryController.text,
                    imageFile: pickedImage,
                    userId: context.read<AuthProvider>().user?.id.toString(),
                    isAvailable: isAvailable,
                  );
                  if (success) {
                    _fetchMenuItems();
                    Navigator.pop(context);
                  } else {
                    setDialogState(() => isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
