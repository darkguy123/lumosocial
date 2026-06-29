import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/screens/drama_screen/drama_details_screen.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/web_service.dart';

class DramaScreen extends StatefulWidget {
  const DramaScreen({super.key});

  @override
  State<DramaScreen> createState() => _DramaScreenState();
}

class _DramaScreenState extends State<DramaScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _dramas = [];
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchDramas();
  }

  void _fetchDramas() {
    setState(() {
      _isLoading = true;
    });

    ApiService.shared.call(
      url: WebService.dramaList,
      param: {},
      completion: (response) {
        setState(() {
          _isLoading = false;
        });
        if (response['status'] == true) {
          setState(() {
            _dramas = response['data'] ?? [];
          });
        }
      },
    );
  }

  void _onSearchTextChanged(String text) {
    if (text.trim().length < 3) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    ApiService.shared.call(
      url: WebService.dramaSearch,
      param: {'query': text.trim()},
      completion: (response) {
        if (response['status'] == true && _isSearching) {
          setState(() {
            _suggestions = response['data'] ?? [];
          });
        }
      },
    );
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Hide keyboard & suggestions, go directly to search results view
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions.clear();
      _isSearching = false;
    });

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
      barrierDismissible: false,
    );

    ApiService.shared.call(
      url: WebService.dramaSearch,
      param: {'query': query.trim()},
      completion: (response) {
        Get.back(); // Close dialog
        if (response['status'] == true) {
          final results = response['data'] as List? ?? [];
          if (results.isEmpty) {
            Get.snackbar("No Results", "No drama series matched your search.", backgroundColor: Colors.orange);
          } else {
            // Show search results in a neat overlay sheet
            _showSearchResultsBottomSheet(query, results);
          }
        }
      },
    );
  }

  void _showSearchResultsBottomSheet(String query, List<dynamic> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Search Results for \"$query\"",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 350,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['thumbnail'] ?? '',
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${item['views_count'] ?? 0} Views", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                      onTap: () {
                        Get.back(); // Close bottom sheet
                        Get.to(() => DramaDetailsScreen(dramaId: int.parse(item['id'].toString())));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar & Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Drama Box",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy-Bold',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Stack(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchTextChanged,
                        onSubmitted: _executeSearch,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search short dramas...",
                          hintStyle: const TextStyle(color: Colors.white30),
                          fillColor: const Color(0xFF1E1E1E),
                          filled: true,
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchTextChanged("");
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content OR Suggestions Overlay
            Expanded(
              child: Stack(
                children: [
                  // Main Drama Grid/List
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
                      : _dramas.isEmpty
                          ? const Center(
                              child: Text(
                                "No drama series available.",
                                style: TextStyle(color: Colors.white30),
                              ),
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF00FF87),
                              backgroundColor: const Color(0xFF1E1E1E),
                              onRefresh: () async {
                                _fetchDramas();
                              },
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: _dramas.length,
                                itemBuilder: (context, index) {
                                  final drama = _dramas[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Get.to(() => DramaDetailsScreen(dramaId: int.parse(drama['id'].toString())));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              drama['thumbnail'] ?? '',
                                              fit: BoxFit.cover,
                                            ),
                                            // Gradient overlay
                                            Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.transparent, Colors.black87],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 12,
                                              right: 12,
                                              bottom: 12,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    drama['title'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${drama['views_count'] ?? 0} Views",
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                  // Suggestions Overlay Dropdown
                  if (_isSearching && _suggestions.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final item = _suggestions[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item['thumbnail'] ?? '',
                                  width: 35,
                                  height: 45,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                item['title'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 12),
                              onTap: () {
                                setState(() {
                                  _suggestions.clear();
                                  _isSearching = false;
                                  _searchController.clear();
                                });
                                Get.to(() => DramaDetailsScreen(dramaId: int.parse(item['id'].toString())));
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
