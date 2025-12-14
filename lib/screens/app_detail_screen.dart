import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../models/topic_model.dart';
import '../models/user_model.dart';
import '../services/topic_storage_service.dart';
import '../services/user_storage_service.dart';
import 'create_app_screen.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _topicStorage = TopicStorageService();
  final _userStorage = UserStorageService();
  
  List<TopicModel> _topics = [];
  List<UserModel> _users = [];
  
  final _topicNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _userTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final topics = await _topicStorage.getTopics(widget.app.id);
    final users = await _userStorage.getUsers(widget.app.id);
    setState(() {
      _topics = topics;
      _users = users;
    });
  }

  Future<void> _addTopic() async {
    final name = _topicNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter topic name'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final topic = TopicModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      appId: widget.app.id,
      name: name,
      createdAt: DateTime.now(),
    );

    await _topicStorage.saveTopic(topic);
    _topicNameController.clear();
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic added successfully')),
      );
    }
  }

  Future<void> _deleteTopic(TopicModel topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete topic "${topic.name}"?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _topicStorage.deleteTopic(topic.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic deleted')),
        );
      }
    }
  }

  Future<void> _addUser() async {
    final name = _userNameController.text.trim();
    final token = _userTokenController.text.trim();
    
    if (name.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter both name and token'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      appId: widget.app.id,
      name: name,
      notificationToken: token,
      createdAt: DateTime.now(),
    );

    await _userStorage.saveUser(user);
    _userNameController.clear();
    _userTokenController.clear();
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user.name}"?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _userStorage.deleteUser(user.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicNameController.dispose();
    _userNameController.dispose();
    _userTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.app.name),
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.pencil),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAppScreen(app: widget.app),
                ),
              );
              if (result == true && context.mounted) {
                // Reload the app data if it was updated
                Navigator.pop(context, true);
              }
            },
            tooltip: 'Edit App',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: HeroIcon(HeroIcons.hashtag), text: 'Topics'),
            Tab(icon: HeroIcon(HeroIcons.user), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopicsTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildTopicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Topic',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _topicNameController,
                    decoration: const InputDecoration(
                      labelText: 'Topic Name',
                      hintText: 'news',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTopic,
                    child: const Text('Add Topic'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Topics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_topics.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    HeroIcon(
                      HeroIcons.inbox,
                      size: 48,
                      style: HeroIconStyle.outline,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No topics added yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._topics.map((topic) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: HeroIcon(HeroIcons.hashtag),
                    ),
                    title: Text(topic.name),
                    trailing: IconButton(
                      icon: const HeroIcon(HeroIcons.trash),
                      onPressed: () => _deleteTopic(topic),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userNameController,
                    decoration: const InputDecoration(
                      labelText: 'User Name',
                      hintText: 'John Doe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Token',
                      hintText: 'FCM device token',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addUser,
                    child: const Text('Add User'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Users',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_users.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    HeroIcon(
                      HeroIcons.inbox,
                      size: 48,
                      style: HeroIconStyle.outline,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users added yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._users.map((user) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: HeroIcon(HeroIcons.user),
                    ),
                    title: Text(user.name),
                    subtitle: Text(
                      user.notificationToken,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const HeroIcon(HeroIcons.trash),
                      onPressed: () => _deleteUser(user),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
