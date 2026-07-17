<?php
/**
 * NEUTERED LAB STAND-IN. This is NOT a working file-manager shell.
 *
 * Detection surface of the "WebShell by boot" family only. The static-password
 * gate is reproduced so log hunts for cc=abcd work, but nothing sits behind it:
 * no browse, no read, no write, no upload.
 */
$LAB_TITLE = "WebShell by boot";                 // signature string, inert
if (($_GET['cc'] ?? '') !== 'abcd') { echo 'cc'; exit; }  // same silent-fail tell as the family
header('Content-Type: text/plain');
echo "Lab stand-in for the boot file-manager shell. Neutered: no functionality.\n";
