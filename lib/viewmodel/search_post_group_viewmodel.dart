import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';

class SearchPostGroupViewModel extends ChangeNotifier {
  final String groupId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PostModel> _allPosts = [];
  List<PostModel> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<PostModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get hasSearched => _searchQuery.isNotEmpty;

  SearchPostGroupViewModel({required this.groupId}) {
    debugPrint('🎬 SearchPostGroupViewModel created for groupId: $groupId');
    _loadAllPosts();
  }

  // Load tất cả bài viết của group
  Future<void> _loadAllPosts() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔍 Loading posts for groupId: $groupId');

      // Query posts từ Firestore - SỬA: collection 'Post' thay vì 'posts'
      final snapshot =
          await _firestore
              .collection('Post')
              .where('groupId', isEqualTo: groupId)
              .get();

      debugPrint('📦 Firestore returned ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No posts found for this group!');
        _allPosts = [];
      } else {
        _allPosts = [];
        for (var doc in snapshot.docs) {
          try {
            final post = PostModel.fromMap(doc.id, doc.data());
            _allPosts.add(post);
            debugPrint(
              '📄 Loaded post ${doc.id}: "${post.content.substring(0, post.content.length > 30 ? 30 : post.content.length)}..."',
            );
          } catch (e) {
            debugPrint('❌ Error parsing post ${doc.id}: $e');
          }
        }
      }

      debugPrint('✅ Successfully loaded ${_allPosts.length} posts');
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading posts: $e');
      debugPrint('Stack trace: $stackTrace');
      _allPosts = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tìm kiếm bài viết
  void searchPosts(String query) {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    // Chuyển query về lowercase để tìm kiếm không phân biệt hoa thường
    final searchLower = _searchQuery.toLowerCase();

    _searchResults =
        _allPosts.where((post) {
          // Tìm trong content
          final contentMatch = post.content.toLowerCase().contains(searchLower);

          if (contentMatch) {
            debugPrint(
              '✅ Match found in post ${post.id}: ${post.content.substring(0, post.content.length > 50 ? 50 : post.content.length)}...',
            );
          }

          return contentMatch;
        }).toList();

    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // Refresh search results
  Future<void> refreshSearch() async {
    await _loadAllPosts();
    if (_searchQuery.isNotEmpty) {
      searchPosts(_searchQuery);
    }
  }
}
