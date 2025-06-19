ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Set non-interactive mode for APT
ENV DEBIAN_FRONTEND=noninteractive

# Detect distro and install packages accordingly
RUN . /etc/os-release && \
    if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then \
        apt-get update && apt-get install -y \
          build-essential cmake ninja-build git libgtkmm-3.0-dev \
          libgtksourceview-4-dev libxml++2.6-dev libsqlite3-dev gettext \
          libgspell-1-dev libcurl4-openssl-dev libuchardet-dev \
          libfribidi-dev libvte-2.91-dev libfmt-dev libspdlog-dev \
          file libxml2-utils xvfb texlive-latex-base dvipng \
          libgirepository1.0-dev gobject-introspection libglibmm-2.4-dev \
        && rm -rf /var/lib/apt/lists/*; \
    elif [ "$ID" = "fedora" ]; then \
        dnf install -y \
          gcc gcc-c++ make cmake ninja-build git gtkmm30-devel \
          gtksourceview4-devel libxml++-devel sqlite-devel gettext \
          gspell-devel libcurl-devel uchardet-devel fribidi-devel \
          vte291-devel fmt-devel spdlog-devel file libxml2 \
          xorg-x11-server-Xvfb texlive-scheme-basic texlive-dvipng \
          gobject-introspection-devel glibmm24-devel; \
    elif [ "$ID" = "arch" ]; then \
        pacman -Sy --noconfirm \
          base-devel cmake ninja git gtkmm3 gtksourceview4 \
          libxml++ sqlite gettext gspell curl uchardet fribidi \
          vte3 fmt spdlog file libxml2 xorg-server-xvfb texlive-core \
          libxml++2.6 texlive-bin gobject-introspection glibmm; \
    else \
        echo "Unsupported base image: $ID" && exit 1; \
    fi

RUN glib-compile-schemas /usr/share/glib-2.0/schemas

# Use a non-root user if necessary (UID 1000 assumed safe)
USER 1000
WORKDIR /workspace
