import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/infographics_card.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';

class InfographicsPage extends StatefulWidget {
  const InfographicsPage({super.key});

  @override
  State<InfographicsPage> createState() => _InfographicsPageState();
}

class _InfographicsPageState extends State<InfographicsPage> {
  List<Map<String, dynamic>> _infographics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInfographics();
  }

  Future<void> _loadInfographics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final infographics = await WHOInfographicsService.getDengueInfographics();
      setState(() {
        _infographics = infographics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading infographics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(Responsive.padding(context, 20)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: Responsive.icon(context, 24),
                    ),
                  ),
                  SizedBox(width: Responsive.padding(context, 12)),
                  Text(
                    'Dengue Infographics',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                      fontSize: Responsive.font(context, 24),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _infographics.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.health_and_safety,
                                size: Responsive.icon(context, 64),
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: Responsive.vertical(context, 16)),
                              Text(
                                'No infographics available',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadInfographics,
                          child: ListView.builder(
                            padding: EdgeInsets.all(Responsive.padding(context, 16)),
                            itemCount: _infographics.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
                                child: InfographicsCard(
                                  infographic: _infographics[index],
                                  onTap: () {
                                    // Custom tap action if needed
                                    print('Tapped infographic: ${_infographics[index]['title']}');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
