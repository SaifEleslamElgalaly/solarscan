<?php
require_once 'header.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['add_role'])) {
    $name = $_POST['role_name'];
    $pdo->prepare("INSERT INTO roles (name) VALUES (?)")->execute([$name]);
}

$roles = $pdo->query("SELECT * FROM roles")->fetchAll();
?>

<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
    <h1 class="h2">Role Management</h1>
</div>

<div class="row">
    <div class="col-md-4">
        <div class="card shadow-sm mb-4">
            <div class="card-header bg-white">Add New Role</div>
            <div class="card-body">
                <form method="POST">
                    <div class="mb-3">
                        <label class="form-label">Role Name</label>
                        <input type="text" name="role_name" class="form-control" required>
                    </div>
                    <button type="submit" name="add_role" class="btn btn-primary">Add Role</button>
                </form>
            </div>
        </div>
    </div>
    <div class="col-md-8">
        <div class="card shadow-sm">
            <div class="card-body">
                <table class="table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Role Name</th>
                            <th>Permissions</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($roles as $role): ?>
                        <tr>
                            <td><?php echo $role['id']; ?></td>
                            <td><?php echo htmlspecialchars($role['name']); ?></td>
                            <td>
                                <!-- Simplified: just show count or link to edit permissions -->
                                <a href="permissions.php?role_id=<?php echo $role['id']; ?>" class="btn btn-sm btn-outline-info">Manage Permissions</a>
                            </td>
                            <td>
                                <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<?php require_once 'footer.php'; ?>
