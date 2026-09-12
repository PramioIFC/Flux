import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../providers/flux_provider.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final provider = Provider.of<FluxProvider>(context, listen: false);
    setState(() => _isSearching = true);
    final results = await provider.searchUsers(query.trim());
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluxApp.backgroundColor,
      appBar: AppBar(
        title: const Text('Amigos'),
        backgroundColor: FluxApp.surfaceColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuários por nome...',
                prefixIcon: const Icon(Icons.search, color: FluxApp.secondaryTextColor),
                filled: true,
                fillColor: FluxApp.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: FluxApp.primaryTextColor),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildFriendsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: FluxApp.accentColor));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum usuário encontrado.',
          style: TextStyle(color: FluxApp.secondaryTextColor),
        ),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserTile(user: user);
      },
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FluxProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: provider.getFriendsList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: FluxApp.accentColor));
            }
            final friendsList = snapshot.data ?? [];
            if (friendsList.isEmpty) {
              return Center(
                child: Text(
                  'Você ainda não adicionou nenhum amigo.',
                  style: GoogleFonts.inter(color: FluxApp.secondaryTextColor),
                ),
              );
            }
            return ListView.builder(
              itemCount: friendsList.length,
              itemBuilder: (context, index) {
                return _UserTile(user: friendsList[index]);
              },
            );
          },
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FluxProvider>(context);
    final userId = user['user_id'] as String;
    final username = user['username'] as String? ?? 'Desconhecido';
    final isFriend = provider.friends.contains(userId);

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: FluxApp.accentColor,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(username, style: const TextStyle(color: Colors.white)),
      trailing: IconButton(
        icon: Icon(
          isFriend ? Icons.person_remove : Icons.person_add,
          color: isFriend ? Colors.redAccent : FluxApp.accentColor,
        ),
        onPressed: () {
          provider.toggleFriend(userId);
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendProfileScreen(
              friendId: userId,
              username: username,
            ),
          ),
        );
      },
    );
  }
}
