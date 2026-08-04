import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_notifier.dart';
import '../map/envanter_notifier.dart';
import '../auth/auth_viewmodel.dart';
import '../auth/login_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'Bilinmiyor';

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [

          _baslik('Tema'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setTheme(s.first),
            ),
          ),
          const Divider(height: 32),

          _baslik('Hesap'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('E-posta'),
            subtitle: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authViewModelProvider).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
          const Divider(height: 32),

          _baslik('Veri'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Tüm envanterleri sil'),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
          const Divider(height: 32),

          _baslik('Hakkında'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('CBS Harita Uygulaması'),
            subtitle: Text('Sürüm 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _baslik(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misin?'),
        content: const Text('Tüm envanter kayıtları kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (onay == true) {
      await ref.read(envanterlerProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm envanterler silindi')),
        );
      }
    }
  }
}
