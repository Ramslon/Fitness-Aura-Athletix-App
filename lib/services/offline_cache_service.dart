import 'dart:async';

import 'package:fitness_aura_athletix/services/storage_service.dart';

/// Simple offline cache service that simulates downloading core content
/// and clearing cached files. In a real app this would persist files to
/// disk and manage expiry, size, and integrity checks.
class OfflineCacheService {
	OfflineCacheService._();
	static final OfflineCacheService _instance = OfflineCacheService._();
	factory OfflineCacheService() => _instance;

	Future<void> downloadCoreContent() async {
		// simulate download work
		await Future.delayed(const Duration(seconds: 2));
		await StorageService().saveBoolSetting('offline_downloaded', true);
	}

	Future<void> clearCache() async {
		// simulate clearing
		await Future.delayed(const Duration(milliseconds: 500));
		await StorageService().saveBoolSetting('offline_downloaded', false);
	}

	Future<bool> isDownloaded() async {
		return await StorageService().loadBoolSetting('offline_downloaded') ?? false;
	}
}

