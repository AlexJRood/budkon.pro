import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:wall/emma/anchors/anchors_wall.dart';

// Location model to store place data
class LocationData {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? country;
  final String? state;
  final String? city;

  LocationData({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.country,
    this.state,
    this.city,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      displayName: json['display_name'] ?? '',
      latitude: double.parse((json['lat'] ?? '0.0').toString()),
      longitude: double.parse((json['lon'] ?? '0.0').toString()),
      country: json['address']?['country'],
      state: json['address']?['state'],
      city:
      json['address']?['city'] ??
          json['address']?['town'] ??
          json['address']?['village'],
    );
  }

  @override
  String toString() {
    return 'LocationData(name: $displayName, lat: $latitude, lng: $longitude)';
  }
}

// Location search service
class LocationSearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<List<LocationData>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '5',
        },
      );

      final response = await http
          .get(
        uri,
        headers: {
          'User-Agent': 'Hously.pro/1.0',
        },
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LocationData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error searching locations: $e');
      return [];
    }
  }
}

// Location Search Dialog Widget
class LocationSearchDialog extends StatefulWidget {
  final String initialValue;
  final WidgetRef ref;
  final void Function(LocationData)? onSelected;

  const LocationSearchDialog({
    super.key,
    this.initialValue = '',
    required this.ref,
    this.onSelected,
  });

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<LocationData> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocations(value);
    });
    setState(() {}); // refresh suffixIcon visibility
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final results = await LocationSearchService.searchLocations(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double postWidth = screenWidth > 700 ? 700 : screenWidth * 0.8;
        double titleFontSize = postWidth * 0.028;
        double subtitleFontSize = postWidth * 0.022;
        double horizontalPadding = postWidth * 0.03;
        double verticalPadding = postWidth * 0.02;
        double iconSize = postWidth * 0.03;

        return EmmaUiAnchorTarget(
           anchorKey: WallEmmaAnchors.locationSearchDialog.anchorKey,

           spec: WallEmmaAnchors.locationSearchDialog,
           runtimeMode: EmmaUiAnchorRuntimeMode.semanticOnly,
           tapMode: EmmaUiAnchorTapMode.disabled,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: CustomColors.secondaryWidgetColor(
              context,
              widget.ref,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: CustomColors.secondaryWidgetColor(
                  context,
                  widget.ref,
                ).withOpacity(0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: iconSize * 1.2,
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          widget.ref,
                        ).withOpacity(0.8),
                      ),
                      SizedBox(width: horizontalPadding * 0.5),
                      Text(
                        'search location'.tr,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            widget.ref,
                          ).withOpacity(0.8),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: iconSize,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            widget.ref,
                          ).withAlpha(178),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalPadding),
          
                  // Search Field
                  EmmaUiAnchorTarget(
                    anchorKey: WallEmmaAnchors.locationSearchField.anchorKey,

                    spec: WallEmmaAnchors.locationSearchField,
                    runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
                    tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          widget.ref,
                        ),
                        fontSize: subtitleFontSize,
                      ),
                      decoration: InputDecoration(
                        hintText: 'enter city address place'.tr,
                        hintStyle: TextStyle(
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            widget.ref,
                          ).withAlpha(153),
                          fontSize: subtitleFontSize,
                        ),
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          size: iconSize * 0.9,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            widget.ref,
                          ).withAlpha(178),
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _searchResults = [];
                              _isLoading = false;
                            });
                          },
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            size: iconSize * 0.8,
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              widget.ref,
                            ).withAlpha(178),
                          ),
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              widget.ref,
                            ).withAlpha(76),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              widget.ref,
                            ).withAlpha(76),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: CustomColors.secondaryWidgetTextColor(
                              context,
                              widget.ref,
                            ).withOpacity(0.2),
                          ),
                        ),
                        filled: true,
                        fillColor: CustomColors.secondaryWidgetColor(
                          context,
                          widget.ref,
                        ).withOpacity(0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: verticalPadding),
          
                  // Results
                  Expanded(
                    child: _buildSearchResults(
                      iconSize: iconSize,
                      titleFontSize: titleFontSize,
                      subtitleFontSize: subtitleFontSize,
                      verticalPadding: verticalPadding,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults({
    required double iconSize,
    required double titleFontSize,
    required double subtitleFontSize,
    required double verticalPadding,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: CustomColors.secondaryWidgetTextColor(context, widget.ref),
        ),
      );
    }

    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLocationAdd01,
              size: iconSize * 2.5,
              color: CustomColors.secondaryWidgetTextColor(
                context,
                widget.ref,
              ).withAlpha(128),
            ),
            SizedBox(height: verticalPadding),
            Text(
              'start typing to search'.tr,
              style: TextStyle(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  widget.ref,
                ).withAlpha(178),
                fontSize: subtitleFontSize,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLocationRemove01,
              size: iconSize * 2.5,
              color: CustomColors.secondaryWidgetTextColor(
                context,
                widget.ref,
              ).withAlpha(128),
            ),
            SizedBox(height: verticalPadding),
            Text(
              'no locations found'.tr,
              style: TextStyle(
                color: CustomColors.secondaryWidgetTextColor(
                  context,
                  widget.ref,
                ).withAlpha(178),
                fontSize: subtitleFontSize,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return EmmaUiAnchorTarget(
          anchorKey: '${WallEmmaAnchors.locationResultItem.anchorKey}_$index',
          runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
          tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: CustomColors.secondaryWidgetColor(context, widget.ref),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: CustomColors.secondaryWidgetTextColor(
                  context,
                  widget.ref,
                ).withOpacity(0.08),
                highlightColor: CustomColors.secondaryWidgetTextColor(
                  context,
                  widget.ref,
                ).withOpacity(0.04),
                onTap: () {
                  widget.onSelected?.call(location);
                  Navigator.of(context).pop(location);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: verticalPadding,
                    vertical: verticalPadding * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: CustomColors.secondaryWidgetColor(context, widget.ref)
                        .withOpacity(
                      Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.18,
                    ),
                    border: Border.all(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        widget.ref,
                      ).withAlpha(26),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon bubble
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CustomColors.secondaryWidgetColor(context, widget.ref)
                              .withOpacity(
                            Theme.of(context).brightness == Brightness.dark
                                ? 0.5
                                : 0.3,
                          ),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation03,
                          size: iconSize,
                          color: CustomColors.secondaryWidgetTextColor(
                            context,
                            widget.ref,
                          ).withAlpha(178),
                        ),
                      ),
                      SizedBox(width: verticalPadding),
          
                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.city ?? location.displayName.split(',').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: titleFontSize * 0.7,
                                color: CustomColors.secondaryWidgetTextColor(
                                  context,
                                  widget.ref,
                                ).withAlpha(178), // ✅ was 18 (almost invisible)
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: subtitleFontSize * 0.9,
                                color: CustomColors.secondaryWidgetTextColor(
                                  context,
                                  widget.ref,
                                ).withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: iconSize * 0.8,
                        color: CustomColors.secondaryWidgetTextColor(
                          context,
                          widget.ref,
                        ).withAlpha(128),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Location Search Button Widget (replaces your original InkWell)
class LocationSearchButton extends ConsumerWidget {
  final LocationData? selectedLocation;
  final Function(LocationData?) onLocationSelected;
  final double? iconSize;
  final EdgeInsets? padding;

  const LocationSearchButton({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showLocationSearch(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: padding,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedLocation01,
          size: (iconSize ?? 24) * 1.2,
          color: CustomColors.secondaryWidgetTextColor(context, ref).withAlpha(178),
        ),
      ),
    );
  }

  void _showLocationSearch(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<LocationData>(
      context: context,
      builder: (context) => LocationSearchDialog(
        ref: ref,
        initialValue: selectedLocation?.displayName ?? '',
      ),
    );

    if (result != null) {
      onLocationSelected(result);
    }
  }
}

// Usage Example:
class LocationSearchTile extends ConsumerWidget {
  final LocationData? selectedLocation;
  final Function(LocationData?) onLocationSelected;
  final double iconSize;

  const LocationSearchTile({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selectedLocation != null
              ? Colors.blue.withAlpha(26)
              : Theme.of(context).primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedLocation01,
          size: iconSize * 0.5,
          color: CustomColors.secondaryWidgetTextColor(context, ref).withOpacity(0.6),
        ),
      ),
      title: Text(
        selectedLocation?.displayName ?? 'check_in'.tr,
        style: TextStyle(
          color: CustomColors.secondaryWidgetTextColor(context, ref)
              .withOpacity(selectedLocation != null ? 1.0 : 0.85),
        ),
      ),
      onTap: () => _showLocationSearch(context, ref),
    );
  }

  void _showLocationSearch(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<LocationData>(
      context: context,
      builder: (context) => LocationSearchDialog(
        ref: ref,
        initialValue: selectedLocation?.displayName ?? '',
      ),
    );

    if (result != null) {
      onLocationSelected(result);
    }
  }
}