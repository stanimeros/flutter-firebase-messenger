import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../models/topic_model.dart';
import '../models/user_model.dart';
import '../services/app_storage_service.dart';
import '../services/topic_storage_service.dart';
import '../services/user_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import 'create_app_screen.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appStorage = AppStorageService();
  final _topicStorage = TopicStorageService();
  final _userStorage = UserStorageService();
  
  List<TopicModel> _topics = [];
  List<UserModel> _users = [];

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

  Future<void> _showAddTopicDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _AddTopicDialog(),
    );

    if (result != null && result.isNotEmpty) {
      final topic = TopicModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appId: widget.app.id,
        name: result,
        createdAt: DateTime.now(),
      );

      await _topicStorage.saveTopic(topic);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic added successfully')),
        );
      }
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

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddUserDialog(),
    );

    if (result != null && result.containsKey('name') && result.containsKey('token')) {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appId: widget.app.id,
        name: result['name']!,
        notificationToken: result['token']!,
        createdAt: DateTime.now(),
      );

      await _userStorage.saveUser(user);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );
      }
    }
  }

  Future<void> _deleteApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App'),
        content: Text('Are you sure you want to delete ${widget.app.name}? This action cannot be undone.'),
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
      await _appStorage.deleteApp(widget.app.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App deleted')),
        );
      }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.app.name,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const HeroIcon(
              HeroIcons.pencil,
              color: Colors.white,
            ),
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
          IconButton(
            icon: const HeroIcon(
              HeroIcons.trash,
              color: Colors.white,
            ),
            onPressed: _deleteApp,
            tooltip: 'Delete App',
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: HeroIcon(HeroIcons.hashtag), text: 'Topics'),
              Tab(icon: HeroIcon(HeroIcons.user), text: 'Users'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopicsTab(),
                _buildUsersTab(),
              ],
            ),
          ),
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
          ElevatedButton.icon(
            onPressed: _showAddTopicDialog,
            icon: const HeroIcon(HeroIcons.plus),
            label: const Text('Add Topic'),
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
          ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            icon: const HeroIcon(HeroIcons.plus),
            label: const Text('Add User'),
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

class _AddTopicDialog extends StatefulWidget {
  const _AddTopicDialog();

  @override
  State<_AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<_AddTopicDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Topic'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Topic Name',
            hintText: 'news',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a topic name';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _nameController.text.trim());
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'User Name',
                  hintText: 'John Doe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Notification Token',
                  hintText: 'FCM device token',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a token';
                  }
                  return null;
                },
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'token': _tokenController.text.trim(),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
