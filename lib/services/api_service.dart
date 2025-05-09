import 'package:http/http.dart' as http;
import 'dart:convert';


class ApiService {
  // URL base del server API
  static const String _baseUrl = 'http://localhost/api';

  // Formato richiesto (json o xml)
  final String format;

  // Costruttore che accetta il formato da usare
  ApiService(this.format);

  /// Metodo GET: recupera dati da un endpoint con il formato selezionato
  Future<http.Response> get(String endpoint) async {
    return await http.get(
      Uri.parse('$_baseUrl/$endpoint?format=$format'),
      headers: {
        // Imposta l'header Accept in base al formato scelto
        'Accept': 'application/${format == 'json' ? 'json' : 'xml'}',
      },
    ).timeout(const Duration(seconds: 10)); // Imposta un Timeout di 10 secondi. Superati i 10 secondi la richiesta fallisce
  }

  /// Metodo POST: invia dati (body) a un endpoint per creare una risorsa
  Future<http.Response> post(String endpoint, dynamic body) async {
    return await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json', 
        'Accept': 'application/${format == 'json' ? 'json' : 'xml'}',  
      },
      body: json.encode(body), // Codifica il body in JSON
    );
  }

  /// Metodo PUT: aggiorna una risorsa identificata da un ID
  Future<http.Response> put(String endpoint, int id, dynamic body) async {
    return await http.put(
      Uri.parse('$_baseUrl/$endpoint?id=$id'), //  L'ID viene passato come parametro query
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/${format == 'json' ? 'json' : 'xml'}',
      },
      body: json.encode(body),
    );
  }

  /// Metodo DELETE: elimina una risorsa identificata da un ID
  Future<http.Response> delete(String endpoint, int id) async {
    return await http.delete(
      Uri.parse('$_baseUrl/$endpoint?id=$id'), // L'ID viene passato come parametro query
      headers: {
        'Accept': 'application/${format == 'json' ? 'json' : 'xml'}',
      },
    );
  }
}
