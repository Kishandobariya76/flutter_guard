import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({super.key});

  String _current(FlutterGuardConfig config, ConfigOption option) {
    switch (option.qualified) {
      case 'FlutterGuardConfig.baseUrl':
        return '${config.baseUrl}';
      case 'NetworkConfig.connectTimeout':
        return '${config.network.connectTimeout}';
      case 'NetworkConfig.receiveTimeout':
        return '${config.network.receiveTimeout}';
      case 'NetworkConfig.sendTimeout':
        return '${config.network.sendTimeout}';
      case 'NetworkConfig.followRedirects':
        return '${config.network.followRedirects}';
      case 'NetworkConfig.maxRedirects':
        return '${config.network.maxRedirects}';
      case 'NetworkConfig.enableDefaultDeduplication':
        return '${config.network.enableDefaultDeduplication}';
      case 'NetworkConfig.userAgent':
        return config.network.userAgent;
      case 'RetryConfig.maxAttempts':
        return '${config.network.retry.maxAttempts}';
      case 'RetryConfig.initialDelay':
        return '${config.network.retry.initialDelay}';
      case 'RetryConfig.maxDelay':
        return '${config.network.retry.maxDelay}';
      case 'RetryConfig.exponentialBackoff':
        return '${config.network.retry.exponentialBackoff}';
      case 'RetryConfig.jitter':
        return '${config.network.retry.jitter}';
      case 'RetryConfig.retryNonIdempotent':
        return '${config.network.retry.retryNonIdempotent}';
      case 'CacheConfig.enabled':
        return '${config.cache.enabled}';
      case 'CacheConfig.defaultTtl':
        return '${config.cache.defaultTtl}';
      case 'CacheConfig.defaultPolicy':
        return config.cache.defaultPolicy.name;
      case 'CacheConfig.maxMemoryEntries':
        return '${config.cache.maxMemoryEntries}';
      case 'CacheConfig.persistent':
        return '${config.cache.persistent}';
      case 'OfflineConfig.enabled':
        return '${config.offline.enabled}';
      case 'OfflineConfig.persistentQueue':
        return '${config.offline.persistentQueue}';
      case 'OfflineConfig.autoSync':
        return '${config.offline.autoSync}';
      case 'DiagnosticsConfig.enabled':
        return '${config.diagnostics.enabled}';
      case 'DiagnosticsConfig.logLevel':
        return config.diagnostics.logLevel.name;
      case 'DiagnosticsConfig.redactSensitiveFields':
        return '${config.diagnostics.redactSensitiveFields}';
      case 'InspectorConfig.enabled':
        return '${config.inspector.enabled}';
      case 'InspectorConfig.allowInRelease':
        return '${config.inspector.allowInRelease}';
      case 'EnvironmentConfig.environment':
        return config.environment.environment.name;
      case 'EnvironmentConfig.applyPresets':
        return '${config.environment.applyPresets}';
      default:
        return option.defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = FlutterGuardScope.of(context).config;
    final owners = ConfigCatalog.options.map((item) => item.owner).toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Playground')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final owner in owners) ...[
            Text(owner, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final option in ConfigCatalog.forOwner(owner))
              Card(
                child: ListTile(
                  title: Text(option.name),
                  subtitle: Text(
                    'Type: ${option.type}\n'
                    'Current: ${_current(config, option)}\n'
                    'Default: ${option.defaultValue}\n'
                    '${option.description}',
                  ),
                  isThreeLine: true,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
