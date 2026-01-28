import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminRepliesScreen extends StatefulWidget {
  const AdminRepliesScreen({super.key});

  @override
  State<AdminRepliesScreen> createState() => _AdminRepliesScreenState();
}

class _AdminRepliesScreenState extends State<AdminRepliesScreen> {
  final _adminService = AdminService();
  bool _loading = true;
  List<Map<String, dynamic>> _replies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _adminService.getAdminReplies();
      if (!mounted) return;
      setState(() {
        _replies = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الردود: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int get _unreadCount =>
      _replies.where((r) => r['is_read_by_admin'] != true).length;

  String _doctorName(Map<String, dynamic> r) {
    final doctor = r['doctors'];
    if (doctor is Map<String, dynamic>) {
      return (doctor['full_name'] ?? 'طبيب').toString();
    }
    return 'طبيب';
  }

  String _messageTitle(Map<String, dynamic> r) {
    final msg = r['admin_messages'];
    if (msg is Map<String, dynamic>) {
      return (msg['title'] ?? 'رسالة').toString();
    }
    return 'رسالة';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openReply(Map<String, dynamic> r) async {
    final replyId = (r['id'] ?? '').toString();
    final isRead = r['is_read_by_admin'] == true;

    if (!isRead && replyId.isNotEmpty) {
      try {
        await _adminService.markReplyAsReadByAdmin(replyId);
        await _load();
      } catch (_) {
        // ignore; still show dialog
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('رد من ${_doctorName(r)}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'على: ${_messageTitle(r)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  (r['reply'] ?? '').toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'التاريخ: ${_formatDate(r['created_at']?.toString())}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Row(
            children: [
              const Text('ردود الأطباء'),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _replies.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد ردود',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _replies.length,
                      itemBuilder: (context, index) {
                        final r = _replies[index];
                        final isRead = r['is_read_by_admin'] == true;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isRead ? 1 : 3,
                          color: isRead ? Colors.white : Colors.blue[50],
                          child: ListTile(
                            onTap: () => _openReply(r),
                            title: Text(
                              _doctorName(r),
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('على: ${_messageTitle(r)}'),
                                const SizedBox(height: 4),
                                Text(
                                  (r['reply'] ?? '').toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(r['created_at']?.toString()),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: isRead
                                ? const Icon(Icons.mark_email_read, color: Colors.grey)
                                : const Icon(Icons.mark_email_unread, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
