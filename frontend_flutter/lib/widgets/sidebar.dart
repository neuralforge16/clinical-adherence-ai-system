import 'package:flutter/material.dart';
import '../pages/login_page.dart';

class SidebarItemData {
  final IconData icon;
  final String title;

  const SidebarItemData({required this.icon, required this.title});
}

class Sidebar extends StatelessWidget {
  final List<SidebarItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const Sidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
  });

  

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1E5AA8),
      child: Column(
        children: [
          /// 🔥 TITLE
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            width: double.infinity,
            child: const Text(
              "Medication\nAdherence System",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          /// 🔥 NAV ITEMS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Material(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: Icon(item.icon, color: Colors.white, size: 22),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      onTap: () => onItemTap(index),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white24),

          /// 🔥 BOTTOM ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                /// BACK BUTTON
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.arrow_back, color: Colors.white),
                  title: const Text(
                    "Back",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context),
                ),

                /// LOGOUT
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text(
                          "Are you sure you want to log out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
