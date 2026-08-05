<?php
require_once 'header.php';

// Fetch Statistics (case/separator-insensitive, covers all 6 model classes)
$class_counts     = get_class_counts($pdo);
$count_clean      = $class_counts['Clean'];
$count_dusty      = $class_counts['Dusty'];
$count_bird_drop  = $class_counts['Bird-drop'];
$count_electrical = $class_counts['Electrical-damage'];
$count_physical   = $class_counts['Physical-Damage'];
$count_snow       = $class_counts['Snow-Covered'];

$total_relevant = array_sum($class_counts);
$efficiency = $total_relevant > 0 ? round(($count_clean / $total_relevant) * 100, 1) : 0;

$stmt = $pdo->query("SELECT AVG(confidence) as avg_conf FROM scans");
$avg_confidence = round(($stmt->fetch()['avg_conf'] ?? 0) * 100, 1);

// Training Status Parser
$training_status = "IDLE";
$training_info = "AI ENGINE READY FOR INFERENCE";
$training_progress = 0;
$log_path = '../ml_resnet/train_log.txt';

if (file_exists($log_path)) {
    $log_content = shell_exec('powershell -Command "Get-Content ' . realpath($log_path) . ' -Tail 5"');
    if ($log_content) {
        // Look for epoch line like " 21/100 "
        if (preg_match('/(\d+)\/(\d+).+?(\d+)%.+?<([\d:]+)/', $log_content, $matches)) {
            $training_status = "TRAINING";
            $current_epoch = $matches[1];
            $total_epochs = 50; // Forced to 50 as requested by user
            $epoch_progress = $matches[3];
            $eta = $matches[4];
            $training_info = "EPOCH $current_epoch/$total_epochs - ETA: $eta";
            $training_progress = round(($current_epoch / $total_epochs) * 100);
        }
    }
}

// Fetch Latest Scans
$stmt = $pdo->query("SELECT scans.*, users.name as user_name FROM scans JOIN users ON scans.user_id = users.id ORDER BY scans.created_at DESC LIMIT 5");
$latest_scans = $stmt->fetchAll();
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 2rem; letter-spacing: 2px;">OVERVIEW</h1>
        <p class="text-muted fw-bold mb-0" style="font-size: 0.75rem; letter-spacing: 1px;">REAL-TIME TELEMETRY & DIAGNOSTICS</p>
    </div>
</div>

<!-- Summary Cards -->
<div class="row g-4 mb-5">
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">CLEAN</div>
                    <div class="stat-value"><?php echo number_format($count_clean); ?></div>
                    <div style="font-size: 0.65rem; color: var(--accent); font-weight: 700;">OPTIMAL PERFORMANCE</div>
                </div>
                <i class="bi bi-sun-fill fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">DUSTY</div>
                    <div class="stat-value"><?php echo number_format($count_dusty); ?></div>
                    <div style="font-size: 0.65rem; color: #ffaa00; font-weight: 700;">CLEANING RECOMMENDED</div>
                </div>
                <i class="bi bi-cloud-haze2-fill fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">BIRD DROP</div>
                    <div class="stat-value"><?php echo number_format($count_bird_drop); ?></div>
                    <div style="font-size: 0.65rem; color: #ff4444; font-weight: 700;">URGENT ACTION REQUIRED</div>
                </div>
                <i class="bi bi-exclamation-octagon-fill fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card p-4" style="border: 2px solid var(--accent); background: rgba(217, 255, 0, 0.05);">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2" style="color: var(--accent);">EFFICIENCY</div>
                    <div class="stat-value"><?php echo $efficiency; ?>%</div>
                    <div class="progress mt-2" style="height: 4px; background: rgba(255,255,255,0.05);">
                        <div class="progress-bar" style="width: <?php echo $efficiency; ?>%; background: var(--accent);"></div>
                    </div>
                </div>
                <i class="bi bi-lightning-charge-fill fs-3" style="color: var(--accent);"></i>
            </div>
        </div>
    </div>
</div>

