while [[ $(podman inspect --format "{{.State.Health.Status}}" demodb) != "healthy" ]]; do 
    if [[ $STATUS == "unhealthy" ]]; then
        echo "Failed to start DemoDB!"
	    exit -1
    fi
    printf .
    lf=$'\n'
    sleep 1
done
printf "$lf"
