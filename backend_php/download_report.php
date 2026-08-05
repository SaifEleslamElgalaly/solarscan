<?php
session_start();
require_once 'db.php';
require_once 'class_helpers.php';

if (!isset($_SESSION['user_id'])) {
    die("Unauthorized");
}

if (!isset($_GET['type'])) {
    die("Invalid report type");
}

$type = $_GET['type'];
$filename = "SolarScan-Report-" . date('Y-m-d') . ".csv";

header('Content-Type: text/csv');
header('Content-Disposition: attachment; filename="' . $filename . '"');

$output = fopen('php://output', 'w');

// Headers
fputcsv($output, ['Scan ID', 'User ID', 'Result', 'Confidence', 'Recommendation', 'Date']);

if ($type == 'full') {
    $stmt = $pdo->query("SELECT id, user_id, result, confidence, recommendation, created_at FROM scans ORDER BY created_at DESC");
} elseif ($type == 'anomalies') {
    $stmt = $pdo->query("SELECT id, user_id, result, confidence, recommendation, created_at FROM scans WHERE " . sql_norm('result') . " != 'clean' ORDER BY created_at DESC");
} else {
    $stmt = $pdo->prepare("SELECT id, user_id, result, confidence, recommendation, created_at FROM scans ORDER BY created_at DESC LIMIT 10");
    $stmt->execute();
}

while ($row = $stmt->fetch()) {
    fputcsv($output, $row);
}

fclose($output);
exit;