<div class="row g-4 mb-5">
    <!-- Production Chart -->
    <div class="col-md-8">
        <div class="card p-4 h-100">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div class="stat-label"><i class="bi bi-graph-up text-accent me-2"></i> SYSTEM DIAGNOSTICS COMPARISON</div>
                <div class="d-flex" style="font-size: 0.6rem; font-weight: 700;">
                    <div class="me-3"><span class="badge rounded-circle p-1 me-1" style="background: var(--accent);"> </span> TOTAL DETECTIONS</div>
                </div>
            </div>
            <canvas id="productionChart" height="280"></canvas>
        </div>
    </div>
    
    <!-- Asset Integrity -->
    <div class="col-md-4">
        <div class="card p-4 h-100">
            <div class="stat-label mb-4">ASSET INTEGRITY</div>
            <div class="d-flex justify-content-center align-items-center mb-4" style="position: relative;">
                <canvas id="integrityChart" width="180" height="180"></canvas>
                <div style="position: absolute; text-align: center;">
                    <div class="orbitron fw-bold mb-0" style="font-size: 2rem;"><?php echo round($efficiency); ?>%</div>
                    <div style="font-size: 0.6rem; color: var(--text-secondary); font-weight: 700;">OPTIMAL</div>
                </div>
            </div>
            <div class="mt-auto">
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.75rem; color: var(--text-secondary);">CLEAN/OPTIMAL</span>
                    <span style="font-size: 0.75rem; color: var(--accent); font-weight: 700;"><?php echo $count_clean; ?> units</span>
                </div>
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.75rem; color: var(--text-secondary);">BIRD DROP</span>
                    <span style="font-size: 0.75rem; color: #ff4444; font-weight: 700;"><?php echo $count_bird_drop; ?> units</span>
                </div>
                <div class="d-flex justify-content-between">
                    <span style="font-size: 0.75rem; color: var(--text-secondary);">NEEDS CLEANING</span>
                    <span style="font-size: 0.75rem; color: #3b82f6; font-weight: 700;"><?php echo $count_dusty; ?> units</span>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row g-4">
    <!-- Table Section -->
    <div class="col-md-8">
        <div class="card p-0">
            <div class="card-header border-0 bg-transparent py-4 px-4 d-flex justify-content-between align-items-center">
                <div class="stat-label">RECENT AI DIAGNOSTICS</div>
                <div class="text-muted" style="font-size: 0.6rem;">LAST UPDATED: 2M AGO</div>
            </div>
            <div class="table-responsive">
                <table class="table mb-0">
                    <thead>
                        <tr>
                            <th>PANEL ID</th>
                            <th>LOCATION</th>
                            <th>DETECTION</th>
                            <th>PRIORITY</th>
                            <th class="text-end">ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($latest_scans as $scan): ?>
                        <tr>
                            <td class="orbitron" style="color: var(--accent); font-size: 0.8rem;">PV-9042-<?php echo strtoupper(substr(md5($scan['id']), 0, 1)); ?></td>
                            <td class="text-muted">Sector-B / Row <?php echo $scan['id'] + 10; ?></td>
                            <td>
                                <?php 
                                    $dot_color = '#D9FF00';
                                    if(norm_class($scan['result']) !== 'clean') $dot_color = '#ff4444';
                                ?>
                                <span class="badge rounded-circle p-1 me-2" style="background: <?php echo $dot_color; ?>;"> </span>
                                <?php echo $scan['result']; ?>
                            </td>
                            <td>
                                <?php if(norm_class($scan['result']) === 'clean'): ?>
                                    <span class="priority-low">LOW</span>
                                <?php else: ?>
                                    <span class="priority-high">HIGH</span>
                                <?php endif; ?>
                            </td>
                            <td class="text-end">
                                <a href="<?php echo $scan['image_path']; ?>" target="_blank" class="text-muted"><i class="bi bi-box-arrow-up-right"></i></a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Infrastructure Section -->
    <div class="col-md-4">
        <div class="card p-4 mb-4">
            <div class="stat-label mb-3">ASSET HEALTH OVERVIEW</div>
            <div class="mb-4">
                <div class="d-flex justify-content-between mb-2">
                    <span style="font-size: 0.65rem; color: var(--text-secondary); font-weight: 700;">CONDITION DISTRIBUTION</span>
                    <span style="font-size: 0.65rem; color: var(--accent); font-weight: 700;"><?php echo $efficiency; ?>% HEALTHY</span>
                </div>
                <div class="d-flex gap-1">
                    <?php 
                    $total = max(1, $total_relevant);
                    $clean_seg = round(($count_clean / $total) * 12);
                    $dusty_seg = round(($count_dusty / $total) * 12);
                    $bird_seg = 12 - $clean_seg - $dusty_seg;
                    
                    for($i=0; $i<12; $i++): 
                        $color = '#333';
                        if ($i < $clean_seg) $color = 'var(--accent)';
                        elseif ($i < $clean_seg + $dusty_seg) $color = '#ffaa00';
                        elseif ($i < 12) $color = '#ff4444';
                    ?>
                        <div style="flex: 1; height: 10px; background: <?php echo $color; ?>; border-radius: 2px;"></div>
                    <?php endfor; ?>
                </div>
                <div class="d-flex justify-content-between mt-1">
                    <span class="text-muted" style="font-size: 0.5rem;">SEGMENTED BY CATEGORY</span>
                    <span class="text-muted" style="font-size: 0.5rem;"><?php echo $total_relevant; ?> TOTAL UNITS</span>
                </div>
            </div>
            
            <div class="p-3 mb-3" style="background: rgba(255,255,255,0.03); border-radius: 8px; border: 1px solid var(--border);">
                <div class="d-flex align-items-center mb-2">
                    <i class="bi bi-cpu-fill <?php echo $training_status == 'TRAINING' ? 'text-accent' : 'text-muted'; ?> me-2"></i>
                    <span class="orbitron" style="font-size: 0.75rem; font-weight: 700;">SOLAR-ML V11.0</span>
                    <?php if($training_status == 'TRAINING'): ?>
                        <span class="badge ms-auto" style="background: rgba(217, 255, 0, 0.1); color: var(--accent); border: 1px solid var(--accent); font-size: 0.55rem; padding: 0.35em 0.65em; letter-spacing: 1px; font-weight: 800;">LIVE TRAINING</span>
                    <?php endif; ?>
                </div>
                <p class="text-muted mb-3" style="font-size: 0.6rem; line-height: 1.4; text-transform: uppercase;">
                    <?php echo $training_info; ?>
                </p>
                <div class="d-flex justify-content-between mb-1">
                    <span class="text-muted" style="font-size: 0.55rem;">
                        <?php echo $training_status == 'TRAINING' ? 'GLOBAL PROGRESS' : 'SYSTEM STATUS'; ?>
                    </span>
                    <span class="text-muted" style="font-size: 0.55rem;">
                        <?php echo $training_status == 'TRAINING' ? $training_progress . '%' : 'ACTIVE'; ?>
                    </span>
                </div>
                <div class="progress" style="height: 3px; background: rgba(255,255,255,0.05);">
                    <div class="progress-bar <?php echo $training_status == 'TRAINING' ? 'progress-bar-animated progress-bar-striped' : ''; ?>" 
                         style="width: <?php echo $training_status == 'TRAINING' ? $training_progress : '100'; ?>%; background: var(--accent);"></div>
                </div>
            </div>
            
            <div class="d-flex justify-content-between align-items-center">
                <div class="d-flex align-items-center">
                    <i class="bi bi-shield-lock-fill text-muted me-2" style="font-size: 0.8rem;"></i>
                    <span class="text-muted" style="font-size: 0.65rem; font-weight: 700;">SSL PROTOCOL ACTIVE</span>
                </div>
                <div class="rounded-circle" style="width: 6px; height: 6px; background: var(--accent);"></div>
            </div>
        </div>
    </div>
