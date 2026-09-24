import 'package:flutter/material.dart';

import '../../core/theme/appColors.dart';
import '../../core/widgets/appBar.dart';
import '../../models/agentDashboardModel.dart';
import '../../services/agentDashboardService.dart';
import '../../services/agentLocationService.dart';

class AgentDashboard extends StatefulWidget {
  final VoidCallback onLogout;

  const AgentDashboard({super.key, required this.onLogout});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  AgentDashboardModel? dashboard;

  bool isLoading = true;
  bool isRefreshing = false;
  bool isUpdatingLocation = false;

  String? errorMessage;
  String? locationMessage;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      locationMessage = null;
    });

    try {
      await _updateLocation();

      await _loadDashboard();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = _cleanError(e);
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDashboard() async {
    final result = await AgentDashboardService.getDashboard();

    if (!mounted) {
      return;
    }

    setState(() {
      dashboard = result;
    });
  }

  Future<void> _updateLocation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isUpdatingLocation = true;
      locationMessage = null;
    });

    try {
      await AgentLocationService.updateCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        locationMessage = 'Location updated successfully.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        locationMessage = _cleanError(e);
      });

      // Location failure should not prevent
      // the dashboard from loading.
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isUpdatingLocation = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    if (isRefreshing) {
      return;
    }

    setState(() {
      isRefreshing = true;
      errorMessage = null;
      locationMessage = null;
    });

    try {
      await _updateLocation();
      await _loadDashboard();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = _cleanError(e);
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isRefreshing = false;
      });
    }
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AgentAppBar(title: 'Dashboard', onLogout: widget.onLogout),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && dashboard == null) {
      return _buildErrorState();
    }

    if (dashboard == null) {
      return _buildErrorState(message: 'Unable to load dashboard.');
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),

          const SizedBox(height: 16),

          _buildLocationCard(),

          const SizedBox(height: 20),

          const Text(
            'Loan Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          _buildStatsGrid(),

          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildMessageCard(message: errorMessage!, isError: true),
          ],

          const SizedBox(height: 20),

          Text(
            dashboard!.message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            dashboard!.agentName.isEmpty ? 'Agent' : dashboard!.agentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agent ID: ${dashboard!.agentId}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agent Location',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUpdatingLocation
                      ? 'Updating your location...'
                      : locationMessage ?? 'Location is ready.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUpdatingLocation)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: 'Update location',
              onPressed: _updateLocation,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _buildStatCard(
          title: 'Accepted',
          value: dashboard!.totalAcceptedLoans.toString(),
          icon: Icons.assignment_turned_in_outlined,
        ),
        _buildStatCard(
          title: 'Under Review',
          value: dashboard!.underReviewLoans.toString(),
          icon: Icons.pending_actions,
        ),
        _buildStatCard(
          title: 'Approved',
          value: dashboard!.approvedLoans.toString(),
          icon: Icons.check_circle_outline,
        ),
        _buildStatCard(
          title: 'Rejected',
          value: dashboard!.rejectedLoans.toString(),
          icon: Icons.cancel_outlined,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({required String message, required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withOpacity(0.08)
            : AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({String message = 'Unable to load dashboard.'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
