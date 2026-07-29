import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/ui/responsive/screens/login_screen.dart';

final appRouter = GoRouter(
  // TODO: Thay thế route /login thành /splash, để kiểm tra đã đăng nhập hay chưa mà route vào login hay home
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  ],
);
