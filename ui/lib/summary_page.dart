import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'api_flask.dart';
import 'flow_meter_data_model.dart';
import 'package:intl/intl.dart';
import 'settings_page.dart';
import 'language_support.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => SummaryPageState();
}

class SummaryPageState extends State<SummaryPage> {
  FlowMeterData? retrievedData;
  bool isLoading = true;
  int navIndex = 0;
  Timer? _refreshTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadData();
    });
  }

  void _loadData() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final api = FlowApi();
      final liveData = await api.fetchLive();
      if (!mounted) return;
      setState(() {
        retrievedData = liveData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LanguageLocalizations.of(context);
    // check if loading
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.8, 1),
              colors: <Color>[Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              tileMode: TileMode.mirror,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Check if data is null
    if (retrievedData == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.8, 1),
              colors: <Color>[Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              tileMode: TileMode.mirror,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  localizations.noDataAvailable,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                    });
                    _loadData();
                  },
                  child: Text(localizations.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> pages = [_buildSummaryContent(), const SettingsPage()];

    return Scaffold(
      body: IndexedStack(index: navIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                navItem(
                  icon: Icons.home_rounded,
                  label: localizations.home,
                  index: 0,
                ),
                navItem(
                  icon: Icons.settings_rounded,
                  label: localizations.settings,
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent() {
    final localizations = LanguageLocalizations.of(context);
    final data = retrievedData;
    final updatedTime = DateFormat('h:mm a').format(data!.time).toUpperCase();
    String formatDate(BuildContext context, DateTime date) {
      final locale = Localizations.localeOf(context).toString();
      return DateFormat('MMMM d', locale).format(date);
    }

    final updatedDate = formatDate(context, data.time);

    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.8, 1),
          colors: <Color>[Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
          tileMode: TileMode.mirror,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Welcome heading
                Text(
                  localizations.welcomeBack,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  localizations.flowmeterSummary,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  '${localizations.lastUpdated} $updatedDate ${localizations.at} $updatedTime ${localizations.est}',
                  style: const TextStyle(fontSize: 20, color: Colors.black),
                ),

                const SizedBox(height: 32),

                // Volume Card
                summaryCard(
                  title: localizations.volume,
                  value: '${data.totalVolume} ${localizations.mlWaterUsed}',
                  trailing: Image.asset(
                    'assets/waterDroplets.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                // Flow Rate Card
                summaryCard(
                  title: localizations.flowRate,
                  value: '${data.flowRate} ${localizations.mlPerMin}',
                ),

                const SizedBox(height: 16),

                // Average Flow Rate Card
                summaryCard(
                  title: localizations.averageFlowRate,
                  value: '${data.avgFlowRate} ${localizations.mlPerMin}',
                ),

                const SizedBox(height: 32),
                // Go to Dashboard Button
                Container(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      shadowColor: Colors.black,
                    ),
                    child: Text(
                      localizations.goToDashboard,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = navIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          navIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF9CA3AF),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryCard({
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
          tileMode: TileMode.mirror,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFBFDBFE),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, color: Color(0xFF4B5563)),
              ),
            ],
          ),

          // Right: optional trailing widget
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }
}