import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class ProductDetailPage extends StatefulWidget {
  final MenuItem item;

  const ProductDetailPage({super.key, required this.item});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final favProvider = context.watch<FavoriteProvider>();
    final isFav = favProvider.isFavorite(widget.item.id);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with hero image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: theme.primaryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.white,
                  ),
                ),
                onPressed: () async {
                  if (!auth.isAuthenticated) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginPage()));
                    return;
                  }
                  await favProvider.toggleFavorite(widget.item);
                  if (mounted) {
                 
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${widget.item.id}',
                child: widget.item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl:
                            ApiService.getFullImageUrl(widget.item.imageUrl),
                        fit: BoxFit.cover,
                        httpHeaders: const {
                          'User-Agent':
                              'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                        },
                        placeholder: (_, __) => Container(
                          color: theme.primaryColor.withOpacity(0.1),
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: theme.primaryColor.withOpacity(0.2),
                          child: Icon(Icons.coffee,
                              size: 80,
                              color: theme.primaryColor.withOpacity(0.5)),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child:
                              Icon(Icons.coffee, size: 100, color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name & Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '${widget.item.price.toStringAsFixed(2)} DH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Availability badge
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.item.available
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.item.available
                                ? 'Disponible'
                                : 'Non disponible',
                            style: TextStyle(
                              color: widget.item.available
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Container(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),

                      // Description header
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.item.description.isNotEmpty
                            ? widget.item.description
                            : 'Aucune description disponible pour ce produit.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Favorite button
              GestureDetector(
                onTap: () async {
                  if (!auth.isAuthenticated) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginPage()));
                    return;
                  }
                  await favProvider.toggleFavorite(widget.item);
                  if (mounted) {
                  
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.primaryColor.withOpacity(0.4), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : theme.primaryColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Add to cart button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.item.available
                      ? () {
                          cart.addItem(widget.item);
                        
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text(
                    'Commander',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
