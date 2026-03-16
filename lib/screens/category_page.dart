import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryPage extends StatelessWidget {
  final String categoryTitle;

  const CategoryPage({super.key, required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle.replaceAll('\n', ' ')),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: ApiService.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final List<MenuItem> allItems = snapshot.data ?? [];
          final normalizedTitle = categoryTitle.replaceAll('\n', ' ').toUpperCase();
          
          final filteredItems = allItems.where((item) {
            final categoryMatch = item.category.toUpperCase().contains(normalizedTitle) ||
                                  normalizedTitle.contains(item.category.toUpperCase());
            final nameMatch = item.name.toUpperCase().contains(normalizedTitle);
            return categoryMatch || nameMatch;
          }).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text('Aucun article trouvé dans cette catégorie.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildProductCard(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, MenuItem item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: ApiService.getFullImageUrl(item.imageUrl), 
                  fit: BoxFit.cover, 
                  httpHeaders: const {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                  },
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (_,__,___) => const Icon(Icons.fastfood, size: 50, color: Colors.grey)
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.description, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text('${item.price.toStringAsFixed(0)} DH', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                    onPressed: () {
                      context.read<CartProvider>().addItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajouté au panier'), duration: Duration(milliseconds: 500)),
                      );
                    },
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
