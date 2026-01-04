import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/slide_page_route.dart';
import 'company_details_screen.dart';

enum CompanyMode { contractee, company }

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final ApiService _apiService = ApiService();
  CompanyMode _currentMode = CompanyMode.contractee;
  List<Company> _companies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final companies = await _apiService.getCompanies();
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _switchMode(CompanyMode mode) {
    if (_currentMode == mode) return;
    setState(() => _currentMode = mode);
  }

  List<Company> get _filteredCompanies {
    if (_currentMode == CompanyMode.contractee) {
      return _companies.where((c) => c.isContractor).toList();
    } else {
      return _companies.where((c) => !c.isContractor).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
      ),
      body: Column(
        children: [
          // Mode toggle tabs
          _buildModeToggle(),

          // Content with animated slide transition
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                // Slide animation based on direction
                final isContractee = (child.key as ValueKey).value == CompanyMode.contractee;
                final slideAnimation = Tween<Offset>(
                  begin: Offset(isContractee ? -1.0 : 1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ));

                return SlideTransition(
                  position: slideAnimation,
                  child: child,
                );
              },
              child: _buildContent(key: ValueKey(_currentMode)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Vertragsunternehmen',
              icon: Icons.handshake_outlined,
              mode: CompanyMode.contractee,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton(
              label: 'Unternehmensprofile',
              icon: Icons.business_outlined,
              mode: CompanyMode.company,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required CompanyMode mode,
  }) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientMiddle,
                    AppColors.gradientEnd,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isSelected ? null : AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({Key? key}) {
    if (_isLoading) {
      return const LoadingIndicator(key: ValueKey('loading'));
    }

    if (_errorMessage != null) {
      return _buildError(key: key);
    }

    final companies = _filteredCompanies;

    if (companies.isEmpty) {
      return EmptyState(
        key: key,
        icon: _currentMode == CompanyMode.contractee
            ? Icons.handshake_outlined
            : Icons.business_outlined,
        title: _currentMode == CompanyMode.contractee
            ? 'Keine Vertragsunternehmen'
            : 'Keine Unternehmensprofile',
        message: _currentMode == CompanyMode.contractee
            ? 'Sie haben noch keine Vertragsunternehmen hinzugefügt.'
            : 'Es sind noch keine Unternehmensprofile verfügbar.',
      );
    }

    return RefreshIndicator(
      key: key,
      onRefresh: _loadCompanies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          return _buildCompanyCard(companies[index]);
        },
      ),
    );
  }

  Widget _buildError({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            'Fehler beim Laden',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unbekannter Fehler',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedGradientButton(
            label: 'Erneut versuchen',
            icon: Icons.refresh,
            onPressed: _loadCompanies,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Company company) {
    return GestureDetector(
      onTap: () => _navigateToDetails(company),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Company logo/avatar
              Avatar(
                imageUrl: company.logoUrl,
                initials: company.initials,
                size: AvatarSize.medium,
              ),
              const SizedBox(width: 16),
              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (company.isContractor)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.businessBadge.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.businessBadge,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vertrag',
                                  style: TextStyle(
                                    color: AppColors.businessBadge,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (company.description != null &&
                        company.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        company.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Stats row
                    Row(
                      children: [
                        _buildMiniStat(
                          Icons.people_outline,
                          '${company.followerCount}',
                          AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildMiniStat(
                          Icons.contact_phone_outlined,
                          '${company.allContacts.length}',
                          AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  void _navigateToDetails(Company company) {
    Navigator.of(context).push(
      SlidePageRoute(
        page: CompanyDetailsScreen(companyId: company.id),
        direction: SlideDirection.right,
      ),
    );
  }
}
