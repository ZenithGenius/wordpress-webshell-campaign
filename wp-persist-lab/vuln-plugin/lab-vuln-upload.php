<?php
/**
 * LAB ONLY. Deliberately vulnerable. NEVER deploy this.
 *
 * Models the vulnerability class behind the campaign's initial access:
 * an unauthenticated arbitrary file upload, the same class as
 * CVE-2020-25213 (wp-file-manager) and many other WordPress plugin bugs.
 *
 * It exposes an upload endpoint that performs NO authentication and NO type
 * check, so the initial-access lab (exploit.sh) has a real vector to hit. It
 * exists only inside the isolated lab (mounted as a must-use plugin) and only
 * listens on 127.0.0.1.
 */
add_action('init', function () {
    if (!isset($_GET['lab_vuln_upload'])) {
        return;
    }

    // The vulnerability: no capability check, no nonce, no auth of any kind.
    $name = isset($_GET['name']) ? basename((string) $_GET['name']) : 'upload.php';
    $dest = WP_CONTENT_DIR . '/' . $name;

    header('Content-Type: text/plain');

    if (!empty($_FILES['file']['tmp_name'])) {
        move_uploaded_file($_FILES['file']['tmp_name'], $dest);
        echo "uploaded: wp-content/$name\n";
        exit;
    }

    $raw = file_get_contents('php://input');
    if ($raw !== '') {
        file_put_contents($dest, $raw);
        echo "uploaded: wp-content/$name\n";
        exit;
    }

    http_response_code(400);
    echo "no file provided\n";
    exit;
});
