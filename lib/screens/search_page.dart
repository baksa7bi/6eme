import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/cafe.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'cafe_detail_page.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;
  const SearchPage({super.key, this.initialQuery = ''});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  List<MenuItem> _products = [];
  List<Cafe> _locations = [];
  List<Event> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      // Parallel fetch (simple version for now)
      final results = await Future.wait([
        ApiService.getMenuItems(),
        ApiService.getCafes(),
        ApiService.getEvents(),
      ]);

      final allProducts = results[0] as List<MenuItem>;
      final allLocations = results[1] as List<Cafe>;
      final allEvents = results[2] as List<Event>;

      setState(() {
        _products = allProducts.where((p) => 
          p.name.toLowerCase().contains(query.toLowerCase()) || 
          p.description.toLowerCase().contains(query.toLowerCase())
        ).toList();

        _locations = allLocations.where((l) => 
          l.name.toLowerCase().contains(query.toLowerCase()) || 
          l.address.toLowerCase().contains(query.toLowerCase())
        ).toList();

        _events = allEvents.where((e) => 
          e.title.toLowerCase().contains(query.toLowerCase()) || 
          e.description.toLowerCase().contains(query.toLowerCase()) ||
          e.location.toLowerCase().contains(query.toLowerCase())
        ).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: widget.initialQuery.isEmpty,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Produits, lieux, événements...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_products.isEmpty && _locations.isEmpty && _events.isEmpty)
          ? const Center(child: Text('Aucun résultat trouvé.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_products.isNotEmpty) ...[
                  const Text('PRODUITS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  ..._products.map((p) => Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('${p.price} DH'),
                        trailing: IconButton(
                          icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            cart.addItem(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} ajouté au panier'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          // Optional: navigate to product detail
                        },
                      );
                    },
                  )),
                  const SizedBox(height: 20),
                ],
                if (_locations.isNotEmpty) ...[
                  const Text('LIEUX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  ..._locations.map((l) => ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(l.name),
                    subtitle: Text(l.address),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CafeDetailPage(cafe: l)),
                      );
                    },
                  )),
                  const SizedBox(height: 20),
                ],
                if (_events.isNotEmpty) ...[
                  const Text('ÉVÉNEMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  ..._events.map((e) => ListTile(
                    leading: const Icon(Icons.event, color: Colors.blue),
                    title: Text(e.title),
                    subtitle: Text(e.location),
                    onTap: () {
                      // Navigate to events page or scroll to event
                    },
                  )),
                ],
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
