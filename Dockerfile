# Setup build environment
FROM ubuntu as builder

RUN apt-get -y update
RUN apt-get -y install libevent-dev libssl-dev
RUN apt-get -y install curl wget xz-utils gcc git libz-dev libcurl4-openssl-dev
WORKDIR /tmp/ldc
RUN if [ $(uname -m) = x86_64 ]; then \
		wget https://github.com/ldc-developers/ldc/releases/download/v1.8.0/ldc2-1.8.0-linux-x86_64.tar.xz && \
		tar xf ldc2-1.8.0-linux-x86_64.tar.xz && \
		mv ldc2-1.8.0-linux-x86_64 /opt/ldc2; \
	elif [ $(uname -m) = armv7l ]; then \
		wget https://github.com/ldc-developers/ldc/releases/download/v1.8.0/ldc2-1.8.0-linux-armhf.tar.xz && \
		tar xf ldc2-1.8.0-linux-armhf.tar.xz && \
		mv ldc2-1.8.0-linux-armhf /opt/ldc2; \
	else \
		echo Unknown architecture: $(uname -m) && \
		exit 1; \
	fi
RUN ln -sf /opt/ldc2/bin/dub /usr/bin/dub

# Pre-fetch and pre-build dub dependencies to speed-up incremental builds
WORKDIR /tmp/app
RUN dub fetch vibe-d
RUN dub fetch tinyredis
RUN dub fetch libevent
RUN dub fetch diet-ng
RUN dub fetch taggedalgebraic
RUN dub fetch openssl
RUN dub fetch botan
RUN dub fetch memutils
RUN dub fetch stdx-allocator
RUN dub fetch vibe-core
RUN dub fetch libasync
RUN dub fetch botan-math
RUN dub fetch eventcore
RUN printf "/++dub.sdl: name\"foo\"\ndependency\"tinyredis\" version=\"2.1.1\"+/\n void main(){}" > foo.d; \
	dub build -b release -v --single foo.d; \
	rm -f foo*; \
	rm -rf .dub/build;
RUN printf "/++dub.sdl: name\"foo\"\ndependency\"vibe-d\" version=\"0.8.3\"+/\n void main(){}" > foo.d; \
	dub build -b release -v --single foo.d; \
	rm -f foo*; \
	rm -rf .dub/build;

# Build app
ADD source ./source
ADD dub.json ./
RUN dub build -b release

# Create final image
FROM ubuntu
RUN apt-get -y update
RUN apt-get -y install libevent-dev libssl-dev
WORKDIR /opt/app
COPY --from=builder /tmp/app/hello-redis /opt/app/
RUN useradd -ms /bin/bash myuser
USER myuser
EXPOSE 8888
CMD /opt/app/hello-redis
