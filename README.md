# Satamotodb Bitcoin project

## Summary

The satamotodb project serves as the umbrella project that orchstrates the necessary containers depending on functionality we want to support.

The main goals are always:

* export the data (blocks, txs, inputs, outputs, addresses etc.) of a blockchain (e.g. Bitcoin) into a Postgres relation database (for example for Bitcoin see [satamotodb-bitcoin-sync](https://github.com/tka85/satamotodb-bitcoin-sync))
* expose the blockchain data in the database over a REST API (for example see [satamotodb-rest](https://github.com/tka85/satamotodb-rest))

## Architecture

Generic architecture that supports multiple blockchains:

![Satamotodb components](./architecture.svg "Architecture of satamotodb project")

## Bitcoin blockchain

Satamotodb setup for Bitcoin uses the images:

* [postgres](https://hub.docker.com/layers/postgres/library/postgres/10.12/images/sha256-f744251a8bd2055a96862ce3c037cb87368522a7ad0d9b2d1eedc235e0a28327)
* [satamotodb-rest](https://hub.docker.com/repository/docker/tka85/satamotodb-rest)
* [satamotodb-bitcoin-node](https://hub.docker.com/repository/docker/tka85/satamotodb-bitcoin-node)
* [satamotodb-bitcoin-sync](https://hub.docker.com/repository/docker/tka85/satamotodb-bitcoin-sync)

The docker-compose.yml creates containers:

* `satamotodb_postgres`: database for blockchian data (single database across all blockchains)
* `satamotodb_rest`: Node.js application that exposes database blockchain data over a REST API (single instance across all blockchains)
* `satamotodb_bitcoin_node`: node that runs bitcoind (blockchain specific)
* `satamotodb_bitcoin_sync`: Node.js application that syncs the Postgres database with the latest blockchain data (blockchain specific)

## Preparation

### Required edit: select a bitcoin.conf

You need to edit in `docker-compose.yml` the `volumes` section of service `satamotodb_bitcoin_node`.

Uncomment only one of the three lines (`bitcoin-node-mainnet.conf`, `bitcoin-node-testnet.conf` or `bitcoin-node-regtest.conf`) that mounts the `bitcoin.conf`, depending on which blockchain data you want to collect.

### Optional edit: mount locally synced blockchain data

If you have locally synced blockchain data you can mount it so bitcoind can use it instead of syncing from scratch. To do so, unncomment and edit accordingly one of the two lines that mounts the chain data depending again on the netowrk.

If you don't have locally synced blockchain data, bitcoind will sync the chain data from scratch.

## Execution

Start the containers:

```bash
docker-compose up
```

Container `satamotodb_bitcoin_sync` automatically initiates a continuous syncing of the database with the latest blockchain data from bitcoind.

In the database all amounts are in Satoshis and all timestamps are either in epoch or in UTC.

You can always attach to the container and stop the syncing:

```bash
docker exec -it satamotodb_bitcoin_sync /bin/bash
kill -TERM [PID of process `node dist/src/app.js`]
```

The next time the syncing starts, it will begin from the most recent valid block. Since all database operations use transactions, a block will never by half-synced even if the application is abrubtly terminated.

## Connecting to Postgresql

Attach to the container `satamotodb_postgres` and connect using `psql`:

```bash
docker exec -it satamotodb_postgres /bin/bash
psql -U satamoto -d satamoto
```

### Optional wallet table

The database table `wallet` is for populating it with your own wallet's addresses so you can do queries like:

* evaluate your balance
* get the set of your unspents

## Change default passwords

You can secure bitcoind and Postgres beyond the default passwords that come in `bitcoin-sync-rpcConfig.json` and `bitcoin-sync-dbConfig.json` respectively.

NOTE: new passwords need to be set **before first run**.

### Setting bitcoind password

* Set new password in `bitcoin-sync-rpcConfig.json` and
* in one of `bitcoin-node-mainnet.conf`, `bitcoin-node-testnet.conf` or `bitcoin-node-regtest.conf` depending on which network you will be using
* and in `bitcoin-sync-start-sync.sh` change `http://satamoto:satamoto@...` to `http://satamoto:NEW_PASSWORD_HERE@...`

### Setting Postgresql password

* Set it in `docker-compose.yml` as value of env variable `POSTGRES_PASSWORD` of service `satamotodb_postgres`
* and also in `bitcoin-sync-dbConfig.json`
