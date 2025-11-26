
FROM jenkins/jenkins:lts-jdk11
USER root

# Install Node.js, npm, Gradle, and tools
RUN apt-get update && apt-get install -y nodejs npm unzip wget curl gradle

# Install Android SDK command-line tools
RUN mkdir -p /opt/android-sdk && cd /opt/android-sdk \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip commandlinetools-linux-9477386_latest.zip

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/bin:$ANDROID_HOME/platform-tools

USER jenkins
