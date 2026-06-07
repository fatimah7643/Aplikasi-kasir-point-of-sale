import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final void Function(String userId, bool isActive) onToggleActive;
  final void Function(String userId) onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';
    final roleColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);
    final roleLabel = isAdmin ? 'Admin' : 'Kasir';
    final roleIcon = isAdmin ? Icons.admin_panel_settings_rounded : Icons.point_of_sale_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isActive
              ? const Color(0xFFE5E7EB)
              : const Color(0xFFFECACA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: user.isActive
                    ? roleColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                roleIcon,
                color: user.isActive ? roleColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: user.isActive ? Colors.black87 : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!user.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Nonaktif',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 11, color: roleColor),
                        const SizedBox(width: 4),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'toggle') {
                  onToggleActive(user.id, !user.isActive);
                } else if (value == 'delete') {
                  onDelete(user.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: user.isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}