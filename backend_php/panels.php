<?php
require_once 'header.php';

// Handle Registration
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['register_panel'])) {
    $p_id = $_POST['panel_id'];
    $loc = $_POST['location'];
    $mod = $_POST['model'];
    
    $stmt = $pdo->prepare("INSERT INTO panels (panel_id, location, model) VALUES (?, ?, ?)");
    try {
        $stmt->execute([$p_id, $loc, $mod]);
        $success = "Panel registered successfully!";
    } catch (Exception $e) {
        $error = "Error: " . $e->getMessage();
    }
}

// Fetch Statistics
$stmt = $pdo->query("SELECT COUNT(*) as total FROM panels");
$total_panels = $stmt->fetch()['total'];

$stmt = $pdo->query("SELECT COUNT(*) as total FROM panels WHERE status = 'Optimal'");
$online_panels = $stmt->fetch()['total'];

$offline_panels = $total_panels - $online_panels;

// Fetch Panels (Real data from panels table with joined scan data)
$stmt = $pdo->query("
    SELECT p.*, s.result as last_result, s.confidence as last_confidence, s.created_at as last_scan_date
    FROM panels p
    LEFT JOIN (
        SELECT panel_id, result, confidence, created_at
        FROM scans
        WHERE id IN (SELECT MAX(id) FROM scans GROUP BY panel_id)
    ) s ON p.panel_id = s.panel_id
    ORDER BY p.created_at DESC
");
$panels = $stmt->fetchAll();

// If no panels, show mock data for demo but still keep the dynamic structure
if (empty($panels)) {
    $panels = [
        ['panel_id' => 'PX-7420-A', 'location' => 'Sector 4, North-West', 'model' => 'SunPower X-Series', 'status' => 'Optimal', 'last_confidence' => 0.98, 'last_scan_date' => date('Y-m-d H:i:s')],
        ['panel_id' => 'PX-7421-B', 'location' => 'Sector 2, South Array', 'model' => 'LG NeON R', 'status' => 'Needs Cleaning', 'last_confidence' => 0.74, 'last_scan_date' => date('Y-m-d H:i:s')],
    ];
}
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 1.5rem; letter-spacing: 2px;">SOLAR PANEL INVENTORY</h1>
    </div>
</div>

<?php if (isset($success)): ?>
    <div class="alert alert-success bg-accent text-black border-0 fw-bold mb-4"><?php echo $success; ?></div>
<?php endif; ?>
<?php if (isset($error)): ?>
    <div class="alert alert-danger bg-danger text-white border-0 fw-bold mb-4"><?php echo $error; ?></div>
<?php endif; ?>

<!-- Summary Stats -->
<div class="row g-4 mb-5">
    <div class="col-md-4">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">TOTAL PANELS</div>
                    <div class="stat-value"><?php echo number_format($total_panels); ?></div>
                    <div style="font-size: 0.65rem; color: var(--text-secondary); font-weight: 700;">INVENTORY COUNT</div>
                </div>
                <i class="bi bi-solar-panel fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">ONLINE STATUS</div>
                    <div class="stat-value"><?php echo number_format($online_panels); ?></div>
                    <div style="font-size: 0.65rem; color: var(--accent); font-weight: 700;">
                        <span class="badge rounded-circle p-1 me-1" style="background: var(--accent);"> </span>
                        <?php echo $total_panels > 0 ? round(($online_panels / $total_panels) * 100, 1) : 0; ?>% UPTIME
                    </div>
                </div>
                <i class="bi bi-cloud-check fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">SYSTEM OFFLINE</div>
                    <div class="stat-value" style="color: #ff4444;"><?php echo $offline_panels; ?></div>
                    <div style="font-size: 0.65rem; color: #ff4444; font-weight: 700;">ATTENTION REQUIRED</div>
                </div>
                <i class="bi bi-exclamation-triangle fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
</div>

<!-- Filters Bar -->
<div class="row g-3 mb-4">
    <div class="col-md-4">
        <div class="search-box w-100" style="margin-left: 0;">
            <i class="bi bi-search text-muted"></i>
            <input type="text" placeholder="Search by Panel ID or Location...">
        </div>
    </div>
    <div class="col-md-2">
        <select class="form-select bg-dark border-secondary text-white" style="font-size: 0.85rem; border: 1px solid var(--border);">
            <option>All Sectors</option>
            <option>Sector 1</option>
            <option>Sector 2</option>
        </select>
    </div>
    <div class="col-md-2">
        <select class="form-select bg-dark border-secondary text-white" style="font-size: 0.85rem; border: 1px solid var(--border);">
            <option>All Status</option>
            <option>Optimal</option>
            <option>Critical</option>
        </select>
    </div>
    <div class="col-md-2">
        <button class="btn btn-outline-secondary border-secondary text-white w-100" style="font-size: 0.75rem; font-weight: 700;">
            <i class="bi bi-download me-2"></i> EXPORT
        </button>
    </div>
    <div class="col-md-2">
        <button class="btn btn-accent w-100" style="font-size: 0.75rem;" data-bs-toggle="modal" data-bs-target="#registerModal">+ REGISTER NEW PANEL</button>
    </div>
</div>

<!-- Panels Table -->
<div class="card p-0 mb-5">
    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th class="ps-4">PANEL ID</th>
                    <th>LOCATION</th>
                    <th>MODEL</th>
                    <th>LAST SCAN</th>
                    <th>EFFICIENCY</th>
                    <th>STATUS</th>
                    <th class="text-end pe-4">ACTION</th>
                </tr>
            </thead>
            <tbody>
                <?php 
                foreach ($panels as $index => $panel): 
                    $eff = isset($panel['last_confidence']) ? round($panel['last_confidence'] * 100) : 100;
                    $status = $panel['status'] ?? 'Optimal';
                    if (isset($panel['last_result']) && norm_class($panel['last_result']) !== 'clean') {
                        $nc = norm_class($panel['last_result']);
                        $status = ($nc === norm_class('Bird-drop') || $nc === norm_class('Physical-Damage')) ? 'Critical' : 'Needs Cleaning';
                    }
                    $color = ($eff > 85) ? 'var(--accent)' : (($eff > 60) ? '#ffaa00' : '#ff4444');
                ?>
                <tr>
                    <td class="ps-4 py-4">
                        <div class="d-flex align-items-center">
                            <div class="p-2 rounded bg-dark border border-secondary me-3">
                                <i class="bi bi-cpu-fill" style="color: <?php echo $color; ?>;"></i>
                            </div>
                            <span class="orbitron fw-bold" style="font-size: 0.85rem;"><?php echo htmlspecialchars($panel['panel_id']); ?></span>
                        </div>
                    </td>
                    <td class="text-muted" style="font-size: 0.8rem;"><?php echo htmlspecialchars($panel['location']); ?></td>
                    <td class="text-muted" style="font-size: 0.8rem;"><?php echo htmlspecialchars($panel['model']); ?></td>
                    <td class="text-muted" style="font-size: 0.8rem;">
                        <?php if (isset($panel['last_scan_date'])): ?>
                            <?php echo date('Y-m-d', strtotime($panel['last_scan_date'])); ?><br>
                            <span style="font-size: 0.7rem; opacity: 0.5;"><?php echo date('H:i', strtotime($panel['last_scan_date'])); ?></span>
                        <?php else: ?>
                            N/A
                        <?php endif; ?>
                    </td>
                    <td>
                        <div class="d-flex align-items-center" style="width: 150px;">
                            <div class="progress flex-grow-1" style="height: 4px; background: rgba(255,255,255,0.05);">
                                <div class="progress-bar" style="width: <?php echo $eff; ?>%; background: <?php echo $color; ?>;"></div>
                            </div>
                            <span class="ms-3 orbitron fw-bold" style="font-size: 0.7rem; color: <?php echo $color; ?>;"><?php echo $eff; ?>%</span>
                        </div>
                    </td>
                    <td>
                        <span class="badge py-2 px-3 fw-bold" style="font-size: 0.6rem; background: rgba(<?php echo $color == 'var(--accent)' ? '217, 255, 0' : '255, 68, 68'; ?>, 0.05); color: <?php echo $color; ?>; border: 1px solid <?php echo $color; ?>33;">
                            <?php echo strtoupper($status); ?>
                        </span>
                    </td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-icon text-muted"><i class="bi bi-three-dots-vertical"></i></button>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <div class="card-footer border-0 bg-transparent py-4 px-4 d-flex justify-content-between align-items-center">
        <div class="text-muted" style="font-size: 0.7rem; font-weight: 700;">SHOWING <?php echo count($panels); ?> OF <?php echo $total_panels; ?> PANELS</div>
        <nav>
            <ul class="pagination pagination-sm mb-0">
                <li class="page-item"><a class="page-link bg-dark border-secondary text-white" href="#"><i class="bi bi-chevron-left"></i></a></li>
                <li class="page-item active"><a class="page-link bg-accent border-accent text-black" href="#">1</a></li>
                <li class="page-item"><a class="page-link bg-dark border-secondary text-white" href="#">2</a></li>
                <li class="page-item"><a class="page-link bg-dark border-secondary text-white" href="#">3</a></li>
                <li class="page-item"><a class="page-link bg-dark border-secondary text-white" href="#"><i class="bi bi-chevron-right"></i></a></li>
            </ul>
        </nav>
    </div>
</div>

<div class="row g-4">
    <!-- AI Recommendation -->
    <div class="col-md-7">
        <div class="card p-0 overflow-hidden h-100" style="position: relative; min-height: 300px;">
            <img src="assets/images/drone_cleaning.png" style="width: 100%; height: 100%; object-fit: cover; opacity: 0.6;">
            <div style="position: absolute; bottom: 30px; left: 30px; right: 30px; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); padding: 20px; border: 1px solid var(--accent); border-radius: 12px;">
                <div class="stat-label mb-2" style="color: var(--accent);">AI RECOMMENDATION</div>
                <p class="mb-0" style="font-size: 0.85rem; font-weight: 500;">Scheduled drone cleaning for Sector 2 tomorrow at 05:00 AM to restore 15% lost efficiency.</p>
            </div>
        </div>
    </div>
    
    <!-- Location Map -->
    <div class="col-md-5">
        <div class="card p-4 h-100">
            <div class="stat-label mb-3">Inventory Location Map</div>
            <div class="mb-4 rounded overflow-hidden position-relative">
                <img src="assets/images/panel_map.png" style="width: 100%; height: 180px; object-fit: cover;">
                <div class="position-absolute" style="top: 50%; left: 50%; width: 12px; height: 12px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 10px var(--accent); transform: translate(-50%, -50%);"></div>
                <div class="position-absolute bottom-0 start-0 p-2" style="background: rgba(0,0,0,0.7); font-size: 0.5rem; color: var(--accent); font-weight: 700; letter-spacing: 1px;">LAT: 34.0522° N | LNG: 118.2437° W</div>
            </div>
            <div class="d-flex justify-content-between align-items-center mt-auto">
                <div>
                    <h6 class="mb-1 fw-bold">Central Hub: North Field</h6>
                    <small class="text-muted" style="font-size: 0.7rem;">Cluster Alpha - Processing Active</small>
                </div>
                <a href="#" class="orbitron text-accent text-decoration-none fw-bold" style="font-size: 0.65rem; letter-spacing: 1px;">VIEW FULL MAP</a>
            </div>
        </div>
    </div>
</div>

<!-- Registration Modal -->
<div class="modal fade" id="registerModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content bg-dark border-secondary" style="border-radius: 20px;">
            <div class="modal-header border-0 p-4 pb-0">
                <h5 class="orbitron fw-bold text-accent">REGISTER NEW PANEL</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4">
                <form method="POST">
                    <div class="mb-4">
                        <label class="stat-label mb-2">PANEL SERIAL ID</label>
                        <div class="search-box w-100" style="margin-left: 0;">
                            <i class="bi bi-hash text-muted"></i>
                            <input type="text" name="panel_id" placeholder="PX-XXXX-X" required>
                        </div>
                    </div>
                    <div class="mb-4">
                        <label class="stat-label mb-2">DEPLOYMENT LOCATION</label>
                        <div class="search-box w-100" style="margin-left: 0;">
                            <i class="bi bi-geo-alt text-muted"></i>
                            <input type="text" name="location" placeholder="Sector / Grid Coordinates" required>
                        </div>
                    </div>
                    <div class="mb-4">
                        <label class="stat-label mb-2">HARDWARE MODEL</label>
                        <div class="search-box w-100" style="margin-left: 0;">
                            <i class="bi bi-cpu text-muted"></i>
                            <input type="text" name="model" placeholder="Manufacturer & Series" required>
                        </div>
                    </div>
                    <button type="submit" name="register_panel" class="btn btn-accent w-100 py-3 orbitron fw-bold mt-2" style="letter-spacing: 2px;">
                        CONFIRM REGISTRATION
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>

<style>
.modal-content {
    background: #0A0A0A !important;
    box-shadow: 0 0 30px rgba(217, 255, 0, 0.1);
}
.modal-backdrop.show { opacity: 0.8; background-color: #000; }
</style>

<?php require_once 'footer.php'; ?>
