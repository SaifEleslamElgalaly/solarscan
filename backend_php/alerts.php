<?php
require_once 'header.php';

// Build Filter Query
// Anything whose normalized result is not "clean" is treated as a defect/alert.
$where = [sql_norm('result') . " != 'clean'"];
$params = [];

if (isset($_GET['q']) && !empty($_GET['q'])) {
    $where[] = "(scans.result LIKE ? OR users.name LIKE ?)";
    $params[] = "%".$_GET['q']."%";
    $params[] = "%".$_GET['q']."%";
}

if (isset($_GET['priority']) && $_GET['priority'] != 'All Priorities') {
    if ($_GET['priority'] == 'High') {
        $where[] = "confidence < 0.7";
    } elseif ($_GET['priority'] == 'Medium') {
        $where[] = "confidence >= 0.7 AND confidence < 0.9";
    } elseif ($_GET['priority'] == 'Low') {
        $where[] = "confidence >= 0.9";
    }
}

if (isset($_GET['status']) && $_GET['status'] != 'All Statuses') {
    // Mock status logic
}

$where_sql = count($where) > 0 ? "WHERE " . implode(" AND ", $where) : "";

$stmt = $pdo->prepare("SELECT scans.*, users.name as user_name FROM scans JOIN users ON scans.user_id = users.id $where_sql ORDER BY scans.created_at DESC LIMIT 10");
$stmt->execute($params);
$alerts = $stmt->fetchAll();
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 1.5rem; letter-spacing: 2px;">ALERTS MANAGEMENT</h1>
    </div>
    <div class="text-end">
        <div class="orbitron fw-bold" style="color: var(--accent); font-size: 0.65rem;">SYSTEM STATUS: <span style="color: var(--accent);">OPTIMAL</span></div>
    </div>
</div>

<!-- Filters Section -->
<form method="GET" class="card p-4 mb-5" style="background: rgba(255,255,255,0.02);">
    <div class="row g-3">
        <div class="col-md-3">
            <div class="stat-label mb-2">SEARCH ALERTS</div>
            <div class="search-box w-100" style="margin-left: 0;">
                <i class="bi bi-search text-muted"></i>
                <input type="text" name="q" placeholder="Search by ID or Panel..." value="<?php echo htmlspecialchars($_GET['q'] ?? ''); ?>">
            </div>
        </div>
        <div class="col-md-2">
            <div class="stat-label mb-2">PRIORITY</div>
            <select name="priority" class="form-select bg-dark border-secondary text-white" style="font-size: 0.85rem; border: 1px solid var(--border);">
                <option>All Priorities</option>
                <option <?php echo ($_GET['priority'] ?? '') == 'High' ? 'selected' : ''; ?>>High</option>
                <option <?php echo ($_GET['priority'] ?? '') == 'Medium' ? 'selected' : ''; ?>>Medium</option>
                <option <?php echo ($_GET['priority'] ?? '') == 'Low' ? 'selected' : ''; ?>>Low</option>
            </select>
        </div>
        <div class="col-md-2">
            <div class="stat-label mb-2">STATUS</div>
            <select name="status" class="form-select bg-dark border-secondary text-white" style="font-size: 0.85rem; border: 1px solid var(--border);">
                <option>All Statuses</option>
                <option <?php echo ($_GET['status'] ?? '') == 'Pending' ? 'selected' : ''; ?>>Pending</option>
                <option <?php echo ($_GET['status'] ?? '') == 'Assigned' ? 'selected' : ''; ?>>Assigned</option>
                <option <?php echo ($_GET['status'] ?? '') == 'Resolved' ? 'selected' : ''; ?>>Resolved</option>
            </select>
        </div>
        <div class="col-md-3">
            <div class="stat-label mb-2">DATE RANGE</div>
            <div class="search-box w-100" style="margin-left: 0;">
                <input type="text" value="Oct 12 - Oct 19, 2026" readonly>
                <i class="bi bi-calendar3 text-muted ms-2"></i>
            </div>
        </div>
        <div class="col-md-2 d-flex align-items-end">
            <button type="submit" class="btn btn-accent w-100">APPLY FILTERS</button>
        </div>
    </div>
</form>

