import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';

class AuthScreen extends StatefulWidget {
  final AuthCubit cubit;
  const AuthScreen({super.key, required this.cubit});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _demoNameController = TextEditingController(text: 'طالب');
  bool _registerMode = false;
  static const _demoEnabled = bool.fromEnvironment('HAYY_DEMO_MODE');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _demoNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_registerMode) {
      widget.cubit.register(_emailController.text, _passwordController.text);
    } else {
      widget.cubit.login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0F2F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                size: 54,
                                color: Color(0xFF00695C),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حيّ',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'منصة المهام والمساعدة المجتمعية',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 32),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('تسجيل الدخول'),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('حساب جديد'),
                              ),
                            ],
                            selected: {_registerMode},
                            onSelectionChanged: loading
                                ? null
                                : (value) => setState(
                                    () => _registerMode = value.first,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? 'أدخل بريداً إلكترونياً صحيحاً'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                ? 'كلمة المرور 6 أحرف على الأقل'
                                : null,
                          ),
                          if (state is AuthError) ...[
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: loading ? null : _submit,
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(
                              _registerMode ? 'إنشاء الحساب' : 'دخول آمن',
                            ),
                          ),
                          if (_demoEnabled) ...[
                            const SizedBox(height: 18),
                            const Divider(),
                            const Text(
                              'وضع العرض المحلي (اختياري)',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _demoNameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم مستخدم العرض',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: loading
                                  ? null
                                  : () => widget.cubit.startDemo(
                                      _demoNameController.text,
                                    ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('بدء رحلة التكامل المحلية'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Text('يتطلب التشغيل الحقيقي إعداد Firebase Email/Password وgoogle-services.json.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
