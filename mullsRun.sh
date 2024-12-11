#!/bin/bash

rosbag_location=$1
output_dir=$2
lidar_type=$3
pointcloud_topic=$4
outputName=$5
configFile=$6

run_and_source() {
	docker exec ${containerID} /bin/bash -c "$1"
}

if [ "${configFile}" = "kitti" ]; then
    config="/mulls/script/config/lo_gflag_list_kitti_ultrafast.txt"

elif [ "${lidar_type}" = "VLP-16" ]; then
    config="/mulls/script/config/lo_gflag_list_16.txt"

elif [ "${configFile}" = "mulran" ]; then
    config="/mulls/script/config/lo_gflag_list_newer_college.txt"

else
    config="/mulls/script/config/lo_gflag_list_example_demo.txt"
fi

containerID=$(docker run -dit --rm \
    --mount type=bind,source="$rosbag_location",target=/data/$(basename "$rosbag_location") \
    --mount type=bind,source="$output_dir",target=/results mulls-mulls)

run_and_source "mkdir -p /tmp/data"
run_and_source "mkdir -p /tmp/data/pcd"
run_and_source "bash /mulls/script/tools/rosbag2pcd.sh /data /tmp/data/pcd '$pointcloud_topic'"

run_and_source "bash /mulls/script/run_mulls_slam.sh /tmp/data $outputName $config"

run_and_source "python3.8 /mulls/timestamp.py /tmp/data/result/timing_table_$outputName.txt /tmp/timestamp.txt"
run_and_source "python3.8 /mulls/kitti_to_tum.py /tmp/data/result/pose_b_lo_$outputName.txt /tmp/timestamp.txt /results/$outputName.tum"

docker stop $containerID
