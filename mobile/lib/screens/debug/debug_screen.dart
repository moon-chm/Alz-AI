import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/websocket_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/debug_log_provider.dart';
import '../../providers/core_providers.dart';
import '../../services/websocket_service.dart'; 
import '../../core/config/theme.dart';
import '../../providers/uptime_provider.dart';
import '../../services/api_service.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  final ScrollController _scrollController = ScrollController();
  int _sosQueueSize = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSOSQueueSize());
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchSOSQueueSize());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSOSQueueSize() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final size = await apiService.getSOSQueueSize();
      if (mounted) {
        setState(() => _sosQueueSize = size);
      }
    } catch (_) {
      // Silently fail for debug stats
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(debugLogProvider);
    final wsConnected = ref.watch(webSocketControllerProvider);
    final wsService = ref.watch(webSocketServiceProvider);
    final locationAsync = ref.watch(locationPositionStreamProvider);
    final isTracking = ref.watch(locationControllerProvider);
    final uptime = ref.watch(uptimeProvider).value ?? '00:00:00';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineering Observability'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: () => ref.read(debugLogProvider.notifier).clearLogs(),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSystemStats(uptime, null, _sosQueueSize), 
          _buildStatusPanel(wsConnected, locationAsync, isTracking),
          _buildControlPanel(wsConnected, isTracking),
          const Divider(height: 1),
          _buildSectionHeader('Live Event Feed (Last 50)'),
          Expanded(
            child: _buildEventLog(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStats(String uptime, DateTime? lastConnected, int sosQueue) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('App Uptime', uptime),
              _buildMetric('SOS Queue', '$sosQueue pending', color: sosQueue > 0 ? AppColors.accent : null),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.history, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                lastConnected != null 
                  ? 'Last Reconnect: ${_formatTime(lastConnected)}' 
                  : 'Last Reconnect: Never',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildStatusPanel(bool wsConnected, AsyncValue<Position> locationAsync, bool isTracking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIndicator('WebSocket', wsConnected ? 'Connected' : 'Disconnected', wsConnected ? AppColors.green : AppColors.red),
              const SizedBox(width: 24),
              _buildStatusIndicator('GPS', isTracking ? 'Active' : 'Inactive', isTracking ? AppColors.primary : Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          locationAsync.when(
            data: (pos) => _buildInfoRow(Icons.location_on_outlined, 
              '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)} (±${pos.accuracy.toStringAsFixed(1)}m)'),
            loading: () => _buildInfoRow(Icons.location_on_outlined, 'Fetching coordinates...'),
            error: (err, _) => _buildInfoRow(Icons.error_outline, 'Location Error: $err', color: AppColors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: color ?? Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool wsConnected, bool isTracking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(wsConnected ? Icons.link_off : Icons.link),
              label: Text(wsConnected ? 'Disconnect' : 'Connect'),
              onPressed: () => wsConnected 
                ? ref.read(webSocketControllerProvider.notifier).forceDisconnect()
                : ref.read(webSocketControllerProvider.notifier).reconnect(),
              style: OutlinedButton.styleFrom(
                foregroundColor: wsConnected ? AppColors.accent : AppColors.green,
                side: BorderSide(color: wsConnected ? AppColors.accent : AppColors.green),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(isTracking ? Icons.gps_off : Icons.gps_fixed),
              label: Text(isTracking ? 'Stop GPS' : 'Start GPS'),
              onPressed: () => isTracking 
                ? ref.read(locationControllerProvider.notifier).stopTracking()
                : ref.read(locationControllerProvider.notifier).startTracking(),
              style: OutlinedButton.styleFrom(
                foregroundColor: isTracking ? AppColors.red : AppColors.primary,
                side: BorderSide(color: isTracking ? AppColors.red : AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog(List<DebugLogEntry> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No events recorded yet.', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final color = _getLogColor(log.severity);

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: ExpansionTile(
            dense: true,
            leading: _buildSeverityIcon(log.severity),
            title: Text(log.title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              '${_formatTime(log.timestamp)} - ${log.message}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              if (log.data != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _formatMap(log.data!),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSeverityIcon(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.error:
        return const Icon(Icons.error_outline, color: AppColors.red, size: 20);
      case LogSeverity.warning:
        return const Icon(Icons.warning_amber, color: AppColors.accent, size: 20);
      case LogSeverity.info:
        return const Icon(Icons.info_outline, color: AppColors.primary, size: 20);
    }
  }

  Color _getLogColor(LogSeverity severity) {
    switch (severity) {
      case LogSeverity.error: return AppColors.red;
      case LogSeverity.warning: return AppColors.accent;
      case LogSeverity.info: return AppColors.primary;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatMap(Map<String, dynamic> map) {
    return JsonEncoder.withIndent('  ').convert(map);
  }
}
