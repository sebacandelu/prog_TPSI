<?php
// Includiamo il file di connessione al database
require_once "db.php";

// Abilita CORS (Cross-Origin Resource Sharing) per consentire richieste da altri domini
header("Access-Control-Allow-Origin: *"); // Consente l'accesso da qualsiasi dominio
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS"); // Consente i metodi HTTP specificati
header("Access-Control-Allow-Headers: Content-Type"); // Consente l'intestazione Content-Type

// Gestione richiesta OPTIONS per CORS
// Quando un browser invia una richiesta "preflight" OPTIONS per verificare le intestazioni CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0); // Risponde con successo senza proseguire con la logica della richiesta
}

// Validazione dell'input per determinare il formato di risposta (json o xml)
$format = isset($_GET['format']) && in_array(strtolower($_GET['format']), ['json', 'xml']) 
    ? strtolower($_GET['format']) // Se il formato è JSON o XML, lo usa
    : 'json'; // Imposta il formato predefinito a JSON

try {
    // Imposta l'attributo per la gestione degli errori del database
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Operazioni CRUD (Create, Read, Update, Delete) basate sul metodo HTTP
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            // READ: Recupera l'utente o la lista di utenti
            if (isset($_GET['id'])) {
                // Se è presente un ID, recupera un singolo utente
                $stmt = $pdo->prepare("SELECT id, nome, email FROM utenti WHERE id = ?");
                $stmt->execute([$_GET['id']]);
                $utente = $stmt->fetch();
                
                // Se l'utente non esiste, invia una risposta di errore 404
                if (!$utente) {
                    sendResponse(404, ['status' => 'error', 'message' => 'Utente non trovato'], $format);
                }
                
                // Invia la risposta con i dettagli dell'utente
                sendResponse(200, ['status' => 'success', 'data' => $utente], $format);
            } else {
                // Se l'ID non è presente, recupera la lista di tutti gli utenti
                $stmt = $pdo->query("SELECT id, nome, email FROM utenti");
                $utenti = $stmt->fetchAll();
                
                // Invia la risposta con la lista degli utenti e il conteggio
                sendResponse(200, ['status' => 'success', 'data' => $utenti, 'count' => count($utenti)], $format);
            }
            break;

        case 'POST':
            // CREATE: Aggiungi un nuovo utente
            // Decodifica i dati in formato JSON inviati nel corpo della richiesta
            $data = json_decode(file_get_contents('php://input'), true);
            
            // Verifica che il nome e l'email siano forniti
            if (!isset($data['nome']) || !isset($data['email'])) {
                sendResponse(400, ['status' => 'error', 'message' => 'Nome e email sono obbligatori'], $format);
            }
            
            // Esegui la query per inserire un nuovo utente nel database
            $stmt = $pdo->prepare("INSERT INTO utenti (nome, email) VALUES (?, ?)");
            $stmt->execute([$data['nome'], $data['email']]);
            
            // Recupera l'ID del nuovo utente inserito
            $id = $pdo->lastInsertId();
            
            // Invia la risposta di successo con l'ID del nuovo utente
            sendResponse(201, [
                'status' => 'success', 
                'message' => 'Utente creato',
                'id' => $id
            ], $format);
            break;

        case 'PUT':
            // UPDATE: Modifica i dati di un utente esistente
            // Decodifica i dati in formato JSON inviati nel corpo della richiesta
            $data = json_decode(file_get_contents('php://input'), true);
            
            // Verifica che l'ID dell'utente sia stato fornito nella query string
            if (!isset($_GET['id'])) {
                sendResponse(400, ['status' => 'error', 'message' => 'ID utente mancante'], $format);
            }
            
            // Prepara i dati da aggiornare
            $fields = [];
            $params = [];
            
            // Se sono forniti nuovi valori per nome o email, li aggiungiamo all'array
            if (isset($data['nome'])) {
                $fields[] = "nome = ?";
                $params[] = $data['nome'];
            }
            
            if (isset($data['email'])) {
                $fields[] = "email = ?";
                $params[] = $data['email'];
            }
            
            // Se non c'è nulla da aggiornare, restituisce un errore
            if (empty($fields)) {
                sendResponse(400, ['status' => 'error', 'message' => 'Nessun dato da aggiornare'], $format);
            }
            
            // Aggiunge l'ID dell'utente ai parametri
            $params[] = $_GET['id'];
            
            // Esegui la query di aggiornamento
            $sql = "UPDATE utenti SET " . implode(', ', $fields) . " WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            
            // Invia la risposta di successo
            sendResponse(200, ['status' => 'success', 'message' => 'Utente aggiornato'], $format);
            break;

        case 'DELETE':
            // DELETE: Elimina un utente esistente
            // Verifica che l'ID dell'utente sia stato fornito nella query string
            if (!isset($_GET['id'])) {
                sendResponse(400, ['status' => 'error', 'message' => 'ID utente mancante'], $format);
            }
            
            // Esegui la query per eliminare l'utente dal database
            $stmt = $pdo->prepare("DELETE FROM utenti WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            
            // Se nessuna riga è stata eliminata, restituisce un errore
            if ($stmt->rowCount() === 0) {
                sendResponse(404, ['status' => 'error', 'message' => 'Utente non trovato'], $format);
            }
            
            // Invia la risposta di successo
            sendResponse(200, ['status' => 'success', 'message' => 'Utente eliminato'], $format);
            break;

        default:
            // Metodo non consentito
            sendResponse(405, ['status' => 'error', 'message' => 'Metodo non consentito'], $format);
    }
} catch (PDOException $e) {
    // Gestione degli errori di database
    sendResponse(500, [
        'status' => 'error',
        'message' => 'Errore del database',
        'error' => $e->getMessage()
    ], $format);
} catch (Exception $e) {
    // Gestione degli errori generali
    sendResponse(500, [
        'status' => 'error',
        'message' => 'Errore del server',
        'error' => $e->getMessage()
    ], $format);
}

