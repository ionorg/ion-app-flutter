FROM ubuntu:20.04

# For Chinese users:
# Due to the blocking of GFW firewall, please use the mirror address in ubuntu sources and flutter pub repo.
# uncomment the line below.
# ENV PUB_HOSTED_URL https://pub.flutter-io.cn
# ENV FLUTTER_STORAGE_BASE_URL https://storage.flutter-io.cn
# RUN sed -i s@/archive.ubuntu.com/@/mirrors.163.com/@g /etc/apt/sources.list \
#     && sed -i '/security.ubuntu.com/d' /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y --fix-missing \
    && DEBIAN_FRONTEND="noninteractive" apt install -y tzdata ca-certificates \
    netcat curl git unzip xz-utils zip libglu1-mesa openjdk-8-jdk wget

# Set up new user
RUN useradd -ms /bin/bash developer
USER developer
WORKDIR /home/developer

# Prepare Android directories and system variables
RUN mkdir -p Android/sdk
ENV ANDROID_SDK_ROOT /home/developer/Android/sdk
RUN mkdir -p .android && touch .android/repositories.cfg

# Set up Android SDK
RUN wget -O sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
RUN unzip sdk-tools.zip && rm sdk-tools.zip
RUN mv tools Android/sdk/tools
RUN cd Android/sdk/tools/bin && yes | ./sdkmanager --licenses
RUN cd Android/sdk/tools/bin && ./sdkmanager "build-tools;29.0.2" "patcher;v4" "platform-tools" "platforms;android-29" "sources;android-29"
ENV PATH "$PATH:/home/developer/Android/sdk/platform-tools"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable --depth=1
ENV PATH "$PATH:/home/developer/flutter/bin"

# Run basic check to download Dark SDK
RUN flutter doctor
RUN flutter precache

RUN mkdir -p src
WORKDIR /home/developer/src
COPY pubspec.yaml ./
RUN flutter pub get

ENTRYPOINT [ "/home/developer/flutter/bin/flutter" ]

# COPY assets/ assets/
# COPY lib/ lib/
# COPY web/ web/
# RUN flutter build web