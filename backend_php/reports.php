<?php
require_once 'header.php';
require_once 'db.php';

// Fetch distribution data (case/separator-insensitive, covers all 6 model classes)
$counts = get_class_counts($pdo);
$total_scans = array_sum($counts);

$crack_percent = $total_scans > 0 ? round(($counts['Physical-Damage'] / $total_scans) * 100) : 0;
$dust_percent = $total_scans > 0 ? round(($counts['Dusty'] / $total_scans) * 100) : 0;
$bird_percent = $total_scans > 0 ? round(($counts['Bird-drop'] / $total_scans) * 100) : 0;
$clean_percent = $total_scans > 0 ? round(($counts['Clean'] / $total_scans) * 100) : 0;

// Fetch trend data (last 7 days)
$trend_data = [];
$trend_labels = [];
for ($i = 6; $i >= 0; $i--) {
    $date = date('Y-m-d', strtotime("-$i days"));
    $display_date = date('M d', strtotime($date));
    $stmt = $pdo->prepare("SELECT count(*) as total, SUM(CASE WHEN " . sql_norm('result') . " = 'clean' THEN 1 ELSE 0 END) as clean FROM scans WHERE DATE(created_at) = ?");
    $stmt->execute([$date]);
    $res = $stmt->fetch();
    
    $efficiency = $res['total'] > 0 ? round(($res['clean'] / $res['total']) * 100) : 100; // Default to 100 if no scans
    $trend_data[] = $efficiency;
    $trend_labels[] = $display_date;
}
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 1.5rem; letter-spacing: 2px;">ANALYTICAL REPORTS</h1>
        <p class="text-muted fw-bold mb-0" style="font-size: 0.8rem;">Generate and export multi-dimensional performance audits.</p>
    </div>
    <div class="search-box" style="width: 200px; margin-left: 0;">
        <i class="bi bi-calendar3 text-muted"></i>
        <input type="text" value="Last 30 Days" readonly>
    </div>
</div>

