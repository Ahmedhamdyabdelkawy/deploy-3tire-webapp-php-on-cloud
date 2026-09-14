<?php
declare(strict_types=1);
$query = $_SERVER['QUERY_STRING'] ?? '';
$target = 'features/preview/index.php' . ($query !== '' ? '?' . $query : '');
header('Location: ' . $target);
exit;
