#!/bin/bash
umask 022
renice 10 $$
set -e
if ! command -v git &>/dev/null || ! command -v cmake &>/dev/null; then
    apt update
    apt install -y --no-install-suggests --no-install-recommends make cmake git build-essential libusb-1.0-0-dev
fi
ipath=/usr/local/share/adsb-wiki/biastee
APPS="dump978-fa"
rm -rf $ipath
mkdir -p $ipath
cd $ipath
git clone --depth 1 https://github.com/rtlsdrblog/rtl_biast
cd rtl_biast
pushd .

mkdir build
cd build
cmake .. -DDETACH_KERNEL_DRIVER=ON
make

popd

for APP in $APPS; do
    mkdir -p /etc/systemd/system/$APP.service.d
    cat > /etc/systemd/system/$APP.service.d/bias-t.conf << "EOF"
[Service]
ExecStartPre=/usr/local/share/adsb-wiki/biastee/rtl_biast/build/src/rtl_biast -b 1
ExecStopPost=/usr/local/share/adsb-wiki/biastee/rtl_biast/build/src/rtl_biast -b 0
EOF

done

systemctl daemon-reload
for APP in $APPS; do
    if systemctl show $APP 2>/dev/null | grep -qs 'UnitFileState=enabled'; then
        echo biastee will be enabled on $APP start
        echo restarting $APP
        systemctl restart $APP || true
    fi
done

echo ----- all done ------