<div class="row g-4 mb-5">
    <!-- Main Performance Chart -->
    <div class="col-md-8">
        <div class="card p-4 h-100">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div class="stat-label">FLEET PERFORMANCE TREND</div>
                <div class="badge bg-dark border border-secondary text-accent">LIVE DATA</div>
            </div>
            <canvas id="performanceChart" height="250"></canvas>
        </div>
    </div>
    
    <!-- Distribution Chart -->
    <div class="col-md-4">
        <div class="card p-4 h-100">
            <div class="stat-label mb-4">ANOMALY DISTRIBUTION</div>
            <canvas id="anomalyChart"></canvas>
            <div class="mt-4">
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.7rem; color: var(--text-secondary);">PHYSICAL DAMAGE</span>
                    <span style="font-size: 0.7rem; color: #ff4444; font-weight: 700;"><?php echo $crack_percent; ?>%</span>
                </div>
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.7rem; color: var(--text-secondary);">DUST ACCUMULATION</span>
                    <span style="font-size: 0.7rem; color: #3b82f6; font-weight: 700;"><?php echo $dust_percent; ?>%</span>
                </div>
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.7rem; color: var(--text-secondary);">BIRD DROPS</span>
                    <span style="font-size: 0.7rem; color: #fbbf24; font-weight: 700;"><?php echo $bird_percent; ?>%</span>
                </div>
                <div class="d-flex justify-content-between">
                    <span style="font-size: 0.7rem; color: var(--text-secondary);">OPTIMAL (CLEAN)</span>
                    <span style="font-size: 0.7rem; color: var(--accent); font-weight: 700;"><?php echo $clean_percent; ?>%</span>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="card p-0 mb-5">
    <div class="card-header border-0 bg-transparent py-4 px-4">
        <div class="stat-label">GENERATED REPORT ARCHIVE</div>
    </div>
    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th class="ps-4">REPORT NAME</th>
                    <th>GENERATED ON</th>
                    <th>TYPE</th>
                    <th>STATUS</th>
                    <th class="text-end pe-4">ACTION</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="ps-4 py-3"><i class="bi bi-file-earmark-spreadsheet text-accent me-2"></i> Full-System-Scan-Archive.csv</td>
                    <td class="text-muted" style="font-size: 0.8rem;"><?php echo date('M d, Y - H:i'); ?></td>
                    <td class="text-muted" style="font-size: 0.8rem;">Performance Audit</td>
                    <td><span class="badge bg-success-subtle text-success px-3 py-2 border border-success-subtle">READY</span></td>
                    <td class="text-end pe-4"><a href="download_report.php?type=full" class="btn btn-sm btn-icon text-muted"><i class="bi bi-download"></i></a></td>
                </tr>
                <tr>
                    <td class="ps-4 py-3"><i class="bi bi-file-earmark-spreadsheet text-danger me-2"></i> Anomaly-Diagnostic-Log.csv</td>
                    <td class="text-muted" style="font-size: 0.8rem;"><?php echo date('M d, Y - H:i', strtotime('-1 day')); ?></td>
                    <td class="text-muted" style="font-size: 0.8rem;">Diagnostic Log</td>
                    <td><span class="badge bg-success-subtle text-success px-3 py-2 border border-success-subtle">READY</span></td>
                    <td class="text-end pe-4"><a href="download_report.php?type=anomalies" class="btn btn-sm btn-icon text-muted"><i class="bi bi-download"></i></a></td>
                </tr>
                <tr>
                    <td class="ps-4 py-3"><i class="bi bi-file-earmark-spreadsheet text-info me-2"></i> Latest-10-Scans.csv</td>
                    <td class="text-muted" style="font-size: 0.8rem;"><?php echo date('M d, Y - H:i', strtotime('-1 hour')); ?></td>
                    <td class="text-muted" style="font-size: 0.8rem;">Recent Activity</td>
                    <td><span class="badge bg-success-subtle text-success px-3 py-2 border border-success-subtle">READY</span></td>
                    <td class="text-end pe-4"><a href="download_report.php?type=recent" class="btn btn-sm btn-icon text-muted"><i class="bi bi-download"></i></a></td>
                </tr>
            </tbody>
        </table>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
const perfCtx = document.getElementById('performanceChart').getContext('2d');
new Chart(perfCtx, {
    type: 'line',
    data: {
        labels: <?php echo json_encode($trend_labels); ?>,
        datasets: [{
            label: 'Efficiency %',
            data: <?php echo json_encode($trend_data); ?>,
            borderColor: '#D9FF00',
            backgroundColor: 'rgba(217, 255, 0, 0.1)',
            fill: true,
            tension: 0.4
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
            y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#94a3b8' } },
            x: { grid: { display: false }, ticks: { color: '#94a3b8' } }
        }
    }
});

const anomalyCtx = document.getElementById('anomalyChart').getContext('2d');
new Chart(anomalyCtx, {
    type: 'doughnut',
    data: {
        labels: ['Physical-Damage', 'Dusty', 'Bird-drop', 'Clean', 'Electrical-damage', 'Snow-Covered'],
        datasets: [{
            data: [<?php echo $counts['Physical-Damage']; ?>, <?php echo $counts['Dusty']; ?>, <?php echo $counts['Bird-drop']; ?>, <?php echo $counts['Clean']; ?>, <?php echo $counts['Electrical-damage']; ?>, <?php echo $counts['Snow-Covered']; ?>],
            backgroundColor: ['#ff4444', '#3b82f6', '#fbbf24', '#D9FF00', '#a855f7', '#22d3ee'],
            borderWidth: 0,
            hoverOffset: 10
        }]
    },
    options: {
        cutout: '80%',
        responsive: true,
        plugins: { legend: { display: false } }
    }
});
</script>

<?php require_once 'footer.php'; ?>
