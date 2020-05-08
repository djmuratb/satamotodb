CREATE TYPE typeof_btc_address AS ENUM (
    'legacy',
    'p2sh-segwit',
    'bech32'
);

CREATE TYPE typeof_btc_script AS ENUM (
    'pubkey',
    'pubkeyhash',
    'scripthash',
    'multisig',
    'nulldata',
    'witness_v0_keyhash',
    'witness_v0_scripthash',
    'witness_unknown',
    'nonstandard'
);

CREATE TABLE IF NOT EXISTS branch_btc (
    _branch_serial serial PRIMARY KEY,
    _fork_height integer NOT NULL,
    _time bigint DEFAULT EXTRACT(EPOCH FROM NOW()),
    _parent_branch_serial integer
);

INSERT INTO branch_btc (_fork_height, _time)
    VALUES (0, 1231006505);

CREATE TABLE IF NOT EXISTS block_btc (
    _block_serial serial PRIMARY KEY,
    _branch_serial integer,
    blockhash text NOT NULL,
    strippedsize bigint,
    size bigint,
    weight bigint,
    height integer,
    version integer,
    versionhex text,
    merkleroot text,
    time bigint,
    mediantime bigint,
    nonce bigint,
    bits text,
    difficulty text,
    chainwork text,
    ntx integer,
    previousblockhash text,
    seq bigint, -- coinbase tx
    coinbase text, -- coinbase tx
    _is_valid boolean NOT NULL,
    UNIQUE (blockhash),
    UNIQUE (_block_serial, _is_valid)
);

CREATE TABLE IF NOT EXISTS tx_btc (
    _tx_serial serial PRIMARY KEY,
    _block_serial bigint NOT NULL,
    txid text NOT NULL,
    hash text, -- differs from txid for witness txs
    version integer,
    size bigint,
    vsize bigint, -- differs from size for witness txs
    weight bigint,
    locktime bigint,
    hex text,
    _is_coinbase boolean,
    _is_valid boolean NOT NULL,
    _fee bigint,
    UNIQUE (_tx_serial, _is_valid)
);

CREATE TABLE IF NOT EXISTS output_btc (
    _output_serial serial PRIMARY KEY,
    _tx_serial bigint NOT NULL,
    vout integer NOT NULL,
    value bigint,
    reqsigs integer,
    scriptasm text,
    scripthex text,
    scripttype typeof_btc_script,
    _is_spent boolean DEFAULT FALSE,
    _spent_by_input_serial bigint,
    _is_valid boolean NOT NULL,
    UNIQUE (_output_serial, _is_valid)
);

CREATE TABLE IF NOT EXISTS output_address_btc (
    _addr_serial serial PRIMARY KEY,
    _output_serial bigint NOT NULL,
    addr text NOT NULL,
    addr_idx integer NOT NULL, -- it can be that the same address apears more than once in single addresses[] of an output
    addrtype typeof_btc_address,
    _is_valid boolean NOT NULL
);

CREATE TABLE IF NOT EXISTS input_btc (
    _input_serial serial PRIMARY KEY,
    _tx_serial bigint NOT NULL,
    vin integer NOT NULL,
    _out_output_serial bigint NOT NULL, -- the serial of the output this input corresponds to
    out_value bigint,
    seq bigint,
    scriptasm text,
    scripthex text,
    txinwitness text[],
    _is_valid boolean NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_btc (
    _wallet_addr_serial serial PRIMARY KEY,
    walletaddr text NOT NULL,
    walletaddrtype typeof_btc_address,
    walletname text
);

-- To speed up things, postpone all foreign key constraints until after the db has been populated with the blockchain data
-- ALTER TABLE branch_btc ADD FOREIGN KEY (_parent_branch_serial) REFERENCES branch_btc (_branch_serial) MATCH FULL ON UPDATE RESTRICT;
-- ALTER TABLE block_btc ADD FOREIGN KEY (_branch_serial) REFERENCES branch_btc (_branch_serial) MATCH FULL ON DELETE RESTRICT ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;
-- ALTER TABLE block_btc ADD FOREIGN KEY (previousblockhash) REFERENCES block_btc (blockhash) MATCH FULL ON UPDATE RESTRICT;
-- ALTER TABLE tx_btc ADD FOREIGN KEY (_block_serial, _is_valid) REFERENCES block_btc (_block_serial, _is_valid) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
-- ALTER TABLE output_btc ADD FOREIGN KEY (_tx_serial, _is_valid) REFERENCES tx_btc (_tx_serial, _is_valid) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
-- ALTER TABLE output_address_btc ADD FOREIGN KEY (_output_serial, _is_valid) REFERENCES output_btc (_output_serial, _is_valid) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
-- ALTER TABLE input_btc ADD FOREIGN KEY (_tx_serial, _is_valid) REFERENCES tx_btc (_tx_serial, _is_valid) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
-- ALTER TABLE input_btc ADD FOREIGN KEY (_out_output_serial) REFERENCES output_btc (_output_serial) MATCH FULL ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
-- ALTER TABLE output_btc ADD FOREIGN KEY (_spent_by_input_serial) REFERENCES input_btc (_input_serial) MATCH SIMPLE ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
