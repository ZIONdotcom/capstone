    <?php

    $servername = "mysql.hostinger.com"; 
    $username = "'u889533010_rutaco";
    $dbname = "u889533010_rutaco";
    $password = "Rutaco_2024";


    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    // Retrieve data sent from Flutter app
    $lanmark = $_POST['landmark'];
    $location_name = $_POST['location_name'];
    $_address = $_POST['address'];
    $user_id = $_POST['user_id']
    $location_type_id = $_POST['location_type_id']
    $lng = $_POST['longitude'];
    $lat = $_POST['latitude'];
    $image_paths = $_POST['image_paths'];


    // SQL query to insert data into the locations table
    $sql1 = "INSERT INTO location_tbl (landmark, location_name, address,user_id,location_type_id,x_coordinate,y_coordinate) VALUES (?,?,?,?,?,?,?)";
    $stmt1 = $conn->prepare($sql1);
    $stmt1->bind_param('sssiidd', $lanmark, $location_name, $_address,$user_id,$location_type_id,$lng,$lat);

    if($stmt1->execute()){
        $location_id = $conn->loc_id;

        $sql2 = "INSERT INTO location_image_tbl (image_path, location_id) VALUES (?, ?)";
        $stmt2 = $conn->prepare($sql2);

        foreach ($image_paths as $image_path) {
            $stmt2->bind_param('si', $image_path, $location_id);
            $stmt2->execute();
        }
        echo "New record created successfully";
    }

    else {
        echo "Error: " . $sql . "<br>" . $conn->error;
    }

    $stmt1->close();
    $stmt2->close();
    $conn->close();
    ?>
