import 'package:xml/xml.dart' as xml;               
import '../models/user.dart';                        
import '../services/api_service.dart';               
import 'dart:convert';                               
/// Controller per la gestione degli utenti
class UserController {
  final ApiService _api;                             // Istanza del servizio API configurato (json/xml)
  List<User> users = [];                             
  bool isLoading = true;                             
  String errorMessage = '';                         

  // Costruttore che accetta un'istanza di ApiService
  UserController(this._api);

  /// Metodo per ottenere la lista degli utenti da backend
  Future<void> fetchUsers() async {
    try {
      isLoading = true;                              
      errorMessage = '';                             

        // Chiamata GET 'Utenti.php'
      final response = await _api.get('Utenti.php');
      if (response.statusCode == 200) {
        // Se formato JSON
        users = _api.format == 'json' 
            ? (json.decode(response.body)['data'] as List)
                .map((u) => User.fromJson(u)).toList()
            // Se formato XML
            : xml.XmlDocument.parse(response.body)
                .findAllElements('utente')
                .map((e) => User.fromXml(e))
                .toList();
      } else {
        throw 'HTTP Error: ${response.statusCode}';  
      }
    } catch (e) {
      errorMessage = e.toString();                   
    } finally {
      isLoading = false;                            
    }
  }

  /// Metodo per salvare un utente (creazione o modifica)
  Future<bool> saveUser(User user, [int? id]) async {
    try {
      // Se ID è nullo -> POST (nuovo utente), altrimenti PUT (aggiornamento)
      final response = id == null 
          ? await _api.post('Utenti.php', user.toJson())
          : await _api.put('Utenti.php', id, user.toJson());

      // Controlla se la richiesta è andata a buon fine
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUsers();                          // Ricarica la lista utenti aggiornata
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = e.toString();                   
      return false;
    }
  }

  /// Metodo per eliminare un utente tramite ID
  Future<bool> deleteUser(int id) async {
    try {
      final response = await _api.delete('Utenti.php', id);
      if (response.statusCode == 200) {
        await fetchUsers();                          // Ricarica lista utenti dopo la cancellazione
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = e.toString();                  
      return false;
    }
  }
}
