<?php

$conn = mysqli_connect(
    getenv('DB_HOST'),
    getenv('DB_USERNAME'),
    getenv('DB_PASSWORD'),
    getenv('DB_DATABASE'),
    getenv('DB_PORT')
);

$counter = 10;
$count = 0;
while (!$conn) {
    echo("Waiting for Database... $count / $counter\n");
    sleep(2);
    $conn = mysqli_connect(
        getenv('DB_HOST'),
        getenv('DB_USERNAME'),
        getenv('DB_PASSWORD'),
        getenv('DB_DATABASE'),
        getenv('DB_PORT')
    );
    $count++;
    if($count == $counter) {
        echo("Database did not respond after $counter tries, giving up\n");
        die(1);
    }
}

echo "Database is up\n";
?>
