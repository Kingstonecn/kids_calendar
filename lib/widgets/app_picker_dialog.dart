import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import '../utils/constants.dart';

/// 已安装App搜索选择弹窗
/// 返回 (packageName, appName) 或 null（用户取消/清除）
class AppPickerDialog extends StatefulWidget {
  final String? currentPackageName;

  const AppPickerDialog({super.key, this.currentPackageName});

  /// 便捷调用: 弹出底部弹窗, 返回 (packageName, appName) 或 null
  static Future<(String, String)?> pick(
    BuildContext context, {
    String? currentPackageName,
  }) {
    return showModalBottomSheet<(String, String)?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AppPickerDialog(currentPackageName: currentPackageName),
    );
  }

  @override
  State<AppPickerDialog> createState() => _AppPickerDialogState();
}

class _AppPickerDialogState extends State<AppPickerDialog> {
  final _searchController = TextEditingController();
  List<ApplicationWithIcon> _allApps = [];
  List<ApplicationWithIcon> _filteredApps = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    try {
      final result = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );
      final apps = result.whereType<ApplicationWithIcon>().toList();
      apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      if (mounted) {
        setState(() {
          _allApps = apps;
          _filteredApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '无法获取应用列表: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filteredApps = _allApps.where((app) {
        return app.appName.toLowerCase().contains(q) ||
            app.packageName.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // 标题 + 清除按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择关联应用',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (widget.currentPackageName != null)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('清除'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '搜索应用...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _filter,
            ),
          ),
          const SizedBox(height: 8),
          // 列表
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_filteredApps.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty ? '未找到匹配的应用' : '未安装任何应用',
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
      );
    }
    return ListView.builder(
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        final isSelected = app.packageName == widget.currentPackageName;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              app.icon,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.android, color: Colors.grey),
              ),
            ),
          ),
          title: Text(app.appName),
          subtitle: Text(app.packageName,
              style: const TextStyle(fontSize: 12)),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppConstants.primaryColor)
              : null,
          onTap: () => Navigator.pop(
            context,
            (app.packageName, app.appName),
          ),
        );
      },
    );
  }
}
