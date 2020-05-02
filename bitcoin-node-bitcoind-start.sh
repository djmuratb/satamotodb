#!/bin/sh
if [ -r /opt/bitcoin/.bitcoin/bitcoin.conf ]; then
    /usr/local/bin/bitcoind -datadir=/opt/bitcoin/.bitcoin -conf=bitcoin.conf
else
    echo "Missing config file '/opt/bitcoin/.bitcoin/bitcoin.conf'. Exiting.";
    exit 1;
fi