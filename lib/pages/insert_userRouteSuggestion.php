<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
$conn = new mysqli("mysql.hostinger.com", "u889533010_rutaco", "Rutaco_2024", "u889533010_rutaco");

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$landmark = $_POST['landmark'] ?? null;
$location_name = $_POST['location_name'] ?? null;
$address = $_POST['address'] ?? null;
$user_id = $_POST['user_id'] ?? null;
$location_type_id = $_POST['location_type_id'] ?? null;
$longitude = $_POST['longitude'] ?? null;
$latitude = $_POST['latitude'] ?? null;

$d_landmark = $_POST['destination_landmark'] ?? null;
$d_location_name = $_POST['destination_location_name'] ?? null;
$d_address = $_POST['destination_address'] ?? null;
$d_longitude = $_POST['destination_longitude'] ?? null;
$d_latitude = $_POST['destination_latitude'] ?? null;

$stepsMapJson = $_POST['steps_map'] ?? null;
// $polylinePointsJson = $_POST['polyline_points'] ?? null;

// $lat_polylinePointsJson = $_POST['lat_polyline_points'] ?? null;
// $long_polylinePointsJson = $_POST['long_polyline_points'] ?? null;

// Validation
if (!$stepsMapJson) {
    die("Missing steps map data");
}
// if (!$lat_polylinePointsJson && !$long_polylinePointsJson) {
//     die("Missing polyline points data");
// }
if (!$location_name || !$address || !$user_id || !$location_type_id || !$longitude || !$latitude) {
    die("Missing required fields");
}

// Decode JSON
$stepsMap = json_decode($stepsMapJson, true);
// $polylinePointsMap = json_decode($polylinePointsJson, true);

// $lat_polylinePointsMap = json_decode($lat_polylinePointsJson, true);
// $long_polylinePointsMap = json_decode($long_polylinePointsJson, true);

// Check for JSON decode errors
if (json_last_error() !== JSON_ERROR_NONE) {
    die("Invalid JSON data for steps_map or polyline_points");
}

// Ensure arrays are valid
if (!is_array($stepsMap) || empty($stepsMap)) {
    die("Invalid or empty steps map data");
}
// if (!is_array($polylinePointsMap) || empty($polylinePointsMap)) {
//     die("Invalid or empty polyline points data");
// }
// if (!is_array($lat_polylinePointsMap) || empty($lat_polylinePointsMap)) {
//     die("Invalid or empty lat polyline points data");
// }
// if (!is_array($long_polylinePointsMap) || empty($long_polylinePointsMap)) {
//     die("Invalid or empty long polyline points data");
// }


