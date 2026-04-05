import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LayoutScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int selectedIndex;
  final Function(int)? onIndexSelected;
  final List<SidebarItem> items;
  final Widget? floatingActionButton;

  const LayoutScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.selectedIndex,
    this.onIndexSelected,
    required this.items,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E293B),
              elevation: 0,
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [_buildUserActions(context)],
            )
          : null,
      drawer: !isDesktop
          ? Drawer(child: _buildSidebarContent(context))
          : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(4, 0))],
              ),
              child: _buildSidebarContent(context),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopBar(context),
                Expanded(
                  child: Container(color: const Color(0xFFF7F9FC), child: body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), offset: const Offset(0, 2), blurRadius: 8)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Spacer(),
          _buildUserActions(context),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      children: [
        // Brand Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.layers_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('EMS PRO', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              const Text('Employee Management System', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Nav items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 18),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected ? Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(4))) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      if (onIndexSelected != null) {
                        onIndexSelected!(index);
                        if (MediaQuery.of(context).size.width <= 900) Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        // Logout
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => context.read<AuthProvider>().logout(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUserActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
        ),
      ],
    );
  }
}

class SidebarItem {
  final String title;
  final IconData icon;
  const SidebarItem({required this.title, required this.icon});
}
