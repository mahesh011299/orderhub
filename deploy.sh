#!/bin/bash
NEW_IMAGE=$1
ROLLBACK_IMAGE=$2
DEPLOY_PORT=5000

echo "Starting deployment of: ${NEW_IMAGE} on port ${DEPLOY_PORT}"

# Stop existing container if present
docker stop orderhub 2>/dev/null || true
docker rm orderhub 2>/dev/null || true

# Run new container mapping host port 5000 to container port 8080
docker run -d --name orderhub -p ${DEPLOY_PORT}:8080 ${NEW_IMAGE}

# Wait and test health
echo "Performing health smoke check..."
sleep 5
STATUS=$(curl -s http://localhost:5000/health | grep '"status":"UP"')

if [ -n "$STATUS" ]; then
    echo "Deployment successful: ${NEW_IMAGE} is healthy on port ${DEPLOY_PORT}!"
    exit 0
else
    echo "CRITICAL: Health check failed! Initiating rollback to ${ROLLBACK_IMAGE}..."
    docker stop orderhub
    docker rm orderhub
    docker run -d --name orderhub -p ${DEPLOY_PORT}:8080 ${ROLLBACK_IMAGE}
    echo "Rollback restored to: ${ROLLBACK_IMAGE}"
    exit 1
fi