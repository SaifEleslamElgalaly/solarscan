<?php
require_once 'header.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $name = $_POST['name'] ?? '';
    $email = $_POST['email'] ?? '';
    $password = password_hash($_POST['password'] ?? 'password123', PASSWORD_DEFAULT);
    $role_id = $_POST['role_id'] ?? 2; // Default to Inspector

    try {
        $pdo->beginTransaction();
        
        $stmt = $pdo->prepare("INSERT INTO users (name, email, password, created_at, updated_at) VALUES (?, ?, ?, NOW(), NOW())");
        $stmt->execute([$name, $email, $password]);
        $user_id = $pdo->lastInsertId();
        
        $stmt = $pdo->prepare("INSERT INTO role_user (role_id, user_id) VALUES (?, ?)");
        $stmt->execute([$role_id, $user_id]);
        
        $pdo->commit();
        $message = "User created successfully!";
    } catch (Exception $e) {
        $pdo->rollBack();
        $error = "Error: " . $e->getMessage();
    }
}

$roles = $pdo->query("SELECT * FROM roles")->fetchAll();
?>

<div class="d-flex justify-content-between align-items-end mb-5">
    <div>
        <h1 class="orbitron fw-bold mb-0" style="font-size: 2rem; letter-spacing: 2px;">PROVISION USER</h1>
        <p class="text-muted fw-bold mb-0" style="font-size: 0.8rem;">Initialize new field inspector credentials and system permissions.</p>
    </div>
    <a href="users.php" class="btn btn-outline-secondary border-secondary text-white px-4 py-2" style="font-size: 0.75rem; font-weight: 700;">
        <i class="bi bi-arrow-left me-2"></i> BACK TO DIRECTORY
    </a>
</div>

<div class="row justify-content-center">
    <div class="col-md-6">
        <?php if ($message): ?>
            <div class="alert alert-success bg-accent text-black border-0 fw-bold mb-4"><?php echo $message; ?></div>
        <?php endif; ?>
        <?php if ($error): ?>
            <div class="alert alert-danger bg-danger text-white border-0 fw-bold mb-4"><?php echo $error; ?></div>
        <?php endif; ?>

        <div class="card p-5">
            <form method="POST">
                <div class="mb-4">
                    <label class="stat-label mb-2">FULL IDENTITY NAME</label>
                    <div class="search-box w-100" style="margin-left: 0;">
                        <i class="bi bi-person text-muted"></i>
                        <input type="text" name="name" placeholder="Enter full name..." required>
                    </div>
                </div>

                <div class="mb-4">
                    <label class="stat-label mb-2">SYSTEM EMAIL ADDRESS</label>
                    <div class="search-box w-100" style="margin-left: 0;">
                        <i class="bi bi-envelope text-muted"></i>
                        <input type="email" name="email" placeholder="name@solarscan.ai" required>
                    </div>
                </div>

                <div class="mb-4">
                    <label class="stat-label mb-2">INITIAL ACCESS KEY (PASSWORD)</label>
                    <div class="search-box w-100" style="margin-left: 0;">
                        <i class="bi bi-key text-muted"></i>
                        <input type="password" name="password" placeholder="••••••••" required>
                    </div>
                </div>

                <div class="mb-5">
                    <label class="stat-label mb-2">DESIGNATED SYSTEM ROLE</label>
                    <select name="role_id" class="form-select bg-dark border-secondary text-white py-3 px-4" style="font-size: 0.9rem; border: 1px solid var(--border);">
                        <?php foreach ($roles as $role): ?>
                            <option value="<?php echo $role['id']; ?>"><?php echo strtoupper($role['name']); ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <button type="submit" class="btn btn-accent w-100 py-3 orbitron fw-bold" style="letter-spacing: 2px;">
                    EXECUTE PROVISIONING
                </button>
            </form>
        </div>
        
        <div class="mt-5 p-4 rounded" style="background: rgba(217, 255, 0, 0.02); border: 1px solid var(--border);">
            <div class="d-flex align-items-center mb-2">
                <i class="bi bi-info-circle text-accent me-2"></i>
                <span class="orbitron" style="font-size: 0.7rem; font-weight: 700;">SECURITY NOTICE</span>
            </div>
            <p class="text-muted mb-0" style="font-size: 0.65rem; line-height: 1.5;">
                Upon execution, an automated notification will be sent to the provisioned email with encrypted access credentials. All sessions are logged for audit purposes.
            </p>
        </div>
    </div>
</div>

<?php require_once 'footer.php'; ?>
