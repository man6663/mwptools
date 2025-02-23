#!/usr/bin/env bash

INSTDIR=${MESON_INSTALL_PREFIX}
if [ -n "$DESTDIR" ] ; then
    INSTDIR=${DESTDIR}/${MESON_INSTALL_PREFIX}
fi

ln -f ${INSTDIR}/bin/fc-get  ${INSTDIR}/bin/fc-set

# Additional programs, without whinging
for FN in bproxy ublox-geo ublox-cli flashdl ; do
    if [ -e  $MESON_BUILD_ROOT/$FN ] ; then
	rm -f $INSTDIR/bin/$FN
	install -C $MESON_BUILD_ROOT/$FN $INSTDIR/bin
    fi
done

if [ -e ${MESON_SOURCE_ROOT}/src/mwp-plot-elevations/mwp-plot-elevations ] ; then
    install ${MESON_SOURCE_ROOT}/src/mwp-plot-elevations/mwp-plot-elevations  $INSTDIR/bin
fi

if [ -z $DESTDIR ]; then
  echo Compiling gsettings schemas...
  glib-compile-schemas $MESON_INSTALL_PREFIX/share/glib-2.0/schemas

  echo Updating desktop icon cache...
  gtk-update-icon-cache -qtf $MESON_INSTALL_PREFIX/share/icons/hicolor
fi
