#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker not found. Please install Docker."
    exit 1
fi

# Get all running container IDs
container_ids=$(docker ps -q)

if [ -z "$container_ids" ]; then
  echo "No running containers found."
  exit 0
fi

# Loop through each container ID
for container_id in $container_ids
do
  # Get the container name
  container_name=$(docker inspect --format '{{.Name}}' "$container_id" | cut -c 2-)

  # Get the OS distribution and version from /etc/os-release
  os_release_info=$(docker exec "$container_id" cat /etc/os-release 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "Could not retrieve OS info for container $container_name"
    continue
  fi

  # Extract and print the OS information
  distro_name=$(echo "$os_release_info" | grep '^NAME=' | awk -F= '{print $2}' | tr -d '"')

  echo "Container: $container_name"
  echo "$os_release_info" | grep -E 'PRETTY_NAME|NAME|VERSION'

  # If Debian-based, check for more details
  if [[ "$distro_name" == *"Debian"* || "$distro_name" == *"Ubuntu"* ]]; then
    # Debian version
    debian_version=$(docker exec "$container_id" cat /etc/debian_version 2>/dev/null)
    if [ -n "$debian_version" ]; then
      echo "Debian version: $debian_version"
    fi

    # Kernel version
    kernel_version=$(docker exec "$container_id" uname -r 2>/dev/null)
    if [ -n "$kernel_version" ]; then
      echo "Kernel version: $kernel_version"
    fi

    # libc version (common system library version)
    libc_version=$(docker exec "$container_id" dpkg -s libc6 2>/dev/null | grep '^Version:' | awk '{print $2}')
    if [ -n "$libc_version" ]; then
      echo "libc version: $libc_version"
    fi
  fi

  echo "------------------------------------"
done
