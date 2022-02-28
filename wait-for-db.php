<?php

function connect()
{
    $connection = getenv('DB_CONNECTION');
    $host = getenv('DB_HOST');
    $username = getenv('DB_USERNAME');
    $password = getenv('DB_PASSWORD');
    $database = getenv('DB_DATABASE');
    $port = getenv('DB_PORT');
    if ($connection === 'mysql') {
        return mysqli_connect($host, $username, $password, $database, $port);
    }
    if ($connection === 'pgsql') {
        return pg_connect('host=' . $host . ' port=' . $port . ' dbname=' . $database . ' user=' . $username . ' password=' . $password);
    }
    throw new Exception('unsupported connection type ' . $connection);
}

$conn = connect();

$counter = 10;
$count = 1;
while (!$conn) {
    echo("Waiting for Database... $count / $counter\n");
    sleep(2);
    $conn = connect();
    $count++;
    if ($count == $counter) {
        echo("Database did not respond after $counter tries, giving up\n");
        die(1);
    }
}

echo "Database is up\n";
?>
