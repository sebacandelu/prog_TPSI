import 'package:xml/xml.dart' as xml;

/// Modello dati per rappresentare un ordine
class Order {
  final int id;            // ID univoco dell’ordine
  final String customer;   // Nome del cliente
  final String product;    // Prodotto ordinato
  final int quantity;      

  // Costruttore dell'oggetto Order
  Order({
    required this.id,
    required this.customer,
    required this.product,
    required this.quantity,
  });

  /// Costruttore per creare un Order a partire da una mappa JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: int.parse(json['id'].toString()),

      // Gestisce nomi alternativi per il campo cliente: 'email' o 'utente'
      customer: json['email'] ?? json['utente'] ?? '',

      product: json['prodotto'],
      quantity: int.parse(json['quantita'].toString()),
    );
  }

  /// Costruttore per creare un Order a partire da un elemento XML
  factory Order.fromXml(xml.XmlElement xmlElement) {
    return Order(
      id: int.parse(xmlElement.findElements('id').single.text),
      customer: xmlElement.findElements('nome').single.text,
      product: xmlElement.findElements('prodotto').single.text,
      quantity: int.parse(xmlElement.findElements('quantita').single.text),
    );
  }

  /// Metodo per convertire l’oggetto in formato JSON (per invio al backend)
  Map<String, dynamic> toJson() => {
        'utente': customer,       // Nota: usa 'utente' come chiave per il cliente
        'prodotto': product,
        'quantita': quantity,
      };
}
