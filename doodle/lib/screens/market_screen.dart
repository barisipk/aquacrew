import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_item.dart';
import '../services/game_state.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final GameState _gameState = GameState();

  @override
  void initState() {
    super.initState();
    _gameState.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _gameState.t('market_title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: _buildItemGrid(ItemType.character),
      ),
    );
  }

  Widget _buildItemGrid(ItemType type) {
    // Sadece 'karakterler/' klasöründeki karakterleri filtrele
    final items = _gameState.getItemsByType(type).where((item) {
      return (item.assetPath.contains('karakterler/') ||
              item.id == 'bundle_all_characters') &&
          item.id != 'char_octopus';
    }).toList();

    if (items.isEmpty) {
      return Center(
        child: Text(
          _gameState.t('no_items'),
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: item.isPurchased ? Colors.green : Colors.grey.shade300,
              width: item.isPurchased ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Görsel veya İkon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white, // Arka plan beyaz
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child:
                      item.assetPath.contains('/') ||
                          item.assetPath.endsWith('.png')
                      ? Image.asset(
                          'assets/images/${item.assetPath}',
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            if (item.id == 'bundle_all_characters') {
                              return Icon(
                                Icons.inventory_2,
                                size: 70,
                                color: Colors.purple.shade300,
                              );
                            }
                            return Icon(
                              _getItemIcon(type),
                              size: 70,
                              color: Colors.grey.shade400, // İkon rengi gri
                            );
                          },
                        )
                      : Icon(
                          _getItemIcon(type),
                          size: 70,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // İsim
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _gameState.t(item.name),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Açıklama
              if (item.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _gameState.t(item.description!),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 8),

              // Satın Alma Butonu
              if (item.isPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _gameState.t('owned'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _purchaseItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        item.displayPrice ??
                            '${item.price.toStringAsFixed(2)} ${_gameState.languageNotifier.value == 'tr' ? '₺' : '\$'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _purchaseItem(GameItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _gameState.t('buy_confirm_title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${_gameState.t(item.name)} ${_gameState.t('buy_confirm_content')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_gameState.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
            ),
            child: Text(
              _gameState.t('buy'),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _gameState.buyProduct(item.id);
    }
  }

  IconData _getItemIcon(ItemType type) {
    switch (type) {
      case ItemType.background:
        return Icons.wallpaper;
      case ItemType.character:
        return Icons.pets;
      case ItemType.obstacle:
        return Icons.dangerous;
      case ItemType.platform:
        return Icons.view_column;
    }
  }
}
