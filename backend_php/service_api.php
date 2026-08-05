<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

// Log incoming request for debugging
$raw_data = file_get_contents('php://input');
file_put_contents('debug.log', "[" . date('Y-m-d H:i:s') . "] Raw Input: " . $raw_data . "\n", FILE_APPEND);
file_put_contents('debug.log', "[" . date('Y-m-d H:i:s') . "] Action: " . ($_GET['action'] ?? 'none') . "\n", FILE_APPEND);

require_once 'db.php';


$action = $_GET['action'] ?? '';

if ($action == 'register') {
    $data = json_decode(file_get_contents('php://input'), true);
    $name = $data['name'] ?? '';
    $email = $data['email'] ?? '';
    $password = password_hash($data['password'] ?? '', PASSWORD_DEFAULT);

    $stmt = $pdo->prepare("INSERT INTO users (name, email, password, created_at, updated_at) VALUES (?, ?, ?, NOW(), NOW())");
    try {
        $stmt->execute([$name, $email, $password]);
        $user_id = $pdo->lastInsertId();
        echo json_encode(['status' => 'success', 'user_id' => $user_id, 'access_token' => 'dummy_token_' . $user_id]);
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
}

elseif ($action == 'login') {
    $data = json_decode(file_get_contents('php://input'), true);
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        $response = [
            'status' => 'success', 
            'access_token' => 'dummy_token_' . $user['id'],
            'user' => ['id' => $user['id'], 'name' => $user['name'], 'email' => $user['email']]
        ];
        file_put_contents('debug.log', "[" . date('Y-m-d H:i:s') . "] Login Success: " . $email . "\n", FILE_APPEND);
        echo json_encode($response);
    } else {
        http_response_code(401);
        $error_msg = $user ? 'Password mismatch' : 'User not found';
        file_put_contents('debug.log', "[" . date('Y-m-d H:i:s') . "] Login Failed: " . $email . " (" . $error_msg . ")\n", FILE_APPEND);
        echo json_encode(['status' => 'error', 'message' => 'Invalid credentials']);
    }
}

elseif ($action == 'upload_scan') {
    $user_id = $_POST['user_id'] ?? 1; // Simplified auth for demo
    if (!isset($_FILES['image'])) {
        echo json_encode(['status' => 'error', 'message' => 'No image uploaded']);
        exit;
    }

    $image = $_FILES['image'];
    $filename = time() . '_' . $image['name'];
    $target_path = 'uploads/' . $filename;
    move_uploaded_file($image['tmp_name'], $target_path);

    // Call ML Service
    $ml_service_url = 'http://127.0.0.1:8000/predict';
    $ch = curl_init();
    $cfile = new CURLFile(realpath($target_path), $image['type'], $image['name']);
    
    curl_setopt($ch, CURLOPT_URL, $ml_service_url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, ['file' => $cfile]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    $ml_result = json_decode($response, true);
    curl_close($ch);

    if ($ml_result) {
        $panel_id = $_POST['panel_id'] ?? null;
        // Persist the defect bounding box (normalized [x1,y1,x2,y2]) as JSON, or NULL if none.
        $box_json = isset($ml_result['box']) && $ml_result['box'] !== null
            ? json_encode($ml_result['box'])
            : null;
        $stmt = $pdo->prepare("INSERT INTO scans (user_id, panel_id, image_path, result, confidence, recommendation, box, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())");
        $stmt->execute([
            $user_id,
            $panel_id,
            $target_path,
            $ml_result['class'],
            $ml_result['confidence'],
            $ml_result['recommendation'],
            $box_json
        ]);
        
        $scan_id = $pdo->lastInsertId();
        echo json_encode([
            'id' => $scan_id,
            'image_path' => $target_path,
            'result' => $ml_result['class'],
            'confidence' => $ml_result['confidence'],
            'recommendation' => $ml_result['recommendation'],
            'box' => $ml_result['box'] ?? null,
            'created_at' => date('Y-m-d H:i:s')
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'ML Service unreachable']);
    }
}

elseif ($action == 'get_history') {
    $user_id = $_GET['user_id'] ?? 1;
    $stmt = $pdo->prepare("SELECT * FROM scans WHERE user_id = ? ORDER BY created_at DESC");
    $stmt->execute([$user_id]);
    $scans = $stmt->fetchAll();
    // Decode the stored box JSON so history returns the same shape as upload_scan (array or null).
    foreach ($scans as &$scan) {
        $scan['box'] = isset($scan['box']) && $scan['box'] !== null
            ? json_decode($scan['box'], true)
            : null;
    }
    unset($scan);
    echo json_encode($scans);
}

elseif ($action == 'retrain') {
    $ml_service_url = 'http://127.0.0.1:8000/retrain';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $ml_service_url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    echo $response ?: json_encode(['status' => 'error', 'message' => 'ML Service unreachable']);
}

else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
}
?>
