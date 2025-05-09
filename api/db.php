<?php

// Abilita CORS (Cross-Origin Resource Sharing) per permettere le richieste da domini esterni
header("Access-Control-Allow-Origin: *"); // Permette l'accesso da qualsiasi dominio
header("Access-Control-Allow-Methods: GET, POST, OPTIONS"); // Permette i metodi GET, POST e OPTIONS
header("Access-Control-Allow-Headers: Content-Type"); // Permette l'intestazione Content-Type nelle richieste
header("Content-Type: application/json; charset=UTF-8"); // Imposta il tipo di contenuto come JSON e la codifica dei caratteri UTF-8

// Configurazione sicura per la connessione al database
$config = [
    'host' => 'localhost',     // Indirizzo del server del database
    'dbname' => 'ecommerce',   // Nome del database a cui ci si connette
    'username' => 'root',      // Nome utente per la connessione al database
    'password' => '',          // Password per la connessione al database (vuota per impostazione predefinita)
    'charset' => 'utf8mb4'     // Set di caratteri da utilizzare per la connessione (utf8mb4 supporta tutti i caratteri, inclusi emoji)
];

try {
    // Costruisce la stringa DSN (Data Source Name) per la connessione al database
    $dsn = "mysql:host={$config['host']};dbname={$config['dbname']};charset={$config['charset']}";
    
    // Opzioni per la connessione PDO
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, // Abilita la gestione delle eccezioni per gli errori PDO
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, // Imposta il formato di recupero dei dati in modalità associativa (array associativi)
        PDO::ATTR_EMULATE_PREPARES => false, // Disabilita la preparazione emulata per la sicurezza (uso di query preparate reali)
    ];

    // Crea una nuova connessione PDO al database con le configurazioni fornite
    $pdo = new PDO($dsn, $config['username'], $config['password'], $options);

} catch (PDOException $e) {
    // Se c'è un errore nella connessione al database, restituisce un errore con codice 500
    http_response_code(500); // Imposta il codice di stato HTTP a 500 (errore interno del server)
    
    // Termina lo script e restituisce un messaggio di errore in formato JSON
    die(json_encode([
        'status' => 'error',        // Stato dell'operazione (errore)
        'message' => 'Database connection failed', // Messaggio che descrive l'errore
        'error' => $e->getMessage() // Dettaglio dell'errore dal PDO
    ]));
}
?>
