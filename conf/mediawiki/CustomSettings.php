<?php

/**
 * VisualEditor
 */
require_once "/usr/src/mediawiki/extensions/VisualEditor/VisualEditor.php";
$wgDefaultUserOptions['visualeditor-enable'] = 1;
$wgHiddenPrefs[] = 'visualeditor-enable';
#$wgDefaultUserOptions['visualeditor-enable-experimental'] = 1;
$wgVirtualRestConfig['modules']['restbase'] = array(
	'url' => 'http://localhost:7231',
	'domain' => 'localhost',
	'forwardCookies' => true,
	'parsoidCompat' => false
);

/**
 * Math
 */
$wgDefaultUserOptions['math'] = 'mathml';
$wgMathFullRestbaseURL = 'http://localhost:7231/localhost/';
wfLoadExtension( 'Math' );

?>
