import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../models/topic_model.dart';
import '../models/user_model.dart';
import '../services/app_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import 'create_app_screen.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;
  final VoidCallback? onDataChanged;

  const AppDetailScreen({
    super.key,
    required this.app,
    this.onDataChanged,
  });

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appStorage = AppStorageService();
  
  late AppModel _currentApp;
  List<TopicModel> _topics = [];
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _currentApp = widget.app;
    _topics = widget.app.topics;
    _users = widget.app.users;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update FAB
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final app = await _appStorage.getAppById(_currentApp.id);
    if (app != null) {
      setState(() {
        _currentApp = app;
        _topics = app.topics;
        _users = app.users;
      });
    }
  }

  Future<void> _showAddTopicDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _AddTopicDialog(),
    );

    if (result != null && result.isNotEmpty) {
      final topic = TopicModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result,
        createdAt: DateTime.now(),
      );

      await _appStorage.addTopic(_currentApp.id, topic);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic added successfully')),
        );
        // Notify parent that data changed
        widget.onDataChanged?.call();
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
      await _appStorage.deleteTopic(_currentApp.id, topic.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic deleted')),
        );
        widget.onDataChanged?.call();
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
        name: result['name']!,
        notificationToken: result['token']!,
        createdAt: DateTime.now(),
      );

      await _appStorage.addUser(_currentApp.id, user);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );
        // Notify parent that data changed
        widget.onDataChanged?.call();
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
      await _appStorage.deleteApp(_currentApp.id);
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
      await _appStorage.deleteUser(_currentApp.id, user.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
        widget.onDataChanged?.call();
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
        title: Text(widget.app.name),
        actions: [
          IconButton(
            icon: const HeroIcon(
              HeroIcons.pencil,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAppScreen(app: _currentApp),
                ),
              );
              if (result == true && context.mounted) {
                // Reload the app data if it was updated
                await _loadData();
                widget.onDataChanged?.call();
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            tooltip: 'Edit App',
          ),
          IconButton(
            icon: HeroIcon(
              HeroIcons.trash,
              color: Theme.of(context).colorScheme.error,
              size: 18,
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
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.hashtag, size: 18),
                    SizedBox(width: 6),
                    Text('Topics'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.user, size: 18),
                    SizedBox(width: 6),
                    Text('Users'),
                  ],
                ),
              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _tabController.index == 0 ? _showAddTopicDialog : _showAddUserDialog,
        child: HeroIcon(_tabController.index == 0 ? HeroIcons.plus : HeroIcons.plus),
      ),
    );
  }

  Widget _buildTopicsTab() {
    if (_topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroIcon(
                HeroIcons.inbox,
                size: 48,
                style: HeroIconStyle.outline,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                'No topics added yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _topics.map((topic) => Card(
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
            )).toList(),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroIcon(
                HeroIcons.inbox,
                size: 48,
                style: HeroIconStyle.outline,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                'No users added yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _users.map((user) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: HeroIcon(HeroIcons.user),
                ),
                title: Text(user.name),
                subtitle: Text(
                  user.notificationToken,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const HeroIcon(HeroIcons.trash),
                  onPressed: () => _deleteUser(user),
                ),
              ),
            )).toList(),
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
              const SizedBox(height: 12),
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
