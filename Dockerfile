# Base Jenkins image with JDK 17
FROM jenkins/jenkins:lts-jdk17

USER root

# -----------------------------
# Install Node.js 18 LTS and common tools
# -----------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs unzip wget curl git zip tar \
    && echo "Node.js installed:" && node -v \
    && echo "npm installed:" && npm -v

# -----------------------------
# Optional: Install a fresh JDK 17 (if you want a custom path)
# -----------------------------
# RUN wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11+9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz \
#     && mkdir -p /opt/jdk17 \
#     && tar -xzf OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz -C /opt/jdk17 --strip-components=1 \
#     && rm OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz
# ENV JAVA_HOME=/opt/jdk17
# ENV PATH="${JAVA_HOME}/bin:${PATH}"

# -----------------------------
# Verify Java 17
# -----------------------------
RUN echo "Java version:" && java -version \
    && echo "Javac version:" && javac -version

# -----------------------------
# Install Android SDK command-line tools
# -----------------------------
RUN mkdir -p /opt/android-sdk/cmdline-tools \
    && cd /opt/android-sdk/cmdline-tools \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip commandlinetools-linux-9477386_latest.zip \
    && rm commandlinetools-linux-9477386_latest.zip \
    && mv cmdline-tools latest

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# -----------------------------
# Install Android SDK packages
# -----------------------------
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# -----------------------------
# Set ownership for Jenkins
# -----------------------------
RUN chown -R jenkins:jenkins /opt/android-sdk

USER jenkins
