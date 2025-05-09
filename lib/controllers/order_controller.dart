import 'package:xml/xml.dart' as xml;
import '../models/order.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'dart:convert';

/// Controller che gestisce logica e dati per gli Ordini
class OrderController {
  final ApiService _api;       // Servizio API configurato con formato (json/xml)
  List<Order> orders = [];     
  List<User> users = [];     
  bool isLoading = true;       // Stato di caricamento per UI
  String errorMessage = '';   

  // Costruttore che accetta un'istanza di ApiService
  OrderController(this._api);

  /// Metodo per caricare sia gli utenti che gli ordini
  Future<void> fetchAllData() async {
    try {
      isLoading = true;
      errorMessage = '';

      // Chiamata API per ottenere la lista utenti
      final usersResponse = await _api.get('Utenti.php');
      if (usersResponse.statusCode == 200) {
        users = _parseUsers(usersResponse.body);

        // Se ci sono utenti, carica anche gli ordini
        if (users.isNotEmpty) {
          await fetchOrders();
        }
      } else {
        throw 'HTTP Error: ${usersResponse.statusCode}';
      }
    } catch (e) {
      // Gestione errori
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  /// Metodo per convertire la risposta degli utenti da JSON o XML in oggetti User
  List<User> _parseUsers(String body) {
    return _api.format == 'json' 
        // Parsing JSON
        ? (json.decode(body)['data'] as List).map((u) => User.fromJson(u)).toList()
        // Parsing XML
        : xml.XmlDocument.parse(body)
            .findAllElements('utente')
            .map((e) => User.fromXml(e))
            .toList();
  }

  /// Metodo per caricare tutti gli ordini
  Future<void> fetchOrders() async {
    try {
      final response = await _api.get('Ordini.php');
      if (response.statusCode == 200) {
        orders = _api.format == 'json' 
            // Parsing JSON
            ? (json.decode(response.body)['data'] as List).map((o) => Order.fromJson(o)).toList()
            // Parsing XML
            : xml.XmlDocument.parse(response.body)
                .findAllElements('ordine')
                .map((e) => Order.fromXml(e))
                .toList();
      } else {
        throw 'HTTP Error: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  /// Metodo per creare o aggiornare un ordine
  Future<bool> saveOrder(Order order, [int? id]) async {
    try {
      // Se l'ID del prodotto è nullo, si tratta di una creazione (POST), altrimenti aggiornamento (PUT)
      final response = id == null 
          ? await _api.post('Ordini.php', order.toJson())
          : await _api.put('Ordini.php', id, order.toJson());
    
      // Verifica del successo
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrders(); // Aggiorna lista ordini
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  /// Metodo per eliminare un ordine specifico
  Future<bool> deleteOrder(int id) async {
    try {
      final response = await _api.delete('Ordini.php', id);
      if (response.statusCode == 200) {
        await fetchOrders(); // Ricarica lista
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}
