<?php
header('Content-Type: application/json');

// Connect to your Hostinger MySQL database
$conn = new mysqli('mysql.hostinger.com', 'u889533010_rutaco', 'Rutaco_2024', 'u889533010_rutaco');

// Check connection
if ($conn->connect_error) {
    die(json_encode(['status' => 'error', 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// Query the database
$sql = "SELECT * FROM route_tbl ORDER BY popularitynumber DESC";
$result = $conn->query($sql);
$data = [];

// Fetch the data
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
}

// Return the data in JSON format
echo json_encode($data);

// Close the connection
$conn->close();
?>
