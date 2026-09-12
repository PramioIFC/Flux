import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../providers/flux_provider.dart';
import 'auth_screen.dart';
import 'equalizer_screen.dart';
import 'friends_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _username;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: context.read<FluxProvider>().username);
  }

  @override
  void dispose() { _username.dispose(); super.dispose(); }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FluxProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const _SectionTitle('CONTA'),
        Card(child: Column(children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.email ?? 'Usuário não logado'),
            subtitle: Text(user?.emailConfirmedAt == null ? 'E-mail pendente' : 'E-mail verificado'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Nome de usuário'),
              onSubmitted: provider.updateUsername,
            ),
          ),
          SwitchListTile(
            title: const Text('Tornar minhas playlists públicas'),
            value: provider.isPublic,
            onChanged: provider.toggleIsPublic,
          ),
          ListTile(
            leading: const Icon(Icons.people_outline), title: const Text('Amigos'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair da conta', style: TextStyle(color: Colors.redAccent)), onTap: _signOut,
          ),
        ])),
        const SizedBox(height: 24),
        const _SectionTitle('DEMO E ÁUDIO'),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.verified_outlined, color: FluxApp.accentColor),
            title: const Text('Catálogo público licenciado'),
            subtitle: const Text('A busca e o player aceitam somente as faixas permitidas incluídas no catálogo demo.'),
          ),
          SwitchListTile(
            title: const Text('Mostrar catálogo em destaque'),
            value: provider.showTrending,
            onChanged: provider.toggleShowTrending,
          ),
          ListTile(
            leading: const Icon(Icons.equalizer, color: FluxApp.accentColor),
            title: const Text('Equalizador e efeitos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerScreen())),
          ),
        ])),
        const SizedBox(height: 24),
        const _SectionTitle('SOBRE'),
        const Card(child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Flux é uma demonstração educacional e de portfólio. Esta versão reproduz exclusivamente '
            'gravações autorizadas do catálogo curado. Os créditos, a fonte e a licença de cada faixa '
            'são mantidos junto aos seus metadados.',
            style: TextStyle(height: 1.45, color: FluxApp.secondaryTextColor),
          ),
        )),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(color: FluxApp.accentColor,
      fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
  );
}
