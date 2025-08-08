FROM ubuntu:22.04 as flutter-base

# Set environment variables
ENV FLUTTER_HOME="/opt/flutter"
ENV DART_SDK="/opt/flutter/bin/cache/dart-sdk"
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV PATH="${PATH}:${FLUTTER_HOME}/bin:${DART_SDK}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin"
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    python3 \
    python3-pip \
    nodejs \
    npm \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create flutter user
RUN useradd -m -s /bin/bash flutter && \
    usermod -aG sudo flutter

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    cd ${FLUTTER_HOME} && \
    git checkout stable && \
    chown -R flutter:flutter ${FLUTTER_HOME}

# Install Android SDK (optional for mobile development)
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -O commandlinetools.zip "https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip" && \
    unzip commandlinetools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm commandlinetools.zip && \
    chown -R flutter:flutter ${ANDROID_SDK_ROOT}

# Switch to flutter user
USER flutter
WORKDIR /home/flutter

# Configure Flutter
RUN flutter config --no-analytics && \
    flutter doctor

# Install Python packages for AI development
RUN pip3 install --user \
    langchain \
    openai \
    anthropic \
    google-generativeai \
    firebase-admin

SHELL ["/bin/bash", "-c"]
