import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/poi.dart';

class HomeSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<Poi> suggestions;
  final Position? userPosition;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<Poi> onSuggestionSelected;

  const HomeSearchBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.suggestions,
    this.userPosition,
    required this.onChanged,
    required this.onClear,
    required this.onSuggestionSelected,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  String _formatDistance(Poi poi) {
    if (widget.userPosition == null ||
        poi.latitude == 0.0 ||
        poi.longitude == 0.0) {
      return '';
    }
    final meters = Geolocator.distanceBetween(
      widget.userPosition!.latitude,
      widget.userPosition!.longitude,
      poi.latitude,
      poi.longitude,
    );
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.toInt()} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions =
        _isFocused &&
        widget.searchQuery.trim().isNotEmpty &&
        widget.suggestions.isNotEmpty;

    return TapRegion(
      onTapOutside: (_) {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.searchController,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa điểm, món ăn...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: widget.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            widget.onClear();
                            _focusNode.unfocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Search Suggestions Dropdown Overlay
            if (showSuggestions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Card(
                  elevation: 6,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: widget.suggestions.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final poi = widget.suggestions[index];
                        final distanceStr = _formatDistance(poi);
                        final hasCover =
                            poi.coverImage != null &&
                            poi.coverImage!.isNotEmpty;

                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: hasCover
                                  ? Image.network(
                                      poi.coverImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.restaurant_rounded,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.restaurant_rounded,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                            ),
                          ),
                          title: Text(
                            poi.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            poi.category ?? 'Ẩm thực đường phố',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: distanceStr.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      distanceStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(
                                  Icons.north_west_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                          onTap: () {
                            widget.searchController.text = poi.name;
                            _focusNode.unfocus();
                            widget.onSuggestionSelected(poi);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
