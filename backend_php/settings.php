<?php
require_once 'header.php';
require_once 'db.php';

$message = '';

// Handle Save Settings
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['save_settings'])) {
    $admin_name = $_POST['admin_name'] ?? '';
    $admin_email = $_POST['admin_email'] ?? '';
    $ml_endpoint = $_POST['ml_endpoint'] ?? '';
    $api_token = $_POST['api_token'] ?? '';
    $auto_audit = isset($_POST['auto_audit']) ? 1 : 0;
    $high_contrast = isset($_POST['high_contrast']) ? 1 : 0;
    $notifications = isset($_POST['notifications']) ? 1 : 0;

    $stmt = $pdo->prepare("UPDATE settings SET 
        admin_name = ?, 
        admin_email = ?, 
        ml_endpoint = ?, 
        api_token = ?, 
        auto_audit = ?, 
        high_contrast = ?, 
        notifications = ? 
        WHERE id = 1");
    
    try {
        $stmt->execute([$admin_name, $admin_email, $ml_endpoint, $api_token, $auto_audit, $high_contrast, $notifications]);
        $message = "Configuration updated successfully!";
    } catch (Exception $e) {
        $message = "Error saving settings: " . $e->getMessage();
    }
}

// Fetch Current Settings
$stmt = $pdo->query("SELECT * FROM settings WHERE id = 1");
$settings = $stmt->fetch();

if (!$settings) {
    // Fallback if somehow deleted
    $settings = [
        'admin_name' => 'System Admin',
        'admin_email' => 'admin@solarscan.ai',
        'ml_endpoint' => 'http://localhost:8000/predict',
        'api_token' => '',
        'auto_audit' => 1,
        'high_contrast' => 1,
        'notifications' => 1
    ];
}
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 1.5rem; letter-spacing: 2px;">SYSTEM SETTINGS</h1>
        <p class="text-muted fw-bold mb-0" style="font-size: 0.8rem;">Configure platform parameters and security protocols.</p>
    </div>
    <button type="submit" form="settingsForm" name="save_settings" class="btn btn-accent px-5 py-2 orbitron fw-bold" style="letter-spacing: 1px;">SAVE CHANGES</button>
</div>

<?php if ($message): ?>
    <div class="alert alert-success bg-accent text-black border-0 fw-bold mb-4"><?php echo $message; ?></div>
<?php endif; ?>

<form id="settingsForm" method="POST" class="row g-4 mb-5">
    <input type="hidden" name="save_settings" value="1">
    <!-- Account Settings -->
    <div class="col-md-6">
        <div class="card p-5 h-100">
            <div class="d-flex align-items-center mb-4">
                <i class="bi bi-person-circle text-accent fs-4 me-3"></i>
                <h5 class="fw-bold mb-0">ADMINISTRATOR IDENTITY</h5>
            </div>
            <div class="mb-4">
                <label class="stat-label mb-2">DISPLAY NAME</label>
                <div class="search-box w-100" style="margin-left: 0;">
                    <i class="bi bi-person text-muted"></i>
                    <input type="text" name="admin_name" value="<?php echo htmlspecialchars($settings['admin_name']); ?>" required>
                </div>
            </div>
            <div class="mb-4">
                <label class="stat-label mb-2">EMAIL ADDRESS</label>
                <div class="search-box w-100" style="margin-left: 0;">
                    <i class="bi bi-envelope text-muted"></i>
                    <input type="email" name="admin_email" value="<?php echo htmlspecialchars($settings['admin_email']); ?>" required>
                </div>
            </div>
            <button type="button" class="btn btn-outline-secondary border-secondary text-white w-100 py-2" style="font-size: 0.75rem; font-weight: 700;">UPDATE PASSWORD</button>
        </div>
    </div>
    
    <!-- API Settings -->
    <div class="col-md-6">
        <div class="card p-5 h-100">
            <div class="d-flex align-items-center mb-4">
                <i class="bi bi-cpu-fill text-accent fs-4 me-3"></i>
                <h5 class="fw-bold mb-0">CORE AI INTEGRATION</h5>
            </div>
            <div class="mb-4">
                <label class="stat-label mb-2">ML SERVICE ENDPOINT</label>
                <div class="search-box w-100" style="margin-left: 0;">
                    <i class="bi bi-link-45deg text-muted"></i>
                    <input type="text" name="ml_endpoint" value="<?php echo htmlspecialchars($settings['ml_endpoint']); ?>" required>
                </div>
            </div>
            <div class="mb-4">
                <label class="stat-label mb-2">API AUTHENTICATION TOKEN</label>
                <div class="search-box w-100" style="margin-left: 0;">
                    <i class="bi bi-shield-lock text-muted"></i>
                    <input type="password" name="api_token" value="<?php echo htmlspecialchars($settings['api_token']); ?>" required>
                </div>
            </div>
            <div class="d-flex align-items-center gap-2 mt-2">
                <span class="badge rounded-circle p-1" style="background: var(--accent);"> </span>
                <small class="text-muted" style="font-size: 0.7rem;">Connection established with AI Cluster.</small>
            </div>
        </div>
    </div>
    
    <!-- Preferences -->
    <div class="col-md-12">
        <div class="card p-5">
            <div class="d-flex align-items-center mb-4">
                <i class="bi bi-sliders text-accent fs-4 me-3"></i>
                <h5 class="fw-bold mb-0">PLATFORM PREFERENCES</h5>
            </div>
            <div class="row g-5">
                <div class="col-md-4">
                    <div class="form-check form-switch mb-3">
                        <input class="form-check-input bg-dark border-secondary" type="checkbox" name="auto_audit" id="autoAudit" <?php echo $settings['auto_audit'] ? 'checked' : ''; ?>>
                        <label class="form-check-label ms-2 fw-bold" for="autoAudit" style="font-size: 0.85rem;">AUTOMATED NIGHTLY AUDIT</label>
                    </div>
                    <small class="text-muted d-block" style="font-size: 0.7rem; margin-top: -8px;">Scan all sectors automatically at 02:00 UTC.</small>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch mb-3">
                        <input class="form-check-input bg-dark border-secondary" type="checkbox" name="high_contrast" id="highContrast" <?php echo $settings['high_contrast'] ? 'checked' : ''; ?>>
                        <label class="form-check-label ms-2 fw-bold" for="highContrast" style="font-size: 0.85rem;">NEON HIGH-CONTRAST MODE</label>
                    </div>
                    <small class="text-muted d-block" style="font-size: 0.7rem; margin-top: -8px;">Enhance neon lime visibility for night operation.</small>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch mb-3">
                        <input class="form-check-input bg-dark border-secondary" type="checkbox" name="notifications" id="notifications" <?php echo $settings['notifications'] ? 'checked' : ''; ?>>
                        <label class="form-check-label ms-2 fw-bold" for="notifications" style="font-size: 0.85rem;">REAL-TIME CRITICAL ALERTS</label>
                    </div>
                    <small class="text-muted d-block" style="font-size: 0.7rem; margin-top: -8px;">Push notifications for detected panel anomalies.</small>
                </div>
            </div>
        </div>
    </div>
</form>


<?php require_once 'footer.php'; ?>
