import 'package:flutter/material.dart'; 
import 'views/order_view.dart';         
import 'views/user_view.dart';         

void main() {
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Costruttore del widget MyApp, utilizza la superclasse per gestire la chiave.

  @override
  Widget build(BuildContext context) {
    // Costruisce la struttura dell'applicazione, compreso il tema e la navigazione.
    return MaterialApp(
      title: 'Flutter App Bergamo-Giudice-Tiveron', 
      debugShowCheckedModeBanner: false,
      
      initialRoute: '/', // La route iniziale che viene mostrata all'avvio dell'app.
      
      routes: {
        // Definisce le rotte dell'app, collegandole a un widget.
        '/': (context) => const HomePage(), 
        '/users': (context) => const UserView(),
        '/orders': (context) => const OrderView(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key}); // Costruttore del widget HomePage.

  @override
  Widget build(BuildContext context) {
    // Costruisce la UI (User Interface) della schermata principale.
    return Scaffold(
      appBar: AppBar(title: const Text('Home')), // AppBar con il titolo "Home".
      body: Center(
  child: Stack(
    children: [
      // Sfondo dell'applicazione.
      Image.asset(
        'assets/images/phone.png',
        fit: BoxFit.fitHeight, // Adatta l'immagine per coprire tutto lo schermo.
        height: double.infinity, // Altezza dell'immagine uguale a quella dello schermo.
        width: double.infinity, // Larghezza dell'immagine uguale a quella dello schermo.
      ),
      // Contenuto sovrapposto all'immagine di sfondo.
      Positioned(
        top: 300, // Posiziona i pulsanti a 100 pixel dall'alto.
        left: 0,
        right: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Primo pulsante di navigazione per "Gestione Utenti".
            _buildNavigationButton(
              context: context,
              route: '/users',
              text: 'Gestione Utenti',
              color: Colors.blue,
            ),
            const SizedBox(height: 20), // Distanza tra i due pulsanti.
            // Secondo pulsante di navigazione per "Gestione Ordini".
            _buildNavigationButton(
              context: context,
              route: '/orders',
              text: 'Gestione Ordini',
              color: Colors.green,
            ),
          ],
        ),
      ),
    ],
  ),
),
    );
  }

  // Funzione helper che crea un pulsante di navigazione.
  Widget _buildNavigationButton({
    required BuildContext context, // Il contesto di costruzione del widget.
    required String route, // La route (percorso) da navigare.
    required String text, // Il testo del pulsante.
    required Color color, // Il colore di sfondo del pulsante.
  }) {
    return SizedBox(
      width: 200, // Imposta la larghezza del pulsante.
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Colore di sfondo del pulsante.
          padding: const EdgeInsets.symmetric(vertical: 15), // Imposta il padding verticale del pulsante.
        ),
        onPressed: () => Navigator.pushNamed(context, route), // Naviga verso la route quando il pulsante viene premuto.
        child: Text(
          text, // Mostra il testo del pulsante.
          style: const TextStyle(
            fontSize: 18, // Imposta la dimensione del testo.
            color: Colors.white, // Imposta il colore del testo su bianco.
          ),
        ),
      ),
    );
  }
}