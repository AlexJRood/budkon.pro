import 'dart:convert';
import 'package:profile/profile_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/user/user/user_model.dart';
import 'package:profile/screens/company/company_screen.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/lottie.dart';
import 'dart:developer';

class PublicCompanyFetcher extends ConsumerStatefulWidget {
  final String companyId;
  
  const PublicCompanyFetcher({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<PublicCompanyFetcher> createState() => _PublicCompanyFetcherState();
}

class _PublicCompanyFetcherState extends ConsumerState<PublicCompanyFetcher> {
  CompanyModel? companyData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchCompany();
  }

  Future<void> _fetchCompany() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await ApiServices.get(
        ref: ref,
        ProfileUrls.publicCompany(widget.companyId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decodedBody = utf8.decode(response.data);
        final companyJson = json.decode(decodedBody) as Map<String, dynamic>;
        
        log('Public Company Fetched - Company ID: ${widget.companyId}');
        log('Company Data: ${companyJson.toString()}');

        final company = CompanyModel.fromJson(companyJson);
        
        setState(() {
          companyData = company;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load company data';
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching public company: $e');
      }
      setState(() {
        error = 'Error loading company: $e';
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

    if (companyData == null) {
      return const Scaffold(
        body: Center(
          child: Text('No company data available'),
        ),
      );
    }

    // Pass the fetched company data to the company screen
    return CompanyScreen(
      companyData: companyData,
      isCurrentUserCompany: false, // This is a public company view
    );
  }
}
