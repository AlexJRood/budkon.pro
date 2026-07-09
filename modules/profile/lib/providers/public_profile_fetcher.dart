import 'dart:convert';
import 'package:profile/profile_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/user/user/user_model.dart';
import 'package:profile/screens/user_profile_default_screen.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/lottie.dart';
import 'dart:developer';

class PublicProfileFetcher extends ConsumerStatefulWidget {
  final String userId;
  
  const PublicProfileFetcher({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PublicProfileFetcher> createState() => _PublicProfileFetcherState();
}

class _PublicProfileFetcherState extends ConsumerState<PublicProfileFetcher> {
  UserModel? profileData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await ApiServices.get(
        ref: ref,
        ProfileUrls.publicProfile(widget.userId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final profileJson = json.decode(decodedBody) as Map<String, dynamic>;
        
        log('Public Profile Fetched - User ID: ${widget.userId}');
        log('Profile Data: ${profileJson.toString()}');

        final profile = UserModel.fromJson(profileJson);
        
        setState(() {
          profileData = profile;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load profile data';
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching public profile: $e');
      }
      setState(() {
        error = 'Error loading profile: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: AppLottie.loading(size: 450),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: AppLottie.error(size: 450),
        ),
      );
    }

    if (profileData == null) {
      return const Scaffold(
        body: Center(
          child: Text('No profile data available'),
        ),
      );
    }

    // Pass the fetched profile data to the profile screen
    return UserProfileDefaultScreen(
      profileData: profileData,
      isCurrentUser: false, // This is a public profile view
    );
  }
}
