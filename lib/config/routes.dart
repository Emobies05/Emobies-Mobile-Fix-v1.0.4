import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/services/auth_service.dart';
import '../core/services/supabase_service.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/biometric_setup_screen.dart';
import '../features/customer/home_screen.dart';
import '../features/customer/complaint_register_screen.dart';
import '../features/customer/my_complaints_screen.dart';
import '../features/customer/emocoin_screen.dart';
import '../features/customer/crypto_wallet_screen.dart';
import '../features/customer/ai_chat_screen.dart';
import '../features/customer/complaint_detail_screen.dart';
import '../features/supervisor/supervisor_dashboard.dart';
import '../features/supervisor/complaint_assign_screen.dart';
import '../features/supervisor/delivery_tracking_screen.dart';
import '../features/supervisor/chat_screen.dart';
import '../features/supervisor/staff_management_screen.dart';
import '../features/supervisor/image_viewer_screen.dart';
import '../features/delivery/delivery_dashboard.dart';
import '../features/delivery/complaint_detail_screen.dart' as delivery;
import '../features/delivery/image_upload_screen.dart';
import '../features/delivery/location_confirm_screen.dart';
import '../features/service_center/sc_dashboard.dart';
import '../features/service_center/complaint_manage_screen.dart';
import '../features/service_center/payment_screen.dart';
import '../features/service_center/repair_complete_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/all_complaints_screen.dart';
import '../features/admin/analytics_screen.dart';
import '../features/admin/staff_add_screen.dart';
import '../features/admin/admin_complaint_detail_screen.dart';
import 'constants.dart';

class AppRoutes {
  AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String signup = '/signup';
  static const String biometricSetup = '/biometric-setup';

  // Customer
  static const String customerHome = '/customer/home';
  static const String customerComplaints = '/customer/complaints';
  static const String customerComplaintDetail = '/customer/complaint-detail';
  static const String registerComplaint = '/customer/register-complaint';
  static const String emoCoins = '/customer/emocoins';
  static const String cryptoWallet = '/customer/crypto-wallet';
  static const String aiChat = '/customer/ai-chat';

  // Supervisor
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String supervisorAssign = '/supervisor/assign';
  static const String supervisorTracking = '/supervisor/tracking';
  static const String supervisorChat = '/supervisor/chat';
  static const String supervisorStaff = '/supervisor/staff';
  static const String supervisorImages = '/supervisor/images';

  // Delivery Boy
  static const String deliveryDashboard = '/delivery/dashboard';
  static const String deliveryComplaint = '/delivery/complaint';
  static const String deliveryUpload = '/delivery/upload';
  static const String deliveryLocation = '/delivery/location';

  // Service Center
  static const String scDashboard = '/sc/dashboard';
  static const String scComplaint = '/sc/complaint';
  static const String scPayment = '/sc/payment';
  static const String scRepairComplete = '/sc/repair-complete';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminComplaints = '/admin/complaints';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminStaffAdd = '/admin/staff-add';
  static const String adminComplaintDetail = '/admin/complaint-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:
        return _fadeRoute(const LoginScreen());
      case signup:
        return _fadeRoute(const SignupScreen());
      case biometricSetup:
        return _fadeRoute(const BiometricSetupScreen());

      // Customer
      case customerHome:
        return _fadeRoute(const CustomerHomeScreen());
      case customerComplaints:
        return _fadeRoute(const MyComplaintsScreen());
      case registerComplaint:
        return _slideUpRoute(const ComplaintRegisterScreen());
      case emoCoins:
        return _fadeRoute(const EmocoinScreen());
      case cryptoWallet:
        return _fadeRoute(const CryptoWalletScreen());
      case aiChat:
        return _slideUpRoute(const AiChatScreen());
      case customerComplaintDetail:
        final id = settings.arguments as String?;
        return _slideRoute(CustomerComplaintDetailScreen(complaintId: id ?? ''));

      // Supervisor
      case supervisorDashboard:
        return _fadeRoute(const SupervisorDashboard());
      case supervisorAssign:
        final id = settings.arguments as String?;
        return _slideRoute(ComplaintAssignScreen(complaintId: id));
      case supervisorTracking:
        final id = settings.arguments as String?;
        return _slideRoute(DeliveryTrackingScreen(deliveryBoyId: id));
      case supervisorChat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(ChatScreen(complaintId: args?['chatId'] ?? ''));

      // Delivery
      case deliveryDashboard:
        return _fadeRoute(const DeliveryDashboard());
      case deliveryComplaint:
        final id = settings.arguments as String?;
        return _slideRoute(delivery.ComplaintDetailScreen(complaintId: id ?? ''));
      case deliveryUpload:
        final id = settings.arguments as String?;
        return _slideUpRoute(ImageUploadScreen(complaintId: id ?? ''));
      case deliveryLocation:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(LocationConfirmScreen(
          type: args?['type'] ?? 'customer',
          complaintId: args?['complaintId'] ?? '',
        ));

      // Service Center
      case scDashboard:
        return _fadeRoute(const SCDashboard());
      case scComplaint:
        final id = settings.arguments as String?;
        return _slideRoute(ComplaintManageScreen(complaintId: id ?? ''));
      case scPayment:
        final id = settings.arguments as String?;
        return _slideRoute(PaymentScreen(complaintId: id ?? ''));
      case scRepairComplete:
        final id = settings.arguments as String?;
        return _slideUpRoute(RepairCompleteScreen(complaintId: id ?? ''));

      // Admin
      case adminDashboard:
        return _fadeRoute(const AdminDashboard());
      case adminComplaints:
        return _fadeRoute(const AllComplaintsScreen());
      case adminAnalytics:
        return _fadeRoute(const AnalyticsScreen());
      case adminStaffAdd:
        return _slideUpRoute(const StaffAddScreen());
      case adminComplaintDetail:
        final id = settings.arguments as String?;
        return _slideRoute(AdminComplaintDetailScreen(complaintId: id ?? ''));

      default:
        return _fadeRoute(const LoginScreen());
    }
  }

  static String getInitialRoute(String? role) {
    switch (role) {
      case 'customer':
        return customerHome;
      case 'supervisor':
        return supervisorDashboard;
      case 'delivery_boy':
        return deliveryDashboard;
      case 'service_center':
        return scDashboard;
      case 'super_admin':
        return adminDashboard;
      default:
        return login;
    }
  }

  static PageRoute _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRoute _slideRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }

  static PageRoute _slideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, secAnim, child) {
        final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: anim.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  const RoleGuard({super.key, required this.child, required this.allowedRoles});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: context.read<AuthService>().getRole(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF07080B),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFFF5500))),
          );
        }
        if (!allowedRoles.contains(snap.data)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          });
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}