</div>

<script>
// Diagnostics Comparison Chart
const prodCtx = document.getElementById('productionChart').getContext('2d');
new Chart(prodCtx, {
    type: 'bar',
    data: {
        labels: ['CLEAN', 'DUSTY', 'BIRD-DROP', 'ELECTRICAL-DAMAGE', 'PHYSICAL-DAMAGE', 'SNOW-COVERED'],
        datasets: [{
            label: 'Total Units',
            data: [<?php echo $count_clean; ?>, <?php echo $count_dusty; ?>, <?php echo $count_bird_drop; ?>, <?php echo $count_electrical; ?>, <?php echo $count_physical; ?>, <?php echo $count_snow; ?>],
            backgroundColor: [
                '#D9FF00',
                '#ffaa00',
                '#ff4444',
                '#3b82f6',
                '#a855f7',
                '#22d3ee'
            ],
            borderRadius: 4
        }]
    },
    options: {
        plugins: { legend: { display: false } },
        scales: {
            y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#64748b' }, beginAtZero: true },
            x: { grid: { display: false }, ticks: { color: '#64748b' } }
        }
    }
});

// Integrity Chart (Radial)
const integrityCtx = document.getElementById('integrityChart').getContext('2d');
new Chart(integrityCtx, {
    type: 'doughnut',
    data: {
        datasets: [{
            data: [<?php echo $count_clean; ?>, <?php echo ($count_dusty + $count_bird_drop); ?>],
            backgroundColor: ['#D9FF00', '#1A1A1A'],
            borderWidth: 0,
            circumference: 360,
            rotation: 0
        }]
    },
    options: {
        cutout: '85%',
        plugins: { legend: { display: false } }
    }
});
</script>

<?php require_once 'footer.php'; ?>
