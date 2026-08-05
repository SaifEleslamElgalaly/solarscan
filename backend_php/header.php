<?php
ob_start();
session_start();
require_once 'db.php';
require_once 'class_helpers.php';

function checkLogin() {
    if (!isset($_SESSION['user_id'])) {
        header('Location: login.php');
        exit;
    }
}

$current_page = basename($_SERVER['PHP_SELF']);
if ($current_page != 'login.php') {
    checkLogin();
}

// Fetch System Settings for Global Application
$sys_settings = $pdo->query("SELECT * FROM settings WHERE id = 1")->fetch();
if (!$sys_settings) {
    $sys_settings = ['high_contrast' => 0, 'notifications' => 0, 'auto_audit' => 0];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SOLARSCAN | Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --bg-dark: #000000;
            --sidebar-bg: #0A0A0A;
            --card-bg: #121212;
            --accent: <?php echo $sys_settings['high_contrast'] ? '#F0FF00' : '#D9FF00'; ?>;
            --text-primary: #FFFFFF;
            --text-secondary: #E2E8F0;
            --border: rgba(255, 255, 255, <?php echo $sys_settings['high_contrast'] ? '0.15' : '0.05'; ?>);
            --glow: <?php echo $sys_settings['high_contrast'] ? '0 0 15px rgba(240, 255, 0, 0.4)' : 'none'; ?>;
        }
        
        body { 
            font-family: 'Inter', sans-serif; 
            background-color: var(--bg-dark); 
            color: var(--text-primary);
            overflow-x: hidden;
        }
        
        .text-muted { color: #CBD5E1 !important; }
        
        /* Force conversion of dark gray to white */
        * { color: inherit; }
        .text-dark, p, span, h1, h2, h3, h4, h5, h6, label, td, th { 
            color: #FFFFFF !important; 
        }
        [style*="color: #212529"], [style*="color:#212529"] {
            color: #FFFFFF !important;
        }
        
        .orbitron { font-family: 'Orbitron', sans-serif; }
        
        /* Sidebar Styling */
        .sidebar { 
            min-height: 100vh; 
            background: var(--sidebar-bg); 
            padding: 2rem 1rem;
            border-right: 1px solid var(--border);
            position: fixed;
            width: 260px;
            z-index: 1000;
        }
        
        .sidebar .nav-link { 
            color: var(--text-secondary); 
            padding: 0.9rem 1.25rem; 
            border-radius: 8px;
            margin-bottom: 0.5rem;
            font-weight: 500;
            font-size: 0.9rem;
            transition: all 0.2s;
            display: flex;
            align-items: center;
        }
        
        .sidebar .nav-link i { font-size: 1.1rem; margin-right: 1rem; }
        
        .sidebar .nav-link:hover, .sidebar .nav-link.active { 
            color: var(--accent); 
        }
        
        .sidebar .nav-link.active {
            background: rgba(217, 255, 0, 0.05);
            border-left: 3px solid var(--accent);
            border-radius: 0 8px 8px 0;
            margin-left: -1rem;
            padding-left: 2rem;
        }
        
        /* Top Bar Styling */
        .topbar {
            height: 70px;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(10px);
            border-bottom: 1px solid var(--border);
            padding: 0 2rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 900;
            margin-left: 260px;
        }
        
        .search-box {
            background: #121212;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 0.5rem 1rem;
            width: 300px;
            display: flex;
            align-items: center;
        }
        
        .search-box input {
            background: transparent;
            border: none;
            color: white;
            margin-left: 10px;
            font-size: 0.85rem;
            width: 100%;
        }
        
        .search-box input:focus { outline: none; }
        
        /* Main Content Styling */
        .main-content { 
            margin-left: 260px;
            padding: 2.5rem 3rem; 
        }
        
        .card { 
            background: var(--card-bg);
            border: 1px solid var(--border); 
            border-radius: 12px; 
            box-shadow: var(--glow);
            transition: all 0.3s ease;
        }
        
        .btn-accent {
            background: var(--accent);
            color: black;
            font-family: 'Orbitron', sans-serif;
            font-weight: 700;
            font-size: 0.75rem;
            padding: 0.75rem 1.5rem;
            border-radius: 4px;
            transition: all 0.2s;
            border: none;
        }
        
        .btn-accent:hover {
            background: #c2e600;
            transform: translateY(-1px);
            box-shadow: 0 0 15px rgba(217, 255, 0, 0.3);
        }
        
        /* Stats Styling */
        .stat-value { font-size: 2.5rem; font-weight: 700; color: var(--accent); }
        .stat-label { font-size: 0.7rem; font-weight: 700; color: var(--text-secondary); letter-spacing: 1px; }
        
        /* Table Styling */
        .table { color: white; }
        .table thead th { 
            background: transparent; 
            border-bottom: 1px solid var(--border); 
            color: var(--text-secondary);
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            padding: 1.25rem 1rem;
        }
        .table tbody td { 
            background: transparent; 
            border-bottom: 1px solid var(--border); 
            padding: 1.25rem 1rem;
            font-size: 0.9rem;
        }
        
        .priority-high { color: #ff4444; border: 1px solid #ff4444; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; font-weight: 700; }
        .priority-low { color: #3b82f6; border: 1px solid #3b82f6; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; font-weight: 700; }
        
        /* User Profile Bottom */
        .sidebar-footer {
            position: absolute;
            bottom: 2rem;
            left: 1rem;
            right: 1rem;
            padding-top: 2rem;
            border-top: 1px solid var(--border);
        }
    </style>
</head>
<body>
<div class="container-fluid p-0">
    <?php if ($current_page != 'login.php'): ?>
    <div class="sidebar d-none d-md-block">
        <div class="mb-4 px-3 text-center">
            <img src="assets/images/logo.png" alt="SOLARSCAN" style="height: 100px; width: auto; filter: drop-shadow(0 0 10px rgba(217, 255, 0, 0.2));">
        </div>
        <ul class="nav flex-column">
            <li class="nav-item"><a href="index.php" class="nav-link <?php echo $current_page == 'index.php' ? 'active' : ''; ?>"><i class="bi bi-grid-fill"></i> Overview</a></li>
            <li class="nav-item"><a href="users.php" class="nav-link <?php echo $current_page == 'users.php' ? 'active' : ''; ?>"><i class="bi bi-people-fill"></i> Users</a></li>
            <li class="nav-item"><a href="panels.php" class="nav-link <?php echo $current_page == 'panels.php' ? 'active' : ''; ?>"><i class="bi bi-cpu-fill"></i> Panels</a></li>
            <li class="nav-item"><a href="alerts.php" class="nav-link <?php echo $current_page == 'alerts.php' ? 'active' : ''; ?>"><i class="bi bi-bell-fill"></i> Alerts</a></li>
            <li class="nav-item"><a href="reports.php" class="nav-link <?php echo $current_page == 'reports.php' ? 'active' : ''; ?>"><i class="bi bi-bar-chart-fill"></i> Reports</a></li>
            <li class="nav-item"><a href="settings.php" class="nav-link <?php echo $current_page == 'settings.php' ? 'active' : ''; ?>"><i class="bi bi-gear-fill"></i> Settings</a></li>
        </ul>
        
        <div class="sidebar-footer">
            <div class="d-flex align-items-center">
                <img src="assets/images/profile_alex.png" class="rounded-circle me-3" style="width: 40px; height: 40px; border: 1px solid var(--accent);" onerror="this.src='https://ui-avatars.com/api/?name=Admin&background=D9FF00&color=000'">
                <div>
                    <h6 class="mb-0 fw-bold" style="font-size: 0.85rem;">System Admin</h6>
                    <small class="text-muted" style="font-size: 0.7rem; font-weight: 700;">ENERGY SECTOR LEAD</small>
                </div>
            </div>
            <a href="logout.php" class="btn btn-sm btn-outline-danger border-0 mt-3 w-100 text-start"><i class="bi bi-power me-2"></i> Logout</a>
        </div>
    </div>
    
    <div class="topbar">
        <div class="search-box">
            <i class="bi bi-search text-muted"></i>
            <input type="text" placeholder="SEARCH SYSTEM...">
        </div>
        <div class="d-flex align-items-center">
            <div class="position-relative me-4">
                <i class="bi bi-bell-fill text-white fs-5"></i>
                <?php if ($sys_settings['notifications']): ?>
                    <span class="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle"></span>
                <?php endif; ?>
            </div>
            <div class="text-end">
                <div class="orbitron fw-bold" style="color: var(--accent); font-size: 0.6rem;">
                    <?php 
                    if ($sys_settings['auto_audit']) {
                        echo "AUTO-AUDIT: ENABLED (02:00 UTC)";
                    } else {
                        echo "SYSTEM NORMAL";
                    }
                    ?>
                </div>
                <div class="text-muted" style="font-size: 0.6rem;">
                    <?php if ($sys_settings['notifications']) echo "ALERTS: ACTIVE | "; ?>
                    LATENCY: 24MS
                </div>
            </div>
        </div>
    </div>
    
    <main class="main-content">
    <?php else: ?>
    <main>
    <?php endif; ?>
