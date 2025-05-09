import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import '../services/api_service.dart';
import '../models/user.dart';

/// Vista principale per la gestione degli utenti
class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  late UserController _controller;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedFormat = 'json';
  int? _editingId;

  final _formKey = GlobalKey<FormState>(); // 🔹 Aggiunta chiave per il Form

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = UserController(ApiService(_selectedFormat));
    _controller.fetchUsers().then((_) => setState(() {}));
  }

  void _handleFormatChange(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedFormat = newValue;
        _initializeController();
      });
    }
  }

  void _showUserForm([User? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey, // 🔹 Wrappa il form
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Il nome è obbligatorio' : null,
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'L\'email è obbligatoria';

                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) return 'Formato email non valido';

                final exists = _controller.users.any((u) =>
                    u.email.toLowerCase() == email.toLowerCase() &&
                    u.id != _editingId);
                if (exists) return 'Email già esistente';

                return null;
              },
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return; // 🔹 Validazione form

                  final user = User(
                    id: _editingId ?? 0,
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                  );

                  final success = await _controller.saveUser(user, _editingId);
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_editingId == null
                            ? 'Utente creato con successo'
                            : 'Utente aggiornato con successo'),
                      ),
                    );
                    _clearForm();
                    _controller.fetchUsers().then((_) => setState(() {}));
                  }
                },
                child: Text(_editingId == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _editingId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Utenti'),
        actions: [
          DropdownButton<String>(
            value: _selectedFormat,
            items: ['json', 'xml']
                .map((format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.toUpperCase()),
                    ))
                .toList(),
            onChanged: _handleFormatChange,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showUserForm();
        },
        child: const Icon(Icons.add),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.errorMessage.isNotEmpty
              ? Center(child: Text(_controller.errorMessage))
              : ListView.builder(
                  itemCount: _controller.users.length,
                  itemBuilder: (context, index) {
                    final user = _controller.users[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editingId = user.id;
                              _nameController.text = user.name;
                              _emailController.text = user.email;
                              _showUserForm(user);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _controller
                                .deleteUser(user.id)
                                .then((success) => success
                                    ? _controller
                                        .fetchUsers()
                                        .then((_) => setState(() {}))
                                    : null),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
/*
validator: (value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'L\'email è obbligatoria';

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email)) return 'Formato email non valido';

  final exists = _controller.users.any((u) =>
      u.email.toLowerCase() == email.toLowerCase() &&
      u.id != _editingId);
  if (exists) return 'Email già esistente';

  return null;
},
*/