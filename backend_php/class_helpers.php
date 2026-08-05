<?php
/**
 * Canonical defect classes + normalization helpers for the SolarScan dashboard.
 *
 * The ml_service YOLOv8n-cls model returns exactly these 6 class strings. All
 * dashboard counting/filtering must compare against them, but stored values may
 * differ in case or separators (e.g. "Bird Drop" vs "Bird-drop"), so comparisons
 * are normalized to a case- and separator-insensitive key.
 */

const SOLAR_CLASSES = [
    'Bird-drop',
    'Clean',
    'Dusty',
    'Electrical-damage',
    'Physical-Damage',
    'Snow-Covered',
];

/**
 * Normalize a class string to a comparison key: lower-case, strip every
 * non-alphanumeric character. e.g. "Bird Drop", "Bird-drop", "BIRD_DROP" -> "birddrop".
 */
function norm_class($s)
{
    return preg_replace('/[^a-z0-9]/', '', strtolower((string)$s));
}

/**
 * SQL expression that normalizes a column/expression the same way norm_class()
 * does, so WHERE/CASE comparisons are case- and separator-insensitive.
 * e.g. sql_norm('result') compared against norm_class('Clean') ("clean").
 */
function sql_norm($expr)
{
    return "LOWER(REPLACE(REPLACE(REPLACE($expr, '-', ''), '_', ''), ' ', ''))";
}

/**
 * Per-class scan counts covering ALL 6 canonical classes, keyed by the canonical
 * class string. Case/separator-insensitive: legacy values like "Bird Drop" or
 * "PHYSICAL DAMAGE" are folded into the correct canonical bucket.
 */
function get_class_counts($pdo)
{
    $counts = array_fill_keys(SOLAR_CLASSES, 0);

    $lookup = [];
    foreach (SOLAR_CLASSES as $c) {
        $lookup[norm_class($c)] = $c;
    }

    $rows = $pdo->query("SELECT result, COUNT(*) AS c FROM scans GROUP BY result")->fetchAll();
    foreach ($rows as $row) {
        $key = norm_class($row['result']);
        if (isset($lookup[$key])) {
            $counts[$lookup[$key]] += (int)$row['c'];
        }
    }

    return $counts;
}