// Funzione per inviare la risposta nel formato richiesto (JSON o XML)
function sendResponse($statusCode, $data, $format) {
    http_response_code($statusCode); // Imposta il codice di stato HTTP
    
    // Se il formato richiesto è XML, invia la risposta in formato XML
    if ($format === 'xml') {
        header("Content-Type: application/xml");
        echo arrayToXml($data); // Converte i dati in XML
    } else {
        // Se il formato è JSON, invia la risposta in formato JSON
        header("Content-Type: application/json");
        echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE); // Converte i dati in JSON
    }
    exit;
}

// Funzione per convertire un array in XML
function arrayToXml($data, $rootNode = 'response') {
    $xml = new SimpleXMLElement("<$rootNode/>");
    
    // Aggiunge lo status della risposta
    $xml->addChild('status', htmlspecialchars($data['status']));
    
    // Se c'è un messaggio, aggiungilo
    if (isset($data['message'])) {
        $xml->addChild('message', htmlspecialchars($data['message']));
    }
    
    // Gestisce i dati, se presenti
    if (isset($data['data'])) {
        $dataNode = $xml->addChild('data');
        if (is_array($data['data'])) {
            // Aggiunge ogni elemento dei dati
            foreach ($data['data'] as $item) {
                $userNode = $dataNode->addChild('utente');
                foreach ($item as $key => $value) {
                    $userNode->addChild($key, htmlspecialchars($value));
                }
            }
        }
    }
    
    return $xml->asXML(); // Restituisce l'XML come stringa
}

// Helper per la conversione array to XML (se necessario)
function arrayToXmlHelper($data, $xml) {
    foreach ($data as $key => $value) {
        if (is_array($value)) {
            if (is_numeric($key)) {
                $key = "item";
            }
            $subnode = $xml->addChild($key);
            arrayToXmlHelper($value, $subnode);
        } else {
            $xml->addChild($key, htmlspecialchars($value));
        }
    }
}
?>
