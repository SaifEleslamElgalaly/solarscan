<?php
require_once 'header.php';

// Handle Role Assignment
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['assign_role'])) {
    $uid = $_POST['user_id'];
    $rid = $_POST['role_id'];
    
    $pdo->prepare("DELETE FROM role_user WHERE user_id = ?")->execute([$uid]);
    $pdo->prepare("INSERT INTO role_user (role_id, user_id) VALUES (?, ?)")->execute([$rid, $uid]);
    $success = "Role updated successfully";
}

$users = $pdo->query("SELECT users.*, roles.name as role_name FROM users LEFT JOIN role_user ON users.id = role_user.user_id LEFT JOIN roles ON role_user.role_id = roles.id ORDER BY users.created_at DESC")->fetchAll();
$roles = $pdo->query("SELECT * FROM roles")->fetchAll();
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 2.5rem; letter-spacing: 2px;">USER DIRECTORY</h1>
        <p class="text-muted fw-bold mb-0" style="font-size: 0.9rem; max-width: 600px; line-height: 1.5;">Manage system access, roles, and security permissions for energy sector lead operators and diagnostic inspectors.</p>
    </div>
    <a href="add_user.php" class="btn btn-accent px-4 py-3"><i class="bi bi-person-plus-fill me-2"></i> ADD NEW USER</a>
</div>

<!-- Summary Stats -->
<div class="row g-4 mb-5">
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">TOTAL USERS</div>
                    <div class="stat-value">1,284</div>
                    <div class="progress mt-2" style="height: 4px; width: 100px; background: rgba(255,255,255,0.05);">
                        <div class="progress-bar" style="width: 80%; background: var(--accent);"></div>
                    </div>
                </div>
                <i class="bi bi-people-fill fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">ACTIVE NOW</div>
                    <div class="stat-value">42</div>
                    <div style="font-size: 0.65rem; color: var(--accent); font-weight: 700;">
                        <span class="badge rounded-circle p-1 me-1" style="background: var(--accent);"> </span>
                        LIVE DIAGNOSTIC SESSIONS
                    </div>
                </div>
                <i class="bi bi-activity fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">TOTAL INSPECTORS</div>
                    <div class="stat-value">89</div>
                    <div style="font-size: 0.65rem; color: var(--accent); font-weight: 700;">FIELD VALIDATED ROLES</div>
                </div>
                <i class="bi bi-shield-check-fill fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">SYSTEM HEALTH</div>
                    <div class="stat-value">99.9%</div>
                    <div class="text-muted" style="font-size: 0.65rem; font-weight: 700;">AUTH LATENCY < 12MS</div>
                </div>
                <i class="bi bi-heart-pulse-fill fs-3 text-muted opacity-25"></i>
            </div>
        </div>
    </div>
</div>

<!-- Table Filter Bar -->
<div class="d-flex justify-content-between align-items-center mb-4 px-4 py-3 rounded-top" style="background: rgba(255,255,255,0.02); border: 1px solid var(--border);">
    <div class="d-flex align-items-center gap-3">
        <span class="stat-label" style="font-size: 0.65rem;">ACTIVE FILTERS:</span>
        <span class="badge py-2 px-3 border border-secondary text-white fw-bold d-flex align-items-center" style="font-size: 0.65rem; background: rgba(217, 255, 0, 0.05); color: var(--accent) !important; border-color: rgba(217, 255, 0, 0.2) !important;">
            ALL ROLES <i class="bi bi-x-lg ms-2"></i>
        </span>
    </div>
    <div class="d-flex gap-2">
        <button class="btn btn-sm btn-outline-secondary border-secondary text-white"><i class="bi bi-filter"></i></button>
        <button class="btn btn-sm btn-outline-secondary border-secondary text-white"><i class="bi bi-download"></i></button>
    </div>
</div>

