FROM centos:7 as ffmpeg-builder
RUN yum clean all && yum install -y autoconf automake bzip2 bzip2-devel cmake curl freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

RUN mkdir /ffmpeg_sources
WORKDIR /ffmpeg_sources
RUN curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
RUN tar xjvf nasm-2.14.02.tar.bz2
WORKDIR /ffmpeg_sources/nasm-2.14.02
RUN ./autogen.sh
RUN ./configure --prefix="/ffmpeg_build" --bindir="/bin"
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
RUN tar xzvf yasm-1.3.0.tar.gz
WORKDIR /ffmpeg_sources/yasm-1.3.0
RUN ./configure --prefix="/ffmpeg_build" --bindir="/bin"
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN git clone --depth 1 http://git.videolan.org/git/x264
WORKDIR /ffmpeg_sources/x264
RUN PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/ffmpeg_build" --bindir="/bin" --enable-static
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN hg clone https://bitbucket.org/multicoreware/x265
WORKDIR /ffmpeg_sources/x265/build/linux
RUN cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN git clone --depth 1 https://github.com/mstorsjo/fdk-aac
WORKDIR /ffmpeg_sources/fdk-aac
RUN autoreconf -fiv
RUN ./configure --prefix="/ffmpeg_build" --disable-shared
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN curl -O -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
RUN tar xzvf lame-3.100.tar.gz
WORKDIR /ffmpeg_sources/lame-3.100
RUN ./configure --prefix="/ffmpeg_build" --bindir="/bin" --disable-shared --enable-nasm
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.tar.gz
RUN tar xzvf opus-1.3.tar.gz
WORKDIR /ffmpeg_sources/opus-1.3
RUN ./configure --prefix="/ffmpeg_build" --disable-shared
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
WORKDIR /ffmpeg_sources/libvpx
RUN ./configure --prefix="/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
RUN make -j$(nproc) && make install

WORKDIR /ffmpeg_sources
RUN curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
RUN tar xjvf ffmpeg-snapshot.tar.bz2
WORKDIR /ffmpeg_sources/ffmpeg
RUN PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I/ffmpeg_build/include" \
  --extra-ldflags="-L/ffmpeg_build/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir="/bin" \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
RUN make -j$(nproc) && make install
RUN hash -d ffmpeg

FROM alpine
VOLUME /out
COPY --from=ffmpeg-builder /bin/ffmpeg /ffmpeg
CMD ["cp", "-v", "/ffmpeg", "/out/ffmpeg"]
