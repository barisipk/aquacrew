import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/game_item.dart';

class GameState extends ChangeNotifier {
  static final GameState _instance = GameState._internal();
  factory GameState() => _instance;
  GameState._internal();

  SharedPreferences? _prefs;
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool isAvailable = false;

  // Seçili öğeler
  String selectedBackgroundId = 'bg_default';
  String selectedCharacterId = 'char_default';
  String selectedObstacleId = 'obs_default';
  String selectedPlatformId = 'plat_default';

  // Tüm öğeler
  List<GameItem> allItems = [];

  // Localization
  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('tr');

  // Gyroscope Control
  final ValueNotifier<bool> gyroscopeNotifier = ValueNotifier<bool>(false);
  bool get useGyroscope => gyroscopeNotifier.value;

  final Map<String, Map<String, String>> _translations = {
    'tr': {
      'app_title': 'Aqua Crew',
      'start_button': 'BAŞLA',
      'settings_button': 'AYARLAR',
      'market_button': 'MARKET',
      'high_score_title': 'EN YÜKSEK SKOR',
      'game_over': 'OYUN BİTTİ',
      'your_score': 'Skorun',
      'score': 'Puan',
      'main_menu': 'Ana Menü',
      'play_again': 'Tekrar Oyna',
      'settings_title': 'Ayarlar',
      'language_title': 'Dil / Language',
      'tab_backgrounds': 'Arka Planlar',
      'tab_characters': 'Karakterler',
      'tab_obstacles': 'Engeller',
      'tab_platforms': 'Platformlar',
      'no_items': 'Henüz satın alınmış öğe yok',
      'buy_items_hint': 'Market\'ten yeni öğeler satın alabilirsiniz',
      'selected': 'SEÇİLİ',
      'market_title': 'Market',
      'balance': 'Bakiye',
      'buy': 'Satın Al',
      'select': 'Seç',
      'insufficient_funds': 'Yetersiz Bakiye',
      'item_purchased': 'satın alındı!',
      'item_selected': 'seçildi!',
      'owned': 'SAHİP',
      'cancel': 'İptal',
      'buy_confirm_title': 'Satın Al',
      'buy_confirm_content': 'öğesini satın almak istiyor musunuz?',

      // Items
      'item_bg_default_name': 'Varsayılan',
      'item_bg_default_desc': 'Klasik mavi gökyüzü',

      'item_char_default_name': 'Ahtapot',
      'item_char_default_desc': 'Sevimli ahtapot',

      'item_char_octopus_name': 'Ahtapot',
      'item_char_octopus_desc': 'Sekiz kollu dost',
      'item_char_octopus2_name': 'Kızgın Ahtapot',
      'item_char_octopus2_desc': 'Biraz sinirli görünüyor',
      'item_char_puffer_name': 'Balon Balığı',
      'item_char_puffer_desc': 'Dikenli ve şişkin',
      'item_char_hammerhead_name': 'Çekiç Baş',
      'item_char_hammerhead_desc': 'Güçlü köpekbalığı',
      'item_char_jellyfish_name': 'Deniz Anası',
      'item_char_jellyfish_desc': 'Parlayan deniz anası',
      'item_char_starfish_name': 'Deniz Yıldızı',
      'item_char_starfish_desc': 'Beş köşeli yıldız',
      'item_char_seal_name': 'Fok',
      'item_char_seal_desc': 'Oyuncu fok balığı',
      'item_char_photographer_name': 'Fotoğrafçı',
      'item_char_photographer_desc': 'Anı yakalayan balık',
      'item_char_lobster_name': 'Istakoz',
      'item_char_lobster_desc': 'Kıskaçlı deniz canlısı',
      'item_char_cameraman_name': 'Kameraman',
      'item_char_cameraman_desc': 'Film çeken balık',
      'item_char_turtle_name': 'Kaplumbağa',
      'item_char_turtle_desc': 'Bilge deniz kaplumbağası',
      'item_char_shark_name': 'Köpekbalığı',
      'item_char_shark_desc': 'Denizlerin hakimi',
      'item_char_squid_name': 'Mürekkep Balığı',
      'item_char_squid_desc': 'Hızlı ve zeki',
      'item_char_robot_name': 'Robot Balık',
      'item_char_robot_desc': 'Gelecekten gelen balık',
      'item_char_snail_name': 'Salyangoz',
      'item_char_snail_desc': 'Yavaş ama kararlı',
      'item_char_otter_name': 'Su Samuru',
      'item_char_otter_desc': 'Sevimli su samuru',
      'item_char_dev_name': 'Yazılımcı',
      'item_char_dev_desc': 'Kod yazan balık',
      'item_char_crab_name': 'Yengeç',
      'item_char_crab_desc': 'Yan yan yürüyen yengeç',
      'item_char_dolphin_name': 'Yunus',
      'item_char_dolphin_desc': 'Zeki ve dost canlısı',

      'item_bundle_all_name': 'Tüm Karakterler',
      'item_bundle_all_desc': 'Tüm karakterleri tek seferde aç!',

      'item_obs_default_name': 'Varsayılan',
      'item_obs_default_desc': 'Klasik düşman',

      'item_plat_default_name': 'Varsayılan',
      'item_plat_default_desc': 'Klasik platform',

      'restore_purchases_button': 'Satın Almaları Geri Yükle',
      'restore_purchase_success': 'Satın almalar geri yüklendi',
      'restore_purchase_error': 'Geri yükleme sırasında hata oluştu',
      'gyroscope_control': 'Eğim Kontrolü',
      'gyroscope_description': 'Cihazı eğerek oyna',
    },
    'en': {
      'app_title': 'Aqua Crew',
      'start_button': 'START',
      'settings_button': 'SETTINGS',
      'market_button': 'MARKET',
      'high_score_title': 'HIGH SCORE',
      'game_over': 'GAME OVER',
      'your_score': 'Score',
      'score': 'Score',
      'main_menu': 'Main Menu',
      'play_again': 'Play Again',
      'settings_title': 'Settings',
      'language_title': 'Language / Dil',
      'tab_backgrounds': 'Backgrounds',
      'tab_characters': 'Characters',
      'tab_obstacles': 'Obstacles',
      'tab_platforms': 'Platforms',
      'no_items': 'No items purchased yet',
      'buy_items_hint': 'You can buy new items from the Market',
      'selected': 'SELECTED',
      'market_title': 'Market',
      'balance': 'Balance',
      'buy': 'Buy',
      'select': 'Select',
      'insufficient_funds': 'Insufficient Funds',
      'item_purchased': 'purchased!',
      'item_selected': 'selected!',
      'owned': 'OWNED',
      'cancel': 'Cancel',
      'buy_confirm_title': 'Buy',
      'buy_confirm_content': 'Do you want to buy this item?',

      'restore_purchases_button': 'Restore Purchases',
      'restore_purchase_success': 'Purchases restored successfully',
      'restore_purchase_error': 'Error restoring purchases',

      // Items
      'item_bg_default_name': 'Default',
      'item_bg_default_desc': 'Classic blue sky',

      'item_char_default_name': 'Octopus',
      'item_char_default_desc': 'Cute octopus',

      'item_char_octopus_name': 'Octopus',
      'item_char_octopus_desc': 'Eight-armed friend',
      'item_char_octopus2_name': 'Angry Octopus',
      'item_char_octopus2_desc': 'Looks a bit angry',
      'item_char_puffer_name': 'Pufferfish',
      'item_char_puffer_desc': 'Spiky and puffy',
      'item_char_hammerhead_name': 'Hammerhead',
      'item_char_hammerhead_desc': 'Strong shark',
      'item_char_jellyfish_name': 'Jellyfish',
      'item_char_jellyfish_desc': 'Glowing jellyfish',
      'item_char_starfish_name': 'Starfish',
      'item_char_starfish_desc': 'Five-pointed star',
      'item_char_seal_name': 'Seal',
      'item_char_seal_desc': 'Playful seal',
      'item_char_photographer_name': 'Photographer',
      'item_char_photographer_desc': 'Capturing the moment',
      'item_char_lobster_name': 'Lobster',
      'item_char_lobster_desc': 'Clawed sea creature',
      'item_char_cameraman_name': 'Cameraman',
      'item_char_cameraman_desc': 'Filming fish',
      'item_char_turtle_name': 'Turtle',
      'item_char_turtle_desc': 'Wise sea turtle',
      'item_char_shark_name': 'Shark',
      'item_char_shark_desc': 'Ruler of the seas',
      'item_char_squid_name': 'Squid',
      'item_char_squid_desc': 'Fast and smart',
      'item_char_robot_name': 'Robot Fish',
      'item_char_robot_desc': 'Fish from the future',
      'item_char_snail_name': 'Snail',
      'item_char_snail_desc': 'Slow but steady',
      'item_char_otter_name': 'Otter',
      'item_char_otter_desc': 'Cute otter',
      'item_char_dev_name': 'Developer',
      'item_char_dev_desc': 'Coding fish',
      'item_char_crab_name': 'Crab',
      'item_char_crab_desc': 'Walking sideways',
      'item_char_dolphin_name': 'Dolphin',
      'item_char_dolphin_desc': 'Smart and friendly',

      'item_bundle_all_name': 'All Characters',
      'item_bundle_all_desc': 'Unlock all characters at once!',

      'item_obs_default_name': 'Default',
      'item_obs_default_desc': 'Classic enemy',

      'item_plat_default_name': 'Default',
      'item_plat_default_desc': 'Classic platform',
      'gyroscope_control': 'Tilt Control',
      'gyroscope_description': 'Play by tilting device',
    },
  };

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initializeItems();
    _loadState();
    _loadLanguage();
    _loadGyroscope();

