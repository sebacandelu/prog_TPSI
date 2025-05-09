import 'package:xml/xml.dart' as xml;

/// Modello dati per rappresentare un utente
class User {
  final int id;
  final String name;
  final String email;

  // Costruttore della classe
  User({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Costruttore factory per creare un oggetto User da un JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()), // Converte l'ID in intero (anche se è una stringa)
      name: json['nome'], 
      email: json['email'], 
    );
  }

  /// Costruttore factory per creare un oggetto User da un elemento XML
  factory User.fromXml(xml.XmlElement xmlElement) {
    return User(
      id: int.parse(xmlElement.findElements('id').single.text), 
      name: xmlElement.findElements('nome').single.text,        
      email: xmlElement.findElements('email').single.text,      
    );
  }

  /// Metodo per convertire l'oggetto in formato JSON (usato per invio via API)
  Map<String, dynamic> toJson() => {
        'nome': name,
        'email': email,
      };
}
