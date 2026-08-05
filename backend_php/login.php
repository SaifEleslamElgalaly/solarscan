<?php
require_once 'header.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $email = $_POST['email'];
    $password = $_POST['password'];

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['user_name'] = $user['name'];
        header('Location: index.php');
        exit;
    } else {
        $error = 'Invalid email or password';
    }
}
?>
<style>
    body {
        background: url('assets/login-bg.png') no-repeat center center fixed;
        background-size: cover;
    }
    .login-container {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    .glass-card {
        background: rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(15px);
        -webkit-backdrop-filter: blur(15px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 20px;
        color: white;
    }
    .form-control {
        background: rgba(0, 0, 0, 0.3);
        border: 1px solid rgba(255, 255, 255, 0.1);
        color: white !important;
    }
    .form-control:focus {
        background: rgba(0, 0, 0, 0.4);
        border-color: rgba(255, 255, 255, 0.3);
        box-shadow: none;
        color: white !important;
    }
    .form-control::placeholder {
        color: rgba(255, 255, 255, 0.6);
    }
    .btn-primary {
        background: #0d6efd;
        border: none;
        font-weight: 600;
    }
</style>
<div class="login-container">
    <div class="col-md-4">
        <div class="card glass-card shadow-lg">
            <div class="card-body p-5">
                <div class="text-center mb-4">
                    <img src="assets/images/logo.png" alt="SOLARSCAN" style="height: 120px; width: auto; filter: drop-shadow(0 0 15px rgba(217, 255, 0, 0.3));">
                </div>
                <p class="text-center text-light opacity-75 mb-4">Secure Admin Access</p>
                <?php if ($error): ?>
                    <div class="alert alert-danger py-2"><?php echo $error; ?></div>
                <?php endif; ?>
                <form method="POST">
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <input type="email" name="email" class="form-control" placeholder="admin@solar.com" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Password</label>
                        <input type="password" name="password" class="form-control" placeholder="••••••••" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 py-2 mt-3">Sign In</button>
                </form>
            </div>
        </div>
    </div>
</div>
<?php require_once 'footer.php'; ?>
