<?php
/**
 * NEUTERED LAB STAND-IN. This is NOT a working web shell.
 *
 * It reproduces only the detection surface of the WSO "orb yanz" family so that
 * YARA rules, string hunts, and cleanup drills work in the lab. Every capability
 * is removed: no file access, no command execution, no multi-stage decode. Do not
 * add any. The signature strings below are inert literals.
 */
$LAB_SIGNATURES = "PRIV8 WEB SHELL ORB YANZ BYPASS / WSOX ENC / xor-key wsoyanz";
// The real family gates on a host-derived cookie such as _d41=fa704e7366d666bd.
// Here the gate is decorative and leads nowhere.
header('Content-Type: text/plain');
echo "Lab stand-in for the WSO shell. Neutered: no functionality.\n";
echo "Signature strings are present so detection fires during the exercise.\n";
