import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_item.dart';
import '../services/game_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GameState _gameState = GameState();
  int _selectedTab = 0;

  final List<String> _tabs = [
    // 'tab_backgrounds',
    'tab_characters',
    // 'tab_obstacles',
    // 'tab_platforms',
  ];

  final List<ItemType> _tabTypes = [
    // ItemType.background,
    ItemType.character,
    // ItemType.obstacle,
    // ItemType.platform,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _gameState.t('settings_title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Dil Seçimi
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.purple.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _gameState.t('language_title'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLanguageButton('tr', 'TR'),
                        const SizedBox(width: 10),
                        _buildLanguageButton('en', 'EN'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.purple.shade100),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    await _gameState.restorePurchases();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _gameState.t('restore_purchase_success'),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Center(
                      child: Text(
                        _gameState.t('restore_purchases_button'),
                        style: GoogleFonts.poppins(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sekmeler
          // Container(
          //   color: Colors.purple.shade400,
          //   child: SingleChildScrollView(
          //     scrollDirection: Axis.horizontal,
          //     child: Row(
          //       children: List.generate(_tabs.length, (index) {
          //         return GestureDetector(
          //           onTap: () {
          //             setState(() {
          //               _selectedTab = index;
          //             });
          //           },
          //           child: Container(
          //             padding: const EdgeInsets.symmetric(
          //               horizontal: 20,
          //               vertical: 15,
          //             ),
          //             decoration: BoxDecoration(
          //               color: _selectedTab == index
          //                   ? Colors.white
          //                   : Colors.transparent,
          //               borderRadius: const BorderRadius.only(
          //                 topLeft: Radius.circular(15),
          //                 topRight: Radius.circular(15),
          //               ),
          //             ),
          //             child: Text(
          //               _gameState.t(_tabs[index]),
          //               style: GoogleFonts.poppins(
          //                 color: _selectedTab == index
          //                     ? Colors.purple.shade400
          //                     : Colors.white,
          //                 fontWeight: FontWeight.w600,
          //                 fontSize: 16,
          //               ),
          //             ),
          //           ),
          //         );
          //       }),
          //     ),
          //   ),
          // ),

          // İçerik
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _buildItemGrid(_tabTypes[_selectedTab]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(ItemType type) {
    final items = _gameState
        .getItemsByType(type)
        .where((item) => item.isPurchased && item.id != 'bundle_all_characters')
        .toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              _gameState.t('no_items'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _gameState.t('buy_items_hint'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    String selectedId = '';
    switch (type) {
      case ItemType.background:
        selectedId = _gameState.selectedBackgroundId;
        break;
      case ItemType.character:
        selectedId = _gameState.selectedCharacterId;
        break;
      case ItemType.obstacle:
        selectedId = _gameState.selectedObstacleId;
        break;
      case ItemType.platform:
        selectedId = _gameState.selectedPlatformId;
        break;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.id == selectedId;

        return GestureDetector(
          onTap: () async {
            setState(() {
              switch (type) {
                case ItemType.background:
                  _gameState.selectBackground(item.id);
                  break;
                case ItemType.character:
                  _gameState.selectCharacter(item.id);
                  break;
                case ItemType.obstacle:
                  _gameState.selectObstacle(item.id);
                  break;
                case ItemType.platform:
                  _gameState.selectPlatform(item.id);
                  break;
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_gameState.t(item.name)} ${_gameState.t('item_selected')}',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Center(
                    child:
                        item.assetPath.contains('/') ||
                            item.assetPath.endsWith('.png')
                        ? Image.asset(
                            'assets/images/${item.assetPath}',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getItemIcon(type),
                                size: 50,
                                color: Colors.white,
                              );
                            },
                          )
                        : Icon(
                            _getItemIcon(type),
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // İsim
                Text(
                  _gameState.t(item.name),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Seçili işareti
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _gameState.t('selected'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildLanguageButton(String code, String label) {
    bool isSelected = _gameState.languageNotifier.value == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gameState.setLanguage(code);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.purple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
