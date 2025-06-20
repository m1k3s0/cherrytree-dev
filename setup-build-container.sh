#!/usr/bin/env bash

set -e
unset HISTFILE
set +o history

# Select distro image to build with
echo "Select base image:"
select IMAGE_CHOICE in "ubuntu:24.04" "debian:stable" "fedora:latest" "docker.io/library/archlinux:latest"; do
    case $IMAGE_CHOICE in
        ubuntu:24.04|debian:stable|fedora:latest|docker.io/library/archlinux:latest)
            BASE_IMAGE="$IMAGE_CHOICE"
            break
            ;;
        *)
            echo "Invalid choice. Choose 1-4."
            ;;
    esac
done

IMAGE_NAME="cpp-build-${BASE_IMAGE//[:\/]/-}"
CONTAINER_NAME="cpp-build-container"

# Check for required build tools
# -------------------------------------------------------------
# podman is used to set up a container using Dockerfile
# uidmap provides newuidmap & newgidmap needed for container namespace mapping
# slirp4netns is needed for a rootless container network
# runtime libs needed for running CT binary
REQUIRED_TOOLS=(podman uidmap slirp4netns)
RUNTIME_LIBS_DEB=(libgtksourceview-4-0 libgspell-1-2 libfmt9)
RUNTIME_LIBS_RHEL=(gtksourceview4 gspell fmt)
RUNTIME_LIBS_ARCH=(gtksourceview4 gspell fmt)

MISSING_PACKAGES=()

# Check for required tools
for pkg in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

# Append runtime libs based on distro
if [ -f /etc/debian_version ]; then
    MISSING_PACKAGES+=("${RUNTIME_LIBS_DEB[@]}")
elif [ -f /etc/redhat-release ]; then
    MISSING_PACKAGES+=("${RUNTIME_LIBS_RHEL[@]}")
elif [ -f /etc/arch-release ]; then
    MISSING_PACKAGES+=("${RUNTIME_LIBS_ARCH[@]}")
else
    echo "Unsupported distro. Please install the following packages manually:"
    echo "${REQUIRED_TOOLS[*]}"
    echo "<plus distro-specific GTK/GSpell/Libfmt packages>"
    exit 1
fi

# Install missing packages
if [ -f /etc/debian_version ]; then
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}"
elif [ -f /etc/redhat-release ]; then
    sudo dnf install -y "${MISSING_PACKAGES[@]}"
elif [ -f /etc/arch-release ]; then
    sudo pacman -Syu --noconfirm "${MISSING_PACKAGES[@]}"
fi

echo "Building container image ($BASE_IMAGE)…"
podman build \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    -t "$IMAGE_NAME" \
    -f .devcontainer/Dockerfile .

echo "Launching container..."
podman run -it --rm \
    --userns=keep-id \
    --name "$CONTAINER_NAME" \
    -v "$(pwd)":/workspace \
    -w /workspace \
    "$IMAGE_NAME" \
    ./post_setup.sh
    
echo "Cleaning up..."
# Remove container (if it still exists)
podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
# Remove image
podman rmi -f "$IMAGE_NAME" 2>/dev/null || true

read -p "Would you like to run your freshly built CherryTree? [Y/n] " RUN
RUN=${RUN:-Y}

if [[ "$RUN" =~ ^[Yy]$ ]]; then
    ./build/cherrytree
else
    exit 0
fi
