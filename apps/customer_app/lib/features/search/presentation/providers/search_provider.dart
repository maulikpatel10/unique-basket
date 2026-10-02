import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// Available sorting options for search results matching Screen 18.
enum SearchSortOption {
  relevance('Relevance'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  nameAsc('Name: A to Z');

  final String label;
  const SearchSortOption(this.label);
}

/// Data class holding matching products and keyword auto-suggestions for Screen 17.
class SearchSuggestionsData {
  final List<ProductModel> productSuggestions;
  final List<String> querySuggestions;

  const SearchSuggestionsData({
    required this.productSuggestions,
    required this.querySuggestions,
  });

  const SearchSuggestionsData.empty()
      : productSuggestions = const [],
        querySuggestions = const [];
}

/// State notifier for recently searched queries persisted locally.
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final LocalStorageService _storage;
  static const String _storageKey = AppConstants.keyCustomerRecentSearches;
  static const int _maxRecentSearches = 5;

  static const List<String> _defaultRecentSearches = [
    'Fresh Apples',
    'Bananas',
    'Tomatoes',
  ];

  RecentSearchesNotifier(this._storage) : super(_defaultRecentSearches) {
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    try {
      final list = _storage.getStringList(_storageKey);
      if (list != null && list.isNotEmpty) {
        state = list.take(_maxRecentSearches).toList();
      }
    } catch (_) {
      // Fallback
    }
  }

  void addSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updated = List<String>.from(state);
    updated.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    updated.insert(0, clean);

    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }

    state = updated;
    _storage.setStringList(_storageKey, updated);
  }

  void removeSearch(String query) {
    final updated = List<String>.from(state)
      ..removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
    state = updated;
    _storage.setStringList(_storageKey, updated);
  }

  void clearAll() {
    state = const [];
    _storage.setStringList(_storageKey, const []);
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return RecentSearchesNotifier(storage);
});

/// Category filter selection for Screen 18 (null means 'All Categories').
final searchSelectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Active sort option for Screen 18.
final searchSortOptionProvider =
    StateProvider<SearchSortOption>((ref) => SearchSortOption.relevance);

/// Provider computing live product and keyword suggestions for Screen 17.
final searchSuggestionsProvider =
    Provider.family<SearchSuggestionsData, String>((ref, query) {
  final cleanQuery = query.trim().toLowerCase();
  if (cleanQuery.isEmpty) {
    return const SearchSuggestionsData.empty();
  }

  final productsAsync = ref.watch(homeProductsProvider);
  final allProducts = (productsAsync.value ?? [])
      .where((p) => p.isPurchasable)
      .toList();

  // Match products by name, description, or category
  final matchingProducts = allProducts.where((p) {
    final nameMatch = p.name.toLowerCase().contains(cleanQuery);
    final descMatch = p.description?.toLowerCase().contains(cleanQuery) ?? false;
    final catMatch = p.categoryName?.toLowerCase().contains(cleanQuery) ?? false;
    return nameMatch || descMatch || catMatch;
  }).toList();

  // Generate intelligent keyword auto-suggestions
  final Set<String> querySuggestions = {};

  for (final p in matchingProducts) {
    final name = p.name.toLowerCase();
    if (name.contains(cleanQuery)) {
      querySuggestions.add(p.name.trim());
      if (p.categoryName != null && p.categoryName!.isNotEmpty) {
        querySuggestions.add('$cleanQuery ${p.categoryName!.toLowerCase()}');
      }
    }
  }

  // Common fresh grocery modifier suggestions
  if (querySuggestions.length < 5) {
    querySuggestions.add('$cleanQuery fresh');
    querySuggestions.add('$cleanQuery organic');
  }

  return SearchSuggestionsData(
    productSuggestions: matchingProducts.take(6).toList(),
    querySuggestions: querySuggestions.take(5).toList(),
  );
});

/// Provider computing full search results grid for Screen 18.
final searchResultsProvider =
    Provider.family<List<ProductModel>, String>((ref, query) {
  final cleanQuery = query.trim().toLowerCase();
  final productsAsync = ref.watch(homeProductsProvider);
  final allProducts = (productsAsync.value ?? [])
      .where((p) => p.isPurchasable)
      .toList();

  if (cleanQuery.isEmpty) {
    return [];
  }

  final selectedCategoryId = ref.watch(searchSelectedCategoryProvider);
  final sortOption = ref.watch(searchSortOptionProvider);

  // 1. Filter by query
  var results = allProducts.where((p) {
    final nameMatch = p.name.toLowerCase().contains(cleanQuery);
    final descMatch = p.description?.toLowerCase().contains(cleanQuery) ?? false;
    final catMatch = p.categoryName?.toLowerCase().contains(cleanQuery) ?? false;
    return nameMatch || descMatch || catMatch;
  }).toList();

  // 2. Filter by selected category chip if any
  if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
    results = results.where((p) => p.categoryId == selectedCategoryId).toList();
  }

  // 3. Sort results
  switch (sortOption) {
    case SearchSortOption.relevance:
      results.sort((a, b) {
        final aExact = a.name.toLowerCase().startsWith(cleanQuery);
        final bExact = b.name.toLowerCase().startsWith(cleanQuery);
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        return a.name.compareTo(b.name);
      });
      break;
    case SearchSortOption.priceLowToHigh:
      results.sort((a, b) => a.price.compareTo(b.price));
      break;
    case SearchSortOption.priceHighToLow:
      results.sort((a, b) => b.price.compareTo(a.price));
      break;
    case SearchSortOption.nameAsc:
      results.sort((a, b) => a.name.compareTo(b.name));
      break;
  }

  return results;
});