// $sql_checking = "SELECT location_id FROM location_tbl WHERE x_coordinate = ? AND y_coordinate = ? AND location_name = ? AND adress = ?";
// $stmt_checking = $conn->prepare($sql_checking);
// if(!$stmt_checking){
    // Insert origin into location_tbl
    $sql1 = "INSERT INTO location_tbl (landmark, location_name, address, user_id, location_type_id, x_coordinate, y_coordinate) 
             VALUES (?, ?, ?, ?, ?, ?, ?)";
    $stmt1 = $conn->prepare($sql1);
    
    if (!$stmt1) {
        die("Error preparing statement 1: " . $conn->error);
    }
    $stmt1->bind_param('sssiidd', $landmark, $location_name, $address, $user_id, $location_type_id, $longitude, $latitude);

    if ($stmt1->execute()) {
        $origin_location_id = $conn->insert_id;
        $origin_name = $location_name;
    
        $sql2 = "INSERT INTO location_tbl (landmark, location_name, address, user_id, location_type_id, x_coordinate, y_coordinate) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)";
        $stmt2 = $conn->prepare($sql2);
        
        if (!$stmt2) {
            die("Error preparing statement 2: " . $conn->error);
        }
        
        $stmt2->bind_param('sssiidd', $d_landmark, $d_location_name, $d_address, $user_id, $location_type_id, $d_longitude, $d_latitude);
    
        if ($stmt2->execute()) {
            $destination_location_id = $conn->insert_id; 
            $destination_name = $d_location_name;
            
            //insert origin and destination to route_tbl
            $sql3 = "INSERT INTO route_tbl (origin, destination) VALUES (?, ?)";
            $stmt3 = $conn->prepare($sql3);
            
            if (!$stmt3) {
                die("Error preparing statement 3: " . $conn->error);
            }
            
            $stmt3->bind_param('ii', $origin_location_id, $destination_location_id);
            
            if ($stmt3->execute()) {
                // echo "Route added successfully!";
                $route_id = $conn->insert_id;
                $sql4 = "INSERT INTO route_suggestion_tbl (route_id, user_id,route_suggestion_name,isVisible) VALUES (?, ?, ?, ?)";
                
                $stmt4 = $conn->prepare($sql4);
                
                if (!$stmt4) {
                die("Error preparing statement 4: " . $conn->error);
                }
                
                $route_suggestion_name = "$origin_name to $destination_name";
                $isVisible = 1;
                
                $stmt4->bind_param('iisi', $route_id, $user_id,$route_suggestion_name,$isVisible);
                
                if ($stmt4->execute()) {
                $route_suggestion_id = $conn->insert_id;
                $previous_location_id = $origin_location_id;
            
                foreach ($stepsMap as $stepNumber => $stepData) {
                    if ($stepNumber == 0) continue;
            
                    // Validate step data
                    if (!isset($stepData[0], $stepData[1], $stepData[2])) {
                        throw new Exception("Invalid data in stepsMap for step number $stepNumber.");
                    }
            
                    $stepType = $stepData[0]; // WALK, RIDE
                    $stepLocationDetails = $stepData[1]; // [address, long, lat, location name, landmark]
                    $stepDetails = $stepData[2];// [instructions, fare,vehicle]
                    
            
                    list($s_address, $s_longitude, $s_latitude, $s_location_name, $s_landmark) = $stepLocationDetails;
                    list($s_instructions, $s_fare,$s_vehicle) = $stepDetails;
            
                    // 1st: Insert into location_tbl
                    if(count($stepsMap)-1 == $stepNumber){
                        $s_location_id = $destination_location_id;
                    }
                    else{
                        $sql_stepInsert = "INSERT INTO location_tbl (landmark, location_name, address, user_id, location_type_id, x_coordinate, y_coordinate) VALUES (?, ?, ?, ?, ?, ?, ?)";
                        $stmt_stepInsert = $conn->prepare($sql_stepInsert);
                        if (!$stmt_stepInsert) {
                            throw new Exception("Error preparing location_tbl statement: " . $conn->error);
                        }
                        $stmt_stepInsert->bind_param('sssiidd', $s_landmark, $s_location_name, $s_address, $user_id, $location_type_id, $s_longitude, $s_latitude);
                
                        if ($stmt_stepInsert->execute()) {
                            $s_location_id = $conn->insert_id;
                        }
                        else {
                            throw new Exception("Error inserting into location_tbl: " . $stmt_stepInsert->error);
                        }
                    }
                        if (count($stepDetails) === 1) {
                            $s_vehicle = 'WALK'; 
                            $s_fare = 0;
                        } else {
                            $s_vehicle = strtoupper($stepDetails[2]); 
                            $s_fare = $stepDetails[1];
                        }
                        
                        // 2nd: Get transportation_id
                        $sql_TranspoId = "SELECT transportation_id FROM transportation_tbl WHERE UPPER(transportation_name) = ?";
                        $stmt_TranspoId = $conn->prepare($sql_TranspoId);
                        if (!$stmt_TranspoId) {
                            throw new Exception("Error preparing Transpo ID statement: " . $conn->error);
                        }
                        $stmt_TranspoId->bind_param('s', $s_vehicle);
                        if (!$stmt_TranspoId->execute()) {
                            throw new Exception("Error executing Transpo ID statement: " . $stmt_TranspoId->error);
                        }
                        $result = $stmt_TranspoId->get_result();
                        if ($result && $result->num_rows > 0) {
                            $row = $result->fetch_assoc();
                            $transportation_id = $row['transportation_id'];
            
                            // 3rd: Insert into step_tbl
                            $sql_insertToStep = "INSERT INTO step_tbl 
                                (transportation_id, get_on, get_off, fare, instructions) 
                                VALUES (?, ?, ?, ?, ?)";
                            $stmt_insertToStep = $conn->prepare($sql_insertToStep);
                            if (!$stmt_insertToStep) {
                                throw new Exception("Error preparing step_tbl statement: " . $conn->error);
                            }
                            $stmt_insertToStep->bind_param('iiiis', $transportation_id, $previous_location_id, $s_location_id, $s_fare, $s_instructions);
            
                            if ($stmt_insertToStep->execute()) {
                                $previous_location_id = $s_location_id;
                                $step_id = $conn->insert_id;
                                echo "Step details for $stepType added successfully";
                                
                                
                                // Step 3: INSERT data to waypoint_tbl
                                $sql_insertToWaypoint = "INSERT INTO waypoint_tbl (route_suggestion_id,step_id,sequence) VALUES (?,?,?)";
                                $stmt_insertToWaypoint = $conn->prepare($sql_insertToWaypoint);
                                if (!$stmt_insertToWaypoint) {
                                throw new Exception("Error preparing waypoint_tbl statement: " . $conn->error);
                                }
                                $stmt_insertToWaypoint->bind_param('iii',$route_suggestion_id,$step_id,$stepNumber);
                                if($stmt_insertToWaypoint->execute()){
                                    echo"Waypoint added successfully";
                                    
                                    // Step 4: INSERT polyline points to step_polyline_points_tbl
                                    // $sequence = 1;
                                    // if($stepNumber <= count($lat_polylinePointsMap)&& $stepNumber <= count($long_polylinePointsMap)){
                                    //     $lats = $lat_polylinePointsMap[$stepNumber-1];  //Latitudes
                                    //     $longs = $long_polylinePointsMap[$stepNumber-1]; //Longitudes
                                    //     $indexForLong = 0;
                                    //     foreach($lats as $lat){
                                    //         $long = $longs[$indexForLong];
                                    //         $sql_insertToStepPoly = "INSERT INTO step_polyline_points_tbl (step_id, x_coordinate, y_coordinate, sequence) VALUES (?, ?, ?, ?)";
                                    //         $stmt_insertToStepPoly = $conn->prepare($sql_insertToStepPoly);
                                    //         if (!$stmt_insertToStepPoly) {
                                    //             throw new Exception("Error preparing statement: " . $conn->error);
                                    //         }

                                    //         $stmt_insertToStepPoly->bind_param('iddi', $step_id, $lat,$long, $sequence);
                                    //         if (!$stmt_insertToStepPoly->execute()) {
                                    //             throw new Exception("Error inserting data: " . $stmt_insertToStepPoly->error);
                                    //         }
                                    //         $indexForLong++;
                                    //         $sequence++;

                                    //     }
                                    // }
                                    
                                    // foreach ($polylinePointsMap as $point) {
                                    //     $lat = $point[0];  // Latitude
                                    //     $long = $point[1]; // Longitude

                                    //     $sql_insertToStepPoly = "INSERT INTO step_polyline_points_tbl (step_id, x_coordinate, y_coordinate, sequence) VALUES (?, ?, ?, ?)";
                                    //     $stmt_insertToStepPoly = $conn->prepare($sql_insertToStepPoly);
                                    //     if (!$stmt_insertToStepPoly) {
                                    //         throw new Exception("Error preparing statement: " . $conn->error);
                                    //     }

                                    //     $stmt_insertToStepPoly->bind_param('iddi', $step_id, $long, $lat, $sequence);
                                    //     if (!$stmt_insertToStepPoly->execute()) {
                                    //         throw new Exception("Error inserting data: " . $stmt_insertToStepPoly->error);
                                    //     }
                                    //     echo"polyline added successfully";

                                    //     $sequence++;
                                    // }

                                }
                                
                                
                            } else {
                                throw new Exception("Error inserting into step_tbl: " . $stmt_insertToStep->error);
                            }
                        } else {
                            throw new Exception("No transportation found for step type: $stepType");
                        }
                    
                }
                echo "Route suggestion added successfully.";
            }

                
            } else {
                echo "Error inserting into route_tbl: " . $stmt3->error;
            }
            $stmt3->close();
        } else {
            echo "Error inserting destination location: " . $stmt2->error;
        }
        $stmt2->close();
    } else {
        echo "Error inserting origin location: " . $stmt1->error;
    }
    // }

$stmt1->close();
$conn->close();
?>