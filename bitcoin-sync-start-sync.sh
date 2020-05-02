#!/bin/bash
while ! curl satamotodb_postgres:5432 2>&1 | grep -sq 'Empty reply from server'; do
    echo 'Postgres still not ready; sleeping 5s';
    sleep 5;
done

while ! curl --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockcount", "params": [] }' -H 'content-type: text/plain;' http://satamoto:satamoto@satamotodb_bitcoin_node:8332/ 2>&1 | grep -sq '"error":null'; do
    echo 'Bitcoind still not ready; sleeping 5s';
    sleep 5;
done

node dist/src/app.js;
# Block from exiting and terminating container
tail -f /dev/null;