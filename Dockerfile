# SWL 1.3 uses a legacy, 32-bit runtime. Pinning linux/386 is
# intentional: SWL 1.3 does not support 64-bit or threaded Chez Scheme.
FROM i386/ubuntu:16.04@sha256:bcb8397f1390f4f0757ca06ce184f05c8ce0c7a4b5ff93f9ab029a581192917b

ARG DEBIAN_FRONTEND=noninteractive
ARG PETITE_URL=https://scheme.com/download/pcsv8.4-i3le.tar.gz
ARG PETITE_SHA256=4f2068caea72e79e8cdd8906fc1ac4ceb7d5f0c6092c61a26022eb5c63c31fb3
ARG SWL_URL=https://scheme.com/download/swl1.3-src.tar.gz
ARG SWL_SHA256=ca159b063c7d88e42c3149cadda9b943c376287684694f8b70e6a6341e74c0a7

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Ubuntu 16.04 supplies the Tcl/Tk 8.5 ABI used by the official SWL 1.3
# binary. Its i386 package indexes remain on the standard Ubuntu mirrors.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      fluxbox \
      make \
      novnc \
      tcl8.5 \
      tk8.5 \
      websockify \
      x11vnc \
      xfonts-base \
      xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/install

# Install the exact Petite Chez Scheme release referenced by this course.
RUN curl -L --fail --silent --show-error -o petite.tar.gz "${PETITE_URL}" \
    && echo "${PETITE_SHA256}  petite.tar.gz" | sha256sum -c - \
    && tar -xzf petite.tar.gz \
    && cd csv8.4/custom \
    && ./configure --machine=i3le --installprefix=/usr --noforce-relink \
    && make install \
    && printf '(unless (and (string=? (scheme-version) "Petite Chez Scheme Version 8.4") (eq? (machine-type) (quote i3le)) (petite?) (not (threaded?))) (exit 1))(exit 0)\n' | petite -q

# Ubuntu uses Debian's shared-data layout, while SWL's 2009 installer
# expects the historical /usr/lib Tcl/Tk paths.
RUN if [[ ! -e /usr/lib/tcl8.5 ]]; then ln -s /usr/share/tcltk/tcl8.5 /usr/lib/tcl8.5; fi \
    && if [[ ! -e /usr/lib/tk8.5 ]]; then ln -s /usr/share/tcltk/tk8.5 /usr/lib/tk8.5; fi \
    && ln -sf /usr/bin/tclsh8.5 /usr/local/bin/tclsh

# Install the official SWL 1.3 prebuilt i3le boot file and shared object.
RUN curl -L --fail --silent --show-error -o swl.tar.gz "${SWL_URL}" \
    && echo "${SWL_SHA256}  swl.tar.gz" | sha256sum -c - \
    && tar -xzf swl.tar.gz \
    && cd swl1.3 \
    && make install \
    && test -f /usr/lib/swl1.3/i3le/swl.boot \
    && test -f /usr/lib/swl1.3/i3le/swl.so \
    && rm -rf /tmp/install

# Opening the noVNC port in a browser must go straight to the desktop. Fail
# the build if the pinned image's expected noVNC layout ever changes.
RUN test -f /usr/share/novnc/vnc_auto.html \
    && ln -sfn vnc_auto.html /usr/share/novnc/index.html \
    && test "$(readlink /usr/share/novnc/index.html)" = vnc_auto.html \
    && useradd --create-home --shell /bin/bash --uid 1000 student \
    && mkdir -p /workspace \
    && chown student:student /workspace

COPY --chmod=0755 entrypoint.sh /usr/local/bin/scheme-swl-entrypoint
COPY examples /opt/scheme-swl/examples
COPY browser-fit.js /usr/share/novnc/include/browser-fit.js
RUN sed -i '/<\/body>/i\    <script src="include/browser-fit.js"></script>' /usr/share/novnc/vnc_auto.html

ENV DISPLAY=:99 \
    HOME=/home/student

USER student
WORKDIR /workspace

EXPOSE 6000

ENTRYPOINT ["/usr/local/bin/scheme-swl-entrypoint"]
