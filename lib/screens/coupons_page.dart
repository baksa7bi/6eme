import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/coupon.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'app_drawer.dart';
import 'login_page.dart';
import '../providers/navigation_provider.dart';
import 'package:store_app/l10n/app_localizations.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<List<Coupon>> _couponsFuture = Future.value([]);
  Future<List<Map<String, dynamic>>> _requestsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  bool _isUploading = false;

  void _loadCoupons() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      setState(() {
        _couponsFuture = ApiService.getCoupons(int.parse(authProvider.user!.id));
        _requestsFuture = ApiService.getCouponRequests(userId: int.parse(authProvider.user!.id));
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginToAcquire)),
      );
      return;
    }

    if (!authProvider.user!.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vérifier votre adresse e-mail pour accéder à cette fonctionnalité.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      // Load cafes for selection
      List<Map<String, dynamic>> cafes = [];
      try {
        cafes = (await ApiService.getCafes()).map((c) => {'id': int.parse(c.id), 'name': c.name}).toList();
      } catch (_) {}

      // Show dialog to pick cafe and enter amount
      final amountController = TextEditingController();
      int? selectedCafeId;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(l10n.receiptAmount),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedCafeId,
                      hint: const Text('Choisir un café'),
                      items: cafes.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setStateDialog(() => selectedCafeId = val),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.store, color: Colors.orange),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: l10n.enterTotalAmount,
                        suffixText: 'DH',
                        prefixIcon: const Icon(Icons.receipt_long, color: Colors.orange),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedCafeId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez sélectionner un café')),
                        );
                        return;
                      }
                      final val = double.tryParse(amountController.text);
                      if (val != null && val > 0) {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.invalidAmount)),
                        );
                      }
                    },
                    child: Text(l10n.continueText),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true) return;
      final amount = double.tryParse(amountController.text);
      if (amount == null) return;

      setState(() => _isUploading = true);
      
      try {
        final success = await ApiService.requestCoupon(
          int.parse(authProvider.user!.id),
          File(pickedFile.path),
          amount,
          cafeId: selectedCafeId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande envoyée avec succès !')),
          );
          _loadCoupons();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'envoi de la demande.')),
          );
        }
      } catch (e) {
        debugPrint('Error uploading coupon: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'envoi : ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }


  Future<void> _claimDailyCoupon() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    if (!auth.user!.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vérifier votre adresse e-mail pour réclamer ce coupon.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isUploading = true);
    try {
      final result = await ApiService.claimDailyCoupon(auth.user!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Action effectuée'),
            backgroundColor: result['coupon'] != null ? Colors.green : Colors.orange,
          ),
        );
        _loadCoupons();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(l10n.myCoupons, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (!auth.isAuthenticated) {
            return _buildLoginRequiredState();
          }

          return Column(
            children: [
              _buildRequestsSection(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _claimDailyCoupon,
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Réclamer mon coupon journalier (15 DH)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Coupon>>(
                  future: _couponsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }

                    final coupons = snapshot.data ?? [];

                    if (coupons.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = coupons[index];
                        return _buildCouponCard(coupon);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        label: _isUploading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(l10n.acquireCoupon),
        icon: _isUploading ? null : const Icon(Icons.add_a_photo),
        backgroundColor: Colors.deepOrange,
      ),
    
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_num_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noCouponsAvailable,
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.submitFiveTickets,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Connexion requise',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez vous connecter pour voir vos coupons et en acquérir de nouveaux.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<NavigationProvider>(context, listen: false).pushOnCurrentTab(context, const LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final requests = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.inProgressRequests, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    String statusText = l10n.pending;
                    if (req['status'] == 'approved') statusText = l10n.approved;
                    if (req['status'] == 'rejected') statusText = l10n.rejected;
                    
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            req['status'] == 'pending' ? Icons.hourglass_empty : 
                            req['status'] == 'approved' ? Icons.check_circle : Icons.error,
                            color: req['status'] == 'pending' ? Colors.orange : 
                                   req['status'] == 'approved' ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${req['amount']} DH',
                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            DateFormat('dd/MM HH:mm').format(DateTime.parse(req['created_at'])),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final bool isExpired = coupon.expiryDate != null && coupon.expiryDate!.isBefore(DateTime.now());
    final bool isAvailable = !coupon.isUsed && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isAvailable
            ? LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? Colors.orange : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CADEAU 🎁',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${coupon.discountAmount.toStringAsFixed(2)} MAD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Offre sur votre prochain achat',
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            coupon.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(color: Colors.white, thickness: 1),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (coupon.isUsed)
                        _buildStatusBadge('UTILISÉ', Colors.white24)
                      else if (isExpired)
                        _buildStatusBadge('EXPIRÉ', Colors.white24)
                      else
                        _buildStatusBadge('VALIDE', Colors.white),
                      const SizedBox(height: 8),
                      if (coupon.expiryDate != null)
                        Text(
                          'Expire le:\n${DateFormat('dd/MM/yyyy').format(coupon.expiryDate!)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
