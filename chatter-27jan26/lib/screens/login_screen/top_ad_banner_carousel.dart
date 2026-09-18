import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/utilities/const.dart';

class TopAdBannerCarousel extends StatefulWidget {
  final String placement;
  const TopAdBannerCarousel({Key? key, this.placement = 'Login Page Banner'}) : super(key: key);

  @override
  State<TopAdBannerCarousel> createState() => _TopAdBannerCarouselState();
}

class _TopAdBannerCarouselState extends State<TopAdBannerCarousel> {
  List<dynamic> _ads = [];
  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAds();
  }

  void _fetchAds() {
    ApiService.shared.call(
      url: "${apiURL}ad/list",
      param: {'placement': widget.placement},
      completion: (response) {
        if (mounted && response['status'] == true) {
          final fetched = response['data'] as List<dynamic>? ?? [];
          if (fetched.isNotEmpty) {
            setState(() {
              _ads = fetched;
            });
            _startAutoSlide();
          }
        }
      },
    );
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (_ads.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _ads.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _extractMediaUrl(dynamic ad) {
    if (ad == null) return '';
    final raw = ad['media_url'];
    if (raw == null) return '';
    if (raw is List && raw.isNotEmpty) return raw[0].toString();
    if (raw is String) {
      if (raw.startsWith('[') && raw.endsWith(']')) {
        final cleaned = raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').trim();
        return cleaned.split(',').first.trim();
      }
      return raw;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) {
      // Sleek fallback promo banner if no user campaign is active
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        height: 85,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "ADVERTISEMENT",
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Promote your brand on LUMO!",
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Sponsored",
                  style: TextStyle(color: Color(0xFF2575FC), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 95,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _ads.length,
              itemBuilder: (context, index) {
                final ad = _ads[index];
                final mediaUrl = _extractMediaUrl(ad);
                final title = ad['campaign_name'] ?? 'LUMO Sponsor';
                final targetLink = ad['target_link'] ?? '';

                return GestureDetector(
                  onTap: () async {
                    if (targetLink.isNotEmpty) {
                      final uri = Uri.parse(targetLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: mediaUrl.isNotEmpty
                                ? Image.network(
                                    mediaUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      color: const Color(0xFF1E1E2C),
                                      child: const Icon(Icons.image_not_supported_rounded, color: Colors.white54),
                                    ),
                                  )
                                : Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "AD",
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 12,
                            right: 12,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          if (_ads.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_ads.length, (idx) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  width: _currentPage == idx ? 16 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == idx ? cPrimary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ]
        ],
      ),
    );
  }
}
