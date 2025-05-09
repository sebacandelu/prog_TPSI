import 'package:flutter/material.dart';
import '../controllers/order_controller.dart';
import '../services/api_service.dart';
import '../models/order.dart';

/// Vista principale per la gestione degli ordini
class OrderView extends StatefulWidget {
  const OrderView({super.key});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  // Controller per la logica degli ordini
  late OrderController _controller;

  // Chiave per validazione del form
  final _formKey = GlobalKey<FormState>();

  // Controller per input del prodotto e quantità
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Stato del formato selezionato (json/xml)
  String _selectedFormat = 'json';

  // Utente selezionato dal menu a discesa
  String? _selectedUser;

  // ID dell'ordine in fase di modifica (null se si sta creando un nuovo ordine)
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _initializeController(); // Inizializza il controller all'avvio
  }

  /// Inizializza il controller con il formato selezionato (json/xml)
  void _initializeController() {
    _controller = OrderController(ApiService(_selectedFormat));
    _controller.fetchAllData().then((_) => setState(() {}));
  }

  /// Gestisce il cambio di formato (json/xml)
  void _handleFormatChange(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedFormat = newValue;
        _initializeController(); // Ricarica i dati con il nuovo formato
      });
    }
  }

  /// Carica i dati di un ordine esistente nel form per la modifica
  void _editOrder(Order order) {
    setState(() {
      _editingId = order.id;
      _selectedUser = order.customer;
      _productController.text = order.product;
      _quantityController.text = order.quantity.toString();
    });
  }

  /// Reimposta i campi del form
  void _resetForm() {
    _formKey.currentState?.reset();
    _selectedUser = null;
    _productController.clear();
    _quantityController.clear();
    _editingId = null;
  }

  /// Salva o aggiorna un ordine dopo la validazione del form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) return;

    final order = Order(
      id: _editingId ?? 0,
      customer: _selectedUser!,
      product: _productController.text,
      quantity: int.parse(_quantityController.text),
    );

    final success = await _controller.saveOrder(order, _editingId);
    if (success && mounted) {
      // Mostra un messaggio di conferma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null 
            ? 'Ordine creato con successo' 
            : 'Ordine aggiornato con successo')),
      );
      _resetForm(); // Pulisce il form
      _controller.fetchAllData().then((_) => setState(() {})); // Ricarica i dati
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Ordini'),
        actions: [
          // Selettore del formato API (json o xml)
          DropdownButton<String>(
            value: _selectedFormat,
            items: ['json', 'xml'].map((format) => 
              DropdownMenuItem(
                value: format,
                child: Text(format.toUpperCase()),
              )).toList(),
            onChanged: _handleFormatChange,
          ),
         
        ],
      ),
      body: _controller.isLoading
          // Indicatore di caricamento
          ? const Center(child: CircularProgressIndicator())
          // Gestione degli errori
          : _controller.errorMessage.isNotEmpty
              ? Center(child: Text(_controller.errorMessage))
              // Nessun utente disponibile
              : _controller.users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Nessun utente trovato'),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/users'),
                            child: const Text('Aggiungi Utenti'),
                          ),
                        ],
                      ),
                    )
                  // Interfaccia principale: form + lista ordini
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Form per creare o modificare ordini
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Selezione utente
                                    DropdownButtonFormField<String>(
                                      value: _selectedUser,
                                      items: _controller.users.map((user) => 
                                        DropdownMenuItem(
                                          value: user.email,
                                          child: Text(user.email),
                                        )).toList(),
                                      onChanged: _editingId == null 
                                          ? (value) => setState(() => _selectedUser = value)
                                          : null, // Disabilita la selezione in modifica
                                      decoration: const InputDecoration(
                                        labelText: 'Cliente',
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      validator: (value) => value == null ? 'Seleziona un utente' : null,
                                    ),
                                    // Input prodotto
                                    TextFormField(
                                      controller: _productController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prodotto',
                                        prefixIcon: Icon(Icons.shopping_cart),
                                      ),
                                      validator: (value) =>
                                        value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                                    ),
                                    // Input quantità
                                    TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantità',
                                        prefixIcon: Icon(Icons.numbers),
                                      ),
                                  validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Inserisci un numero';
                                      }
                                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) { // Solo cifre numeriche
                                        return 'Inserisci un numero intero valido';
                                      }
                                      return null;
                                    },
                                    ),
                                    const SizedBox(height: 16),
                                    // Pulsante per aggiungere o aggiornare ordine
                                    ElevatedButton(
                                      onPressed: _submitForm,
                                      child: Text(_editingId == null 
                                          ? 'Aggiungi Ordine' 
                                          : 'Aggiorna Ordine'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Lista degli ordini
                          Expanded(
                            child: ListView.builder(
                              itemCount: _controller.orders.length,
                              itemBuilder: (context, index) {
                                final order = _controller.orders[index];
                                return ListTile(
                                  title: Text(order.customer),
                                  subtitle: Text('${order.product} (x${order.quantity})'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pulsante modifica ordine
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editOrder(order),
                                      ),
                                      // Pulsante elimina ordine
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _controller.deleteOrder(order.id)
                                          .then((success) => success 
                                            ? _controller.fetchAllData().then((_) => setState(() {}))
                                            : null),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
