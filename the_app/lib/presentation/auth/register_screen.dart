import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../home/main_navigation_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
	const RegisterScreen({super.key});

	@override
	State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
	final _formKey = GlobalKey<FormState>();

	final _emailController = TextEditingController();
	final _passwordController = TextEditingController();
	final _confirmPasswordController = TextEditingController();
	final _firstNameController = TextEditingController();
	final _lastNameController = TextEditingController();
	final _phoneController = TextEditingController();

	bool _isLoading = false;
	bool _isPasswordVisible = false;
	bool _isConfirmPasswordVisible = false;

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		_confirmPasswordController.dispose();
		_firstNameController.dispose();
		_lastNameController.dispose();
		_phoneController.dispose();
		super.dispose();
	}

	Future<bool> _isNetworkConnected() async {
		await Future.delayed(const Duration(milliseconds: 50));
		return true;
	}

	Future<void> _registerUser() async {
		if (!_formKey.currentState!.validate()) {
			Helpers.showSnackBar(context, 'الرجاء ملء جميع الحقول المطلوبة بشكل صحيح.');
			return;
		}

		setState(() => _isLoading = true);

		final isConnected = await _isNetworkConnected();
		if (!isConnected) {
			if (mounted) {
				Helpers.showSnackBar(context, 'فشل الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت.');
			}
			setState(() => _isLoading = false);
			return;
		}

		final emailPart = _emailController.text.trim().split('@').first;
		final username = emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

		final registrationData = {
			'username': username,
			'display_name': '${_firstNameController.text} ${_lastNameController.text}'.trim(),
			'email': _emailController.text.trim(),
			'password': _passwordController.text,
			'first_name': _firstNameController.text.trim(),
			'last_name': _lastNameController.text.trim(),
			'phone': _phoneController.text.trim(),
			'role': 'USER',
		};

		try {
			final authProvider = context.read<AuthProvider>();
			final success = await authProvider.register(registrationData);

			if (success && mounted) {
				Helpers.showSnackBar(context, 'تم التسجيل بنجاح! مرحباً بك في DZ Local');
				Navigator.of(context).pushAndRemoveUntil(
					MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
					(route) => false,
				);
			} else if (!success && mounted) {
				final errorMsg = authProvider.error ?? 'تعذر إكمال التسجيل، حاول مجدداً';
				Helpers.showSnackBar(context, errorMsg);
			}
		} catch (e) {
			debugPrint('❌ Registration Error: $e');
			if (mounted) {
				Helpers.showSnackBar(context, 'فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.');
			}
		}

		if (mounted) {
			setState(() => _isLoading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final size = MediaQuery.of(context).size;

		return Scaffold(
			body: Stack(
				children: [
					Container(
						height: size.height,
						decoration: BoxDecoration(
							gradient: LinearGradient(
								colors: [
									AppColors.primaryOrange.withOpacity(0.92),
									AppColors.primaryPurple.withOpacity(0.9),
								],
								begin: Alignment.topLeft,
								end: Alignment.bottomRight,
							),
						),
					),
					Positioned(top: -50, right: -60, child: _blurredCircle(170, Colors.white.withOpacity(0.1))),
					Positioned(bottom: -70, left: -40, child: _blurredCircle(200, Colors.white.withOpacity(0.08))),

					SafeArea(
						child: SingleChildScrollView(
							padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											Container(
												padding: const EdgeInsets.all(12),
												decoration: BoxDecoration(
													shape: BoxShape.circle,
													color: Colors.white.withOpacity(0.16),
													border: Border.all(color: Colors.white.withOpacity(0.16)),
												),
												child: const Icon(Icons.auto_awesome, color: Colors.white),
											),
											const SizedBox(width: 12),
											Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text('أنشئ حسابك', style: AppTextStyles.h1.copyWith(color: Colors.white)),
													Text('خصومات محلية + شحن سريع', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
												],
											),
										],
									).animate().fadeIn(duration: const Duration(milliseconds: 400)).move(begin: const Offset(0, -12)),

									const SizedBox(height: 22),

									GlassmorphicContainer(
										width: double.infinity,
										height: size.height * 0.82,
										borderRadius: 22,
										blur: 18,
										border: 1.2,
										alignment: Alignment.topCenter,
										linearGradient: LinearGradient(
											colors: [
												Colors.white.withOpacity(0.22),
												Colors.white.withOpacity(0.12),
											],
											begin: Alignment.topLeft,
											end: Alignment.bottomRight,
										),
										borderGradient: LinearGradient(
											colors: [
												Colors.white.withOpacity(0.36),
												Colors.white.withOpacity(0.20),
											],
											begin: Alignment.topLeft,
											end: Alignment.bottomRight,
										),
										child: Padding(
											padding: const EdgeInsets.all(22),
											child: Form(
												key: _formKey,
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.stretch,
													children: [
														Wrap(
															spacing: 10,
															runSpacing: 8,
															children: const [
																_FeatureChip(icon: Icons.bolt_outlined, label: 'تسجيل سريع'),
																_FeatureChip(icon: Icons.card_giftcard_outlined, label: 'عروض فورية'),
																_FeatureChip(icon: Icons.shield_outlined, label: 'حماية بياناتك'),
															],
														),

														const SizedBox(height: 20),

														_buildTextField(
															controller: _firstNameController,
															labelText: 'الاسم الأول',
															icon: Icons.person_outline,
															validator: (value) {
																if (value!.isEmpty) return 'الرجاء إدخال الاسم الأول';
																return null;
															},
														),
														const SizedBox(height: 14),

														_buildTextField(
															controller: _lastNameController,
															labelText: 'الاسم الأخير',
															icon: Icons.person,
															validator: (value) {
																if (value!.isEmpty) return 'الرجاء إدخال الاسم الأخير';
																return null;
															},
														),
														const SizedBox(height: 14),

														_buildTextField(
															controller: _emailController,
															labelText: 'البريد الإلكتروني',
															icon: Icons.email_outlined,
															keyboardType: TextInputType.emailAddress,
															validator: (value) {
																if (value!.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
																if (!value.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
																return null;
															},
														),
														const SizedBox(height: 14),

														_buildTextField(
															controller: _phoneController,
															labelText: 'رقم الهاتف',
															icon: Icons.phone_outlined,
															keyboardType: TextInputType.phone,
															validator: (value) {
																if (value!.isEmpty) return 'الرجاء إدخال رقم الهاتف';
																return null;
															},
														),
														const SizedBox(height: 14),

														_buildPasswordField(
															controller: _passwordController,
															labelText: 'كلمة المرور',
															isVisible: _isPasswordVisible,
															toggleVisibility: () {
																setState(() {
																	_isPasswordVisible = !_isPasswordVisible;
																});
															},
															validator: (value) {
																if (value!.isEmpty) return 'الرجاء إدخال كلمة المرور';
																if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
																return null;
															},
														),
														const SizedBox(height: 14),

														_buildPasswordField(
															controller: _confirmPasswordController,
															labelText: 'تأكيد كلمة المرور',
															isVisible: _isConfirmPasswordVisible,
															toggleVisibility: () {
																setState(() {
																	_isConfirmPasswordVisible = !_isConfirmPasswordVisible;
																});
															},
															validator: (value) {
																if (value!.isEmpty) return 'الرجاء تأكيد كلمة المرور';
																if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
																return null;
															},
														),

														const SizedBox(height: 18),

														SizedBox(
															width: double.infinity,
															child: ElevatedButton(
																onPressed: _isLoading ? null : _registerUser,
																style: ElevatedButton.styleFrom(
																	padding: const EdgeInsets.symmetric(vertical: 16),
																	backgroundColor: AppColors.primaryOrange,
																	shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
																	elevation: 0,
																),
																child: AnimatedSwitcher(
																	duration: const Duration(milliseconds: 250),
																	child: _isLoading
																			? const SizedBox(
																					width: 22,
																					height: 22,
																					child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
																				)
																			: Text('إنشاء حساب جديد', style: AppTextStyles.buttonText),
																),
															),
														),

														const SizedBox(height: 12),
														Center(
															child: TextButton(
																onPressed: () {
																	Navigator.of(context).pushReplacement(
																		MaterialPageRoute(builder: (context) => const LoginScreen()),
																	);
																},
																child: Text(
																	'لديك حساب بالفعل؟ تسجيل الدخول',
																	style: AppTextStyles.linkText.copyWith(color: AppColors.cardWhite),
																),
															),
														),
													],
												),
											),
										),
									).animate().fadeIn(duration: const Duration(milliseconds: 450), delay: const Duration(milliseconds: 120)).move(begin: const Offset(0, 16)),
								],
							),
						),
					),
				],
			),
		);
	}

	Widget _blurredCircle(double size, Color color) {
		return Container(
			width: size,
			height: size,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				color: color,
				boxShadow: [BoxShadow(color: color, blurRadius: 60, spreadRadius: 20)],
			),
		);
	}

	Widget _buildTextField({
		required TextEditingController controller,
		required String labelText,
		required IconData icon,
		TextInputType keyboardType = TextInputType.text,
		String? Function(String?)? validator,
	}) {
		return TextFormField(
			controller: controller,
			keyboardType: keyboardType,
			textAlign: TextAlign.right,
			style: AppTextStyles.bodyMedium,
			decoration: InputDecoration(
				labelText: labelText,
				prefixIcon: Icon(icon, color: AppColors.textHint),
				labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
				filled: true,
				fillColor: Colors.white,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
				),
			),
			validator: validator,
		);
	}

	Widget _buildPasswordField({
		required TextEditingController controller,
		required String labelText,
		required bool isVisible,
		required VoidCallback toggleVisibility,
		String? Function(String?)? validator,
	}) {
		return TextFormField(
			controller: controller,
			obscureText: !isVisible,
			textAlign: TextAlign.right,
			style: AppTextStyles.bodyMedium,
			decoration: InputDecoration(
				labelText: labelText,
				prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
				suffixIcon: IconButton(
					icon: Icon(
						isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
						color: AppColors.textHint,
					),
					onPressed: toggleVisibility,
				),
				labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
				filled: true,
				fillColor: Colors.white,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
				),
			),
			validator: validator,
		);
	}
}

class _FeatureChip extends StatelessWidget {
	final IconData icon;
	final String label;

	const _FeatureChip({required this.icon, required this.label});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
			decoration: BoxDecoration(
				color: Colors.white.withOpacity(0.14),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: Colors.white.withOpacity(0.16)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 16, color: Colors.white),
					const SizedBox(width: 6),
					Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
				],
			),
		);
	}
}