    // IAP Initialization
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        // handle error here.
      },
    );
    await _initStoreInfo();
  }

  Future<void> _initStoreInfo() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      return;
    }

    // Get all product IDs from our items
    Set<String> _kIds = allItems
        .where((item) => !item.isPurchased && item.price > 0)
        .map((item) => item.id)
        .toSet();

    if (_kIds.isEmpty) return;

    ProductDetailsResponse response = await _iap.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle missing IDs
      if (kDebugMode) {
        print('Products not found: ${response.notFoundIDs}');
      }
    }
    _products = List<ProductDetails>.from(response.productDetails);

    // Update items with store details
    for (var product in _products) {
      final index = allItems.indexWhere((item) => item.id == product.id);
      if (index != -1) {
        allItems[index] = allItems[index].copyWith(
          displayPrice: product.price,
          storeTitle: product.title,
          storeDescription: product.description,
        );
      }
    }
    notifyListeners();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      print(
        'Purchase Update: status=${purchaseDetails.status} productID=${purchaseDetails.productID}',
      );
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print('Purchase Error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          print('Purchase success/restored: ${purchaseDetails.productID}');
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Verify purchase with backend or local logic
    return true;
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    print('Invalid Purchase: ${purchaseDetails.productID}');
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    print('Delivering Product: ${purchaseDetails.productID}');
    // Unlock the item
    purchaseItem(purchaseDetails.productID);
  }

  Future<void> buyProduct(String productId) async {
    if (!isAvailable) return;

    // Find product details
    final ProductDetails productDetails = _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => ProductDetails(
        id: productId,
        title: 'Unknown',
        description: '',
        price: '',
        rawPrice: 0,
        currencyCode: '',
      ),
    );
    if (productDetails.title != 'Unknown') {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      if (await _iap.isAvailable()) {
        _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } else {
      if (kDebugMode) {
        print("Product not found in store: $productId");
      }
    }
  }

  Future<void> restorePurchases() async {
    if (await _iap.isAvailable()) {
      await _iap.restorePurchases();
    }
  }

  void _loadLanguage() {
    String? savedLang = _prefs?.getString('language');
    if (savedLang != null) {
      languageNotifier.value = savedLang;
    } else {
      // Detect system language
      // PlatformDispatcher.instance.locale.languageCode might be 'tr' or 'en'
      // Default to 'tr' if system is 'tr', otherwise 'en'
      final systemLang = PlatformDispatcher.instance.locale.languageCode;
      if (systemLang == 'tr') {
        languageNotifier.value = 'tr';
      } else {
        languageNotifier.value = 'en';
      }
    }
  }

  Future<void> setLanguage(String code) async {
    if (_translations.containsKey(code)) {
      languageNotifier.value = code;
      await _prefs?.setString('language', code);
    }
  }

  void _loadGyroscope() {
    gyroscopeNotifier.value = _prefs?.getBool('useGyroscope') ?? false;
  }

  Future<void> setGyroscope(bool value) async {
    gyroscopeNotifier.value = value;
    await _prefs?.setBool('useGyroscope', value);
    notifyListeners();
  }

  String t(String key) {
    return _translations[languageNotifier.value]?[key] ?? key;
  }

  void _initializeItems() {
    allItems = [
      // Arka Planlar
      GameItem(
        id: 'bg_default',
        name: 'item_bg_default_name',
        type: ItemType.background,
        price: 0,
        isPurchased: true,
        assetPath: 'default',
        description: 'item_bg_default_desc',
      ),

      // Karakterler
      GameItem(
        id: 'bundle_all_characters',
        name: 'item_bundle_all_name',
        type: ItemType.character,
        price: 29.99,
        assetPath: 'arkaplansız-logo.png',
        description: 'item_bundle_all_desc',
      ),
      GameItem(
        id: 'char_default',
        name: 'item_char_default_name',
        type: ItemType.character,
        price: 0,
        isPurchased: true,
        assetPath: 'karakterler/ahtapot.png',
        description: 'item_char_default_desc',
      ),

      GameItem(
        id: 'char_octopus2',
        name: 'item_char_octopus2_name',
        type: ItemType.character,
        price: 3.99,
        assetPath: 'karakterler/ahtapot2.png',
        description: 'item_char_octopus2_desc',
      ),
      GameItem(
        id: 'aquacrew_balonbaligi',
        name: 'item_char_puffer_name',
        type: ItemType.character,
        price: 1.99,
        assetPath: 'karakterler/balonbaligi.png',
        description: 'item_char_puffer_desc',
      ),
      GameItem(
        id: 'char_hammerhead',
        name: 'item_char_hammerhead_name',
        type: ItemType.character,
        price: 3.99,
        assetPath: 'karakterler/cekicbaskopekbaligi.png',
        description: 'item_char_hammerhead_desc',
      ),
      GameItem(
        id: 'char_jellyfish',
        name: 'item_char_jellyfish_name',
        type: ItemType.character,
        price: 1.99,
        assetPath: 'karakterler/denizanasi.png',
        description: 'item_char_jellyfish_desc',
      ),
      GameItem(
        id: 'char_starfish',
        name: 'item_char_starfish_name',
        type: ItemType.character,
        price: 1.99,
        assetPath: 'karakterler/denizyildizi.png',
        description: 'item_char_starfish_desc',
      ),
      GameItem(
        id: 'char_seal',
        name: 'item_char_seal_name',
        type: ItemType.character,
        price: 2.99,
        assetPath: 'karakterler/fok.png',
        description: 'item_char_seal_desc',
      ),
      GameItem(
        id: 'char_photographer',
        name: 'item_char_photographer_name',
        type: ItemType.character,
        price: 2.99,
        assetPath: 'karakterler/fotografcibalik.png',
        description: 'item_char_photographer_desc',
      ),
      GameItem(
        id: 'char_lobster',
        name: 'item_char_lobster_name',
        type: ItemType.character,
        price: 1.99,
        assetPath: 'karakterler/istakoz.png',
        description: 'item_char_lobster_desc',
      ),
      GameItem(
        id: 'char_cameraman',
        name: 'item_char_cameraman_name',
        type: ItemType.character,
        price: 2.99,
        assetPath: 'karakterler/kameramanbalik.png',
        description: 'item_char_cameraman_desc',
      ),
      GameItem(
        id: 'char_turtle',
        name: 'item_char_turtle_name',
        type: ItemType.character,
        price: 2.99,
        assetPath: 'karakterler/kaplumbaga.png',
        description: 'item_char_turtle_desc',
      ),
      GameItem(
        id: 'char_shark',
        name: 'item_char_shark_name',
        type: ItemType.character,
        price: 3.99,
        assetPath: 'karakterler/kopekbaligi.png',
        description: 'item_char_shark_desc',
      ),
      GameItem(
        id: 'char_squid',
        name: 'item_char_squid_name',
        type: ItemType.character,
        price: 2.99,
        assetPath: 'karakterler/murekkepbaligi.png',
        description: 'item_char_squid_desc',
      ),
      GameItem(
        id: 'char_robot',
        name: 'item_char_robot_name',
        type: ItemType.character,
        price: 3.99,
        assetPath: 'karakterler/robotbalik.png',
        description: 'item_char_robot_desc',
      ),
      GameItem(
        id: 'char_snail',
        name: 'item_char_snail_name',
        type: ItemType.character,
        price: 1.99,
        assetPath: 'karakterler/salyangoz.png',
        description: 'item_char_snail_desc',
      ),
      GameItem(
        id: 'char_otter',
        name: 'item_char_otter_name',
        type: ItemType.character,
        price: 2.99,
        assetPath: 'karakterler/susamuru.png',
        description: 'item_char_otter_desc',
      ),
      GameItem(
        id: 'char_dev',
        name: 'item_char_dev_name',
        type: ItemType.character,
        price: 3.99,
        assetPath: 'karakterler/yazilimcibalik.png',
        description: 'item_char_dev_desc',
      ),
      GameItem(
        id: 'char_crab',
        name: 'item_char_crab_name',
        type: ItemType.character,
        price: 1.99,
        assetPath: 'karakterler/yengec.png',
        description: 'item_char_crab_desc',
      ),
      GameItem(
        id: 'char_dolphin',
        name: 'item_char_dolphin_name',
        type: ItemType.character,
        price: 3.99,
        assetPath: 'karakterler/yunusbaligi.png',
        description: 'item_char_dolphin_desc',
      ),

      // Engeller
      GameItem(
        id: 'obs_default',
        name: 'item_obs_default_name',
        type: ItemType.obstacle,
        price: 0,
        isPurchased: true,
        assetPath: 'dusman.png',
        description: 'item_obs_default_desc',
      ),

      // Platformlar
      GameItem(
        id: 'plat_default',
        name: 'item_plat_default_name',
        type: ItemType.platform,
        price: 0,
        isPurchased: true,
        assetPath: 'platform.png',
        description: 'item_plat_default_desc',
      ),
    ];
  }

  void _loadState() {
    // Seçili öğeleri yükle
    selectedBackgroundId =
        _prefs?.getString('selectedBackground') ?? 'bg_default';
    selectedCharacterId =
        _prefs?.getString('selectedCharacter') ?? 'char_default';
    selectedObstacleId = _prefs?.getString('selectedObstacle') ?? 'obs_default';
    selectedPlatformId =
        _prefs?.getString('selectedPlatform') ?? 'plat_default';

    // Satın alınan öğeleri yükle
    final purchasedIds = _prefs?.getStringList('purchasedItems') ?? [];
    for (var item in allItems) {
      if (purchasedIds.contains(item.id)) {
        final index = allItems.indexOf(item);
        allItems[index] = item.copyWith(isPurchased: true);
      }
    }
  }

  Future<void> selectBackground(String id) async {
    selectedBackgroundId = id;
    await _prefs?.setString('selectedBackground', id);
    notifyListeners();
  }

  Future<void> selectCharacter(String id) async {
    selectedCharacterId = id;
    await _prefs?.setString('selectedCharacter', id);
    notifyListeners();
  }

  Future<void> selectObstacle(String id) async {
    selectedObstacleId = id;
    await _prefs?.setString('selectedObstacle', id);
    notifyListeners();
  }

  Future<void> selectPlatform(String id) async {
    selectedPlatformId = id;
    await _prefs?.setString('selectedPlatform', id);
    notifyListeners();
  }

  Future<void> purchaseItem(String id) async {
    print('Attempting to purchase/unlock item: $id');
    final index = allItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      print('Item found in allItems: $id');
      allItems[index] = allItems[index].copyWith(isPurchased: true);

      final purchasedIds = _prefs?.getStringList('purchasedItems') ?? [];
      if (!purchasedIds.contains(id)) {
        purchasedIds.add(id);
        await _prefs?.setStringList('purchasedItems', purchasedIds);
      }
      notifyListeners();
    } else {
      print('Item NOT found in allItems: $id');
    }

    // Eğer tüm karakterler paketi alındıysa hepsini aç
    if (id == 'bundle_all_characters') {
      print('Unlocking all characters for bundle...');
      for (int i = 0; i < allItems.length; i++) {
        if (allItems[i].type == ItemType.character) {
          // Exclude specific characters from the bundle
          const excludedIds = [
            'bundle_all_characters', // Don't unlock the bundle itself (already purchased)
          ];

          if (excludedIds.contains(allItems[i].id)) {
            continue;
          }

          allItems[i] = allItems[i].copyWith(isPurchased: true);

          final purchasedIds = _prefs?.getStringList('purchasedItems') ?? [];
          if (!purchasedIds.contains(allItems[i].id)) {
            purchasedIds.add(allItems[i].id);
            await _prefs?.setStringList('purchasedItems', purchasedIds);
          }
        }
      }
      notifyListeners();
      print('All characters unlocked.');
    }
  }

  List<GameItem> getItemsByType(ItemType type) {
    return allItems.where((item) => item.type == type).toList();
  }

  GameItem? getItemById(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  GameItem getSelectedBackground() {
    return getItemById(selectedBackgroundId) ?? allItems.first;
  }

  GameItem getSelectedCharacter() {
    return getItemById(selectedCharacterId) ?? allItems.first;
  }

  GameItem getSelectedObstacle() {
    return getItemById(selectedObstacleId) ?? allItems.first;
  }

  GameItem getSelectedPlatform() {
    return getItemById(selectedPlatformId) ?? allItems.first;
  }
}