<!-- Users Table -->
<div class="card p-0 mb-5">
    <div class="table-responsive">
        <table class="table mb-0">
            <thead>
                <tr>
                    <th>USER IDENTITY</th>
                    <th>SYSTEM ROLE</th>
                    <th>LAST LOGIN</th>
                    <th>STATUS</th>
                    <th class="text-end pe-4">ACTIONS</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($users as $index => $user): ?>
                <tr>
                    <td class="ps-4">
                        <div class="d-flex align-items-center">
                            <div class="position-relative">
                                <img src="assets/images/user_<?php echo ($index % 2 == 0) ? 'marcus' : 'sarah'; ?>.png" 
                                     class="rounded me-3" 
                                     style="width: 45px; height: 45px; object-fit: cover; border: 1px solid var(--border);"
                                     onerror="this.src='https://ui-avatars.com/api/?name=<?php echo urlencode($user['name']); ?>&background=D9FF00&color=000'">
                                <div class="position-absolute bottom-0 end-0 rounded-circle" style="width: 10px; height: 10px; background: var(--accent); border: 2px solid var(--card-bg); margin-bottom: -2px; margin-right: 12px;"></div>
                            </div>
                            <div>
                                <h6 class="mb-0 fw-bold"><?php echo htmlspecialchars($user['name']); ?></h6>
                                <small class="text-muted" style="font-size: 0.75rem;"><?php echo htmlspecialchars($user['email']); ?></small>
                            </div>
                        </div>
                    </td>
                    <td>
                        <span class="badge py-2 px-3 fw-bold" style="font-size: 0.65rem; background: rgba(255,255,255,0.05); color: <?php echo ($user['role_name'] == 'Admin') ? 'var(--accent)' : 'var(--text-secondary)'; ?>; border: 1px solid rgba(255,255,255,0.05);">
                            <?php echo strtoupper($user['role_name'] ?? 'PENDING'); ?>
                        </span>
                    </td>
                    <td class="text-muted">
                        <div style="font-size: 0.9rem; font-weight: 500;">2026.10.<?php echo 24 - $index; ?> <span style="font-size: 0.75rem; opacity: 0.5;">14:22 UTC</span></div>
                    </td>
                    <td>
                        <div class="d-flex align-items-center fw-bold" style="font-size: 0.7rem; color: var(--accent);">
                            <span class="badge rounded-circle p-1 me-2" style="background: var(--accent);"> </span> ACTIVE
                        </div>
                    </td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-icon text-muted"><i class="bi bi-pencil-square"></i></button>
                        <button class="btn btn-sm btn-icon text-muted"><i class="bi bi-trash3"></i></button>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <div class="card-footer border-0 bg-transparent py-4 px-4 d-flex justify-content-between align-items-center">
        <div class="text-muted" style="font-size: 0.7rem; font-weight: 700;">SHOWING 1-4 OF 1,284 RESULTS</div>
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
    <div class="col-md-7">
        <div class="card p-4 h-100" style="background: rgba(255,255,255,0.02);">
            <div class="d-flex align-items-center mb-4">
                <div class="p-3 rounded-circle me-3" style="background: rgba(217, 255, 0, 0.1); border: 1px solid rgba(217, 255, 0, 0.2);">
                    <i class="bi bi-shield-lock-fill text-accent fs-4"></i>
                </div>
                <div>
                    <h5 class="fw-bold mb-1">ACCESS CONTROL AUDIT</h5>
                    <p class="text-muted mb-0" style="font-size: 0.8rem;">System logs indicate 3 new Inspector credentials provisioned in the last 24 hours.</p>
                </div>
            </div>
            <a href="#" class="orbitron text-accent text-decoration-none fw-bold" style="font-size: 0.7rem; letter-spacing: 1px;">VIEW SECURITY LOGS</a>
        </div>
    </div>
    <div class="col-md-5">
        <div class="card p-4 h-100" style="background: rgba(255,255,255,0.02);">
            <div class="d-flex align-items-center mb-4">
                <div class="p-3 rounded-circle me-3" style="background: rgba(59, 130, 246, 0.1); border: 1px solid rgba(59, 130, 246, 0.2);">
                    <i class="bi bi-geo-alt-fill text-primary fs-4"></i>
                </div>
                <div>
                    <h5 class="fw-bold mb-1">REGIONAL ALLOCATION</h5>
                    <p class="text-muted mb-0" style="font-size: 0.8rem;">Inspector distribution is currently balanced across all sectors.</p>
                </div>
            </div>
            <a href="#" class="orbitron text-accent text-decoration-none fw-bold" style="font-size: 0.7rem; letter-spacing: 1px;">MANAGE REGIONS</a>
        </div>
    </div>
</div>

<?php require_once 'footer.php'; ?>