<!-- Active Findings Section -->
<div class="card p-0 mb-5">
    <div class="card-header border-0 bg-transparent py-4 px-4 d-flex justify-content-between align-items-center">
        <div class="stat-label">Active Findings</div>
        <div class="d-flex gap-2">
            <button class="btn btn-sm btn-outline-secondary border-secondary text-white" style="font-size: 0.65rem; font-weight: 700;">EXPORT CSV</button>
            <button class="btn btn-sm btn-outline-secondary border-secondary text-white" style="font-size: 0.65rem; font-weight: 700;">BULK RESOLVE</button>
        </div>
    </div>
    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>PANEL ID</th>
                    <th>ALERT TYPE</th>
                    <th>PRIORITY</th>
                    <th>TIMESTAMP</th>
                    <th class="text-end">ACTION</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($alerts as $index => $alert): ?>
                <tr>
                    <td class="text-muted" style="font-size: 0.8rem;">AL-88<?php echo 21 - $index; ?></td>
                    <td class="orbitron" style="color: var(--text-primary); font-size: 0.8rem;">PNL-XY-00<?php echo $alert['id']; ?></td>
                    <td>
                        <span class="badge rounded-circle p-1 me-2" style="background: #ff4444;"> </span>
                        Critical <?php echo $alert['result']; ?>
                    </td>
                    <td>
                        <?php 
                            if($alert['confidence'] < 0.7) echo '<span class="priority-high">HIGH</span>';
                            elseif($alert['confidence'] < 0.9) echo '<span class="priority-low" style="color: #00BFA5; border-color: #00BFA5;">MEDIUM</span>';
                            else echo '<span class="priority-low">LOW</span>';
                        ?>
                    </td>
                    <td class="text-muted" style="font-size: 0.8rem;"><?php echo $alert['created_at']; ?></td>
                    <td class="text-end">
                        <?php if($index % 2 == 0): ?>
                            <button class="btn btn-accent py-1 px-3" style="font-size: 0.65rem;">ASSIGN</button>
                        <?php else: ?>
                            <button class="btn btn-outline-accent py-1 px-3" style="font-size: 0.65rem; border: 1px solid var(--accent); color: var(--accent); background: transparent;">VIEW DETAILS</button>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <div class="card-footer border-0 bg-transparent py-4 px-4 d-flex justify-content-between align-items-center">
        <div class="text-muted" style="font-size: 0.7rem; font-weight: 700;">SHOWING 1-10 OF 1,248 DETECTIONS</div>
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
    <div class="col-md-8">
        <div class="card p-5 h-100" style="background: rgba(217, 255, 0, 0.02);">
            <div class="stat-label mb-2" style="color: var(--accent);">AI ANALYSIS ENGINE</div>
            <h3 class="fw-bold mb-4">Predictive Risk Assessment</h3>
            <p class="text-muted mb-4" style="font-size: 0.9rem; line-height: 1.6;">
                Machine learning models suggest a 14% increase in crack formation probability for Sector B due to recent thermal fluctuations. Urgent inspection of serial numbers PNL-XY-010 through 025 is recommended.
            </p>
            <button class="btn btn-outline-accent py-2 px-4" style="font-size: 0.75rem; border: 1px solid var(--accent); color: var(--accent); background: transparent; width: fit-content;">GENERATE RISK REPORT</button>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card p-4 h-100">
            <div class="stat-label mb-4">Alert Stats</div>
            
            <div class="mb-4">
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.65rem; color: var(--text-secondary); font-weight: 700;">PENDING RESOLUTION</span>
                    <span style="font-size: 0.65rem; color: var(--accent); font-weight: 700;">42%</span>
                </div>
                <div class="progress" style="height: 4px; background: rgba(255,255,255,0.05);">
                    <div class="progress-bar" style="width: 42%; background: var(--accent);"></div>
                </div>
            </div>
            
            <div class="mb-4">
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.65rem; color: var(--text-secondary); font-weight: 700;">HIGH PRIORITY DENSITY</span>
                    <span style="font-size: 0.65rem; color: #ff4444; font-weight: 700;">12%</span>
                </div>
                <div class="progress" style="height: 4px; background: rgba(255,255,255,0.05);">
                    <div class="progress-bar" style="width: 12%; background: #ff4444;"></div>
                </div>
            </div>
            
            <div class="mb-4">
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.65rem; color: var(--text-secondary); font-weight: 700;">SYSTEM RELIABILITY</span>
                    <span style="font-size: 0.65rem; color: #3b82f6; font-weight: 700;">99.8%</span>
                </div>
                <div class="progress" style="height: 4px; background: rgba(255,255,255,0.05);">
                    <div class="progress-bar" style="width: 99.8%; background: #3b82f6;"></div>
                </div>
            </div>
        </div>
    </div>
</div>


<style>
.pagination .page-link { border-radius: 4px; margin: 0 4px; }
.pagination .page-item.active .page-link { color: black; }
.btn-outline-accent:hover { background: var(--accent) !important; color: black !important; }
</style>

<?php require_once 'footer.php'; ?>
