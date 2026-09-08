import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/auth/models/user_model.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.go(RouterPath.login);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<UserModel?>(
              future: userStorageService.getUser(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    children: [
                    AppNetworkImage(
                        url: user?.avatarUrl,
                        width: 48,
                        height: 48,
                        isCircle: true,
                        errorWidget: CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    Text(user?.email ?? ""),
                    Text(user?.fullname ?? ""),
                    Text(user?.avatarUrl ?? ""),
                    Text(user?.role.toString() ?? ""),
                    Text(user?.registrationStatus.toString() ?? ""),
                    Text(user?.phone ?? ""),
                    Text(user?.dateOfBirth ?? ""),
                    Text(user?.gender ?? ""),
                    ]
                  )
                );
              }
            ),
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome to SmartSpace Admin',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            const Text('Authentication: Logged in'),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                await authService.logout();
                if (context.mounted) {
                  context.go(RouterPath.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
