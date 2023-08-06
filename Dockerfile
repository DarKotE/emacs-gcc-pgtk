FROM ubuntu:22.04
WORKDIR /opt
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list &&\
    apt-get update && apt-get install --yes --no-install-recommends  \
    apt-transport-https\
    ca-certificates\
    build-essential \
    autoconf \
    git \
    pkg-config \
    libgnutls28-dev \
    libasound2-dev \
    libacl1-dev \
    libgtk-3-dev \
    libgpm-dev \
    liblockfile-dev \
    libotf-dev \
    libsystemd-dev \
    libjansson-dev \
    libgccjit-11-dev \
    libgif-dev \
    librsvg2-dev  \
    libxml2-dev \
    libxpm-dev \
    libtiff-dev \
    libjbig-dev \
    libncurses-dev\
    liblcms2-dev\
    libwebp-dev\
    libsqlite3-dev\
    texinfo\
    libwebkit2gtk-4.0-dev \
    libtree-sitter-dev


# Clone emacs
RUN update-ca-certificates \
    && git clone --depth 1 https://git.savannah.gnu.org/git/emacs.git -b emacs-29 emacs \
    && mv emacs/* .

# Build
ENV CC="gcc-11"
RUN ./autogen.sh && ./configure \
    --prefix "/usr/local" \
    --with-included-regex \
    --with-small-ja-dic \
    --with-pgtk \
    --with-json \
    --with-gnutls  \
    --with-rsvg  \
    --with-xwidgets \
    --with-xaw3d \
    --without-mailutils \
    --without-pop \
    --without-dbus \
    --without-gpm \
    --with-native-compilation=aot \
    CFLAGS="-Ofast -fno-finite-math-only -fomit-frame-pointer"



RUN make -j $(nproc)

# Create package
RUN EMACS_VERSION=$(sed -ne 's/AC_INIT(\[GNU Emacs\], \[\([0-9.]\+\)\], .*/\1/p' configure.ac).$(date +%y.%m.%d.%H) \
    && make install prefix=/opt/emacs-gcc-pgtk_${EMACS_VERSION}/usr/local \
    && mkdir emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN && echo "Package: emacs-gcc-pgtk\n\
Version: ${EMACS_VERSION}\n\
Section: base\n\
Priority: optional\n\
Architecture: amd64\n\
Depends: libtree-sitter0, libgif7, libotf1, libgccjit0, libgtk-3-0, librsvg2-2, libtiff5, libjansson4, libacl1, libgmp10, libwebp7, webp, libsqlite3-0, libharfbuzz0b, libncurses5, libjpeg9, libpng16-16, libwebkit2gtk-4.0-37\n\
Conflicts: emacs\n\
Maintainer: konstare\n\
Description: Emacs with native compilation, pure GTK and tree-sitter\n\
    --with-pgtk \
    --with-json \
    --with-gnutls  \
    --with-rsvg  \
    --with-xwidgets \
    --with-xaw3d \
    --without-mailutils \
    --without-gsettings \
    --without-pop \
    --without-dbus \
    --without-gpm \
    --with-native-compilation=aot\
 CFLAGS='-Ofast -fno-finite-math-only -fomit-frame-pointer'" \
    >> emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN/control \
    && echo "activate-noawait ldconfig" >> emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN/triggers \
    && cd /opt \
    && dpkg-deb --build emacs-gcc-pgtk_${EMACS_VERSION} \
    && mkdir /opt/deploy \
    && mv /opt/emacs-gcc-pgtk_*.deb /opt/deploy
