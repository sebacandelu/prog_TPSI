<?php
require_once "db.php"; // Include il file di connessione al database

// Impostazioni per i CORS, che permettono le richieste da domini esterni
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Gestione delle richieste OPTIONS per i CORS (preflight requests)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0); // Esci se la richiesta è una OPTIONS (usata dai browser per verificare i permessi CORS)
}

// Gestione del formato di risposta (JSON o XML)
$format = isset($_GET['format']) && in_array(strtolower($_GET['format']), ['json', 'xml']) 
    ? strtolower($_GET['format']) 
    : 'json'; // Default a JSON se non specificato

try {
    // Impostazione degli errori per il PDO
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Gestione della richiesta in base al metodo HTTP (GET, POST, PUT, DELETE)
    switch ($_SERVER['REQUEST_METHOD']) {

        // Metodo GET - Leggere i dati (ottenere gli ordini)
        case 'GET':
            $utente_id = isset($_GET['utente_id']) ? (int)$_GET['utente_id'] : null; // Se specificato, ottieni l'ID dell'utente
            
            if ($utente_id) {
                // Recupera gli ordini di un utente specifico
                $stmt = $pdo->prepare("
                    SELECT o.id, o.utente_id,u.email, u.nome, o.prodotto, o.quantita 
                    FROM ordini o
                    JOIN utenti u ON o.utente_id = u.id 
                    WHERE u.id = ?
                ");
                $stmt->execute([$utente_id]);
            } else {
                // Recupera tutti gli ordini se l'utente non è specificato
                $stmt = $pdo->query("
                    SELECT o.id, o.utente_id, u.email, u.nome, o.prodotto, o.quantita 
                    FROM ordini o
                    JOIN utenti u ON o.utente_id = u.id
                ");
            }
            
            $ordini = $stmt->fetchAll(); // Ottieni tutti gli ordini
            // Risposta in formato JSON o XML
            sendResponse(200, ['status' => 'success', 'data' => $ordini, 'count' => count($ordini)], $format);
            break;

        // Metodo POST - Creare un nuovo ordine
        case 'POST':
            // Leggi i dati inviati nel corpo della richiesta
            $data = json_decode(file_get_contents('php://input'), true);
            
            // Controlla che i dati richiesti siano presenti
            if (!isset($data['utente']) || !isset($data['prodotto']) || !isset($data['quantita'])) {
                sendResponse(400, ['status' => 'error', 'message' => 'Dati mancanti'], $format); // Errore se mancano dati
            }
            
            // Cerca l'ID dell'utente in base al nome
            $stmt = $pdo->prepare("SELECT id FROM utenti WHERE email = ?");
            $stmt->execute([$data['utente']]);
            $utente = $stmt->fetch();
            
            // Se l'utente non esiste, invia un errore
            if (!$utente) {
                sendResponse(404, ['status' => 'error', 'message' => 'Utente non trovato'], $format);
            }
            
            $utente_id = $utente['id'];
            
            // Inserisci il nuovo ordine nel database
            $stmt = $pdo->prepare("INSERT INTO ordini (utente_id, prodotto, quantita) VALUES (?, ?, ?)");
            $stmt->execute([$utente_id, $data['prodotto'], $data['quantita']]);
            $id = $pdo->lastInsertId(); // Ottieni l'ID dell'ordine appena inserito
            
            // Recupera i dati completi dell'ordine appena creato
            $stmt = $pdo->prepare("
                SELECT o.id, o.utente_id, u.email, u.nome, o.prodotto, o.quantita 
                FROM ordini o
                JOIN utenti u ON o.utente_id = u.id
                WHERE o.id = ?
            ");
            $stmt->execute([$id]);
            $ordine = $stmt->fetch();
            
            // Rispondi con i dettagli dell'ordine appena creato
            sendResponse(201, [
                'status' => 'success', 
                'message' => 'Ordine creato',
                'data' => $ordine,
                'id' => $id
            ], $format);
            break;

        // Metodo PUT - Aggiornare un ordine esistente
        case 'PUT':
            $data = json_decode(file_get_contents('php://input'), true); // Leggi i dati inviati
            
            // Controlla che l'ID dell'ordine sia fornito
            if (!isset($_GET['id'])) {
                sendResponse(400, ['status' => 'error', 'message' => 'ID ordine mancante'], $format);
            }
            
            $fields = [];
            $params = [];
            
            // Se l'email dell'utente è fornito, cerca l'ID dell'utente
            if (isset($data['utente'])) {
                $stmt = $pdo->prepare("SELECT id FROM utenti WHERE email = ?");
                $stmt->execute([$data['utente']]);
                $utente = $stmt->fetch();
                
                if (!$utente) {
                    sendResponse(404, ['status' => 'error', 'message' => 'Utente non trovato'], $format);
                }
                
                $fields[] = "utente_id = ?"; // Aggiungi il campo per l'ID utente
                $params[] = $utente['id'];
            }
            
            // Se il prodotto è fornito, aggiungilo ai campi da aggiornare
            if (isset($data['prodotto'])) {
                $fields[] = "prodotto = ?";
                $params[] = $data['prodotto'];
            }
            
            // Se la quantità è fornita, aggiungila ai campi da aggiornare
            if (isset($data['quantita'])) {
                $fields[] = "quantita = ?";
                $params[] = $data['quantita'];
            }
            
            // Se non ci sono campi da aggiornare, invia un errore
            if (empty($fields)) {
                sendResponse(400, ['status' => 'error', 'message' => 'Nessun dato da aggiornare'], $format);
            }
            
            // Aggiungi l'ID dell'ordine alla lista dei parametri
            $params[] = $_GET['id'];
            // Costruisci la query di aggiornamento
            $sql = "UPDATE ordini SET " . implode(', ', $fields) . " WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            
            // Recupera i dati aggiornati dell'ordine
            $stmt = $pdo->prepare("
                SELECT o.id, o.utente_id, u.email, u.nome, o.prodotto, o.quantita 
                FROM ordini o
                JOIN utenti u ON o.utente_id = u.id
                WHERE o.id = ?
            ");
            $stmt->execute([$_GET['id']]);
            $ordine = $stmt->fetch();
            
            // Rispondi con i dati aggiornati dell'ordine
            sendResponse(200, [
                'status' => 'success', 
                'message' => 'Ordine aggiornato',
                'data' => $ordine
            ], $format);
            break;

        // Metodo DELETE - Eliminare un ordine
        case 'DELETE':
            // Controlla che l'ID dell'ordine sia fornito
            if (!isset($_GET['id'])) {
                sendResponse(400, ['status' => 'error', 'message' => 'ID ordine mancante'], $format);
            }
            
            // Esegui l'eliminazione dell'ordine
            $stmt = $pdo->prepare("DELETE FROM ordini WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            
            // Se non sono stati eliminati ordini, invia un errore
            if ($stmt->rowCount() === 0) {
                sendResponse(404, ['status' => 'error', 'message' => 'Ordine non trovato'], $format);
            }
            
            // Rispondi con un messaggio di successo
            sendResponse(200, ['status' => 'success', 'message' => 'Ordine eliminato'], $format);
            break;

        // Metodo non consentito
        default:
            sendResponse(405, ['status' => 'error', 'message' => 'Metodo non consentito'], $format);
    }
} catch (PDOException $e) {
    // Gestione degli errori del database
    sendResponse(500, [
        'status' => 'error',
        'message' => 'Errore del database',
        'error' => $e->getMessage()
    ], $format);
} catch (Exception $e) {
    // Gestione di altri errori
    sendResponse(500, [
        'status' => 'error',
        'message' => 'Errore del server',
        'error' => $e->getMessage()
    ], $format);
}

// Funzione per inviare la risposta al client in formato JSON o XML
function sendResponse($statusCode, $data, $format) {
    http_response_code($statusCode); // Imposta il codice di stato HTTP
    
    if ($format === 'xml') {
        header("Content-Type: application/xml"); // Imposta l'intestazione per XML
        echo arrayToXml($data); // Converte l'array in XML e lo invia
    } else {
        header("Content-Type: application/json"); // Imposta l'intestazione per JSON
        echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE); // Converte l'array in JSON e lo invia
    }
    exit;
}

// Funzione per convertire un array in formato XML
function arrayToXml($data, $rootNode = 'response') {
    $xml = new SimpleXMLElement("<$rootNode/>"); // Crea un nodo radice XML
    
    // Aggiungi lo status
    $xml->addChild('status', htmlspecialchars($data['status']));
    
    // Se c'è un messaggio, aggiungilo
    if (isset($data['message'])) {
        $xml->addChild('message', htmlspecialchars($data['message']));
    }
    
    // Gestione dei dati
    if (isset($data['data'])) {
        $dataNode = $xml->addChild('data');
        if (is_array($data['data'])) {
            foreach ($data['data'] as $item) {
                $orderNode = $dataNode->addChild('ordine');
                foreach ($item as $key => $value) {
                    $orderNode->addChild($key, htmlspecialchars($value)); // Aggiungi ogni campo come nodo XML
                }
            }
        }
    }
    
    return $xml->asXML(); // Restituisci l'XML generato
}
