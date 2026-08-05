<?php
require_once 'header.php';

$role_id = $_GET['role_id'] ?? null;

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['update_permissions'])) {
    $rid = $_POST['role_id'];
    $pdo->prepare("DELETE FROM permission_role WHERE role_id = ?")->execute([$rid]);
    if (isset($_POST['perms'])) {
        foreach ($_POST['perms'] as $pid) {
            $pdo->prepare("INSERT INTO permission_role (permission_id, role_id) VALUES (?, ?)")->execute([$pid, $rid]);
        }
    }
    $success = "Permissions updated for role.";
}

$roles = $pdo->query("SELECT * FROM roles")->fetchAll();
$all_permissions = $pdo->query("SELECT * FROM permissions")->fetchAll();

$active_role = null;
$role_perms = [];
if ($role_id) {
    $stmt = $pdo->prepare("SELECT * FROM roles WHERE id = ?");
    $stmt->execute([$role_id]);
    $active_role = $stmt->fetch();
    
    $stmt = $pdo->prepare("SELECT permission_id FROM permission_role WHERE role_id = ?");
    $stmt->execute([$role_id]);
    $role_perms = $stmt->fetchAll(PDO::FETCH_COLUMN);
}
?>

<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
    <h1 class="h2">Permission Management</h1>
</div>

<div class="row">
    <div class="col-md-4">
        <div class="list-group shadow-sm">
            <div class="list-group-item bg-light font-weight-bold">Select Role</div>
            <?php foreach ($roles as $role): ?>
                <a href="?role_id=<?php echo $role['id']; ?>" class="list-group-item list-group-item-action <?php echo ($role_id == $role['id']) ? 'active' : ''; ?>">
                    <?php echo htmlspecialchars($role['name']); ?>
                </a>
            <?php endforeach; ?>
        </div>
    </div>
    <div class="col-md-8">
        <?php if ($active_role): ?>
            <div class="card shadow-sm">
                <div class="card-header bg-white">Permissions for <strong><?php echo htmlspecialchars($active_role['name']); ?></strong></div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="role_id" value="<?php echo $active_role['id']; ?>">
                        <div class="row">
                            <?php foreach ($all_permissions as $perm): ?>
                                <div class="col-md-6 mb-2">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" name="perms[]" value="<?php echo $perm['id']; ?>" id="perm_<?php echo $perm['id']; ?>" <?php echo in_array($perm['id'], $role_perms) ? 'checked' : ''; ?>>
                                        <label class="form-check-label" for="perm_<?php echo $perm['id']; ?>">
                                            <?php echo str_replace('_', ' ', ucfirst($perm['name'])); ?>
                                        </label>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        </div>
                        <hr>
                        <button type="submit" name="update_permissions" class="btn btn-success">Save Permissions</button>
                    </form>
                </div>
            </div>
        <?php else: ?>
            <div class="alert alert-info">Please select a role from the left to manage its permissions.</div>
        <?php endif; ?>
    </div>
</div>

<?php require_once 'footer.php'; ?>
