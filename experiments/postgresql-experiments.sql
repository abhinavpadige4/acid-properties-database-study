-- PostgreSQL Experiments for ACID Properties Testing
-- Run these experiments in a PostgreSQL database to understand ACID properties

-- ==========================
-- EXPERIMENT 1: ATOMICITY
-- ==========================

-- Setup
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    balance DECIMAL(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts (name, balance) VALUES 
('Alice', 1000.00), 
('Bob', 500.00);

-- Test 1: Successful atomic transaction
BEGIN;
UPDATE accounts SET balance = balance - 200.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 200.00 WHERE name = 'Bob';
COMMIT;

SELECT * FROM accounts; -- Should show Alice: 800, Bob: 700

-- Reset for next test
UPDATE accounts SET balance = 1000.00 WHERE name = 'Alice';
UPDATE accounts SET balance = 500.00 WHERE name = 'Bob';

-- Test 2: Atomicity failure - constraint violation
BEGIN;
UPDATE accounts SET balance = balance - 1500.00 WHERE name = 'Alice'; -- Would make negative
-- This will fail due to CHECK constraint
UPDATE accounts SET balance = balance + 1500.00 WHERE name = 'Bob';
COMMIT; -- This won't execute due to previous error

SELECT * FROM accounts; -- Should still show Alice: 1000, Bob: 500 (rolled back)

-- Test 3: Atomicity failure - manual rollback
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
-- Simulate error condition
ROLLBACK;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob'; -- Won't execute

SELECT * FROM accounts; -- Should still show Alice: 1000, Bob: 500

-- ==========================
-- EXPERIMENT 2: CONSISTENCY
-- ==========================

-- Test constraint enforcement
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    product VARCHAR(100) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    total DECIMAL(10,2) GENERATED ALWAYS AS (quantity * price) STORED
);

-- Valid insert
INSERT INTO orders (product, quantity, price) VALUES ('Widget', 5, 10.00);
SELECT * FROM orders; -- Should show total = 50.00

-- Invalid insert - negative quantity
INSERT INTO orders (product, quantity, price) VALUES ('Gadget', -2, 15.00);
-- Should fail due to CHECK constraint

-- Invalid insert - negative price
INSERT INTO orders (product, quantity, price) VALUES ('Gadget', 2, -5.00);
-- Should fail due to CHECK constraint

-- Test trigger-based consistency
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS inventory_log;

CREATE TABLE inventory (
    product VARCHAR(50) PRIMARY KEY,
    quantity INT NOT NULL CHECK (quantity >= 0)
);

CREATE TABLE inventory_log (
    id SERIAL PRIMARY KEY,
    product VARCHAR(50),
    change_amount INT,
    new_quantity INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO inventory (product, quantity) VALUES ('Widget', 100);

-- Create trigger to maintain log
CREATE OR REPLACE FUNCTION log_inventory_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO inventory_log (product, change_amount, new_quantity)
    VALUES (OLD.product, NEW.quantity - OLD.quantity, NEW.quantity);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_change_log
AFTER UPDATE ON inventory
FOR EACH ROW EXECUTE FUNCTION log_inventory_change();

-- Test the trigger
UPDATE inventory SET quantity = 80 WHERE product = 'Widget';
SELECT * FROM inventory; -- Should show 80
SELECT * FROM inventory_log; -- Should show log entry

-- ==========================
-- EXPERIMENT 3: ISOLATION LEVELS
-- ==========================

-- Setup for isolation tests
DROP TABLE IF EXISTS isolation_test;
CREATE TABLE isolation_test (
    id SERIAL PRIMARY KEY,
    balance DECIMAL(10,2) NOT NULL
);

INSERT INTO isolation_test (balance) VALUES (1000.00);

-- Test READ COMMITTED (non-repeatable read possible)
-- In terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM isolation_test; -- Reads 1000.00

-- In terminal 2 (run separately):
BEGIN TRANSACTION;
UPDATE isolation_test SET balance = 1500.00;
COMMIT;

-- Back to terminal 1:
SELECT balance FROM isolation_test; -- May see 1500.00 (non-repeatable read)
COMMIT;

-- Reset
UPDATE isolation_test SET balance = 1000.00;

-- Test REPEATABLE READ (prevents non-repeatable reads)
-- In terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM isolation_test; -- Reads 1000.00

-- In terminal 2 (run separately):
BEGIN TRANSACTION;
UPDATE isolation_test SET balance = 2000.00;
COMMIT;

-- Back to terminal 1:
SELECT balance FROM isolation_test; -- Still sees 1000.00
COMMIT;

-- Test for phantom reads
DROP TABLE IF EXISTS phantom_test;
CREATE TABLE phantom_test (
    id SERIAL PRIMARY KEY,
    value INT
);

INSERT INTO phantom_test (value) VALUES (100), (200), (300);

-- In terminal 1 (REPEATABLE READ):
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM phantom_test WHERE value > 150; -- Returns 2

-- In terminal 2:
BEGIN TRANSACTION;
INSERT INTO phantom_test (value) VALUES (400);
COMMIT;

-- Back to terminal 1:
SELECT COUNT(*) FROM phantom_test WHERE value > 150; -- Still returns 2 (no phantom in REPEATABLE READ)
COMMIT;

-- Test SERIALIZABLE (prevents phantom reads)
-- In terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM phantom_test WHERE value > 150; -- Returns 2

-- In terminal 2:
BEGIN TRANSACTION;
INSERT INTO phantom_test (value) VALUES (500);
COMMIT;

-- Back to terminal 1:
SELECT COUNT(*) FROM phantom_test WHERE value > 150; -- Would need to retry due to serialization failure
COMMIT; -- Might fail with serialization error

-- ==========================
-- EXPERIMENT 4: DURABILITY & WAL
-- ==========================

-- Check WAL settings
SHOW wal_level;
SHOW checkpoint_timeout;
SHOW max_wal_size;
SHOW checkpoint_completion_target;

-- Force a checkpoint
CHECKPOINT;

-- Insert data and check WAL location
INSERT INTO isolation_test (balance) VALUES (2000.00);
SELECT pg_current_wal_insert_lsn(), pg_walfile_name(pg_current_wal_insert_lsn());

-- To test durability properly, you would:
-- 1. Insert data
-- 2. Force checkpoint
-- 3. Simulate crash (stop PostgreSQL)
-- 4. Restart and verify data persists
-- This requires external process control, so we'll just show the concepts

-- ==========================
-- EXPERIMENT 5: DEADLOCK DETECTION
-- ==========================

-- Setup for deadlock test
DROP TABLE IF EXISTS deadlock_test;
CREATE TABLE deadlock_test (
    id SERIAL PRIMARY KEY,
    account VARCHAR(10),
    balance DECIMAL(10,2)
);

INSERT INTO deadlock_test (account, balance) VALUES 
('A', 1000.00),
('B', 1000.00);

-- In terminal 1:
BEGIN TRANSACTION;
UPDATE deadlock_test SET balance = balance - 100 WHERE account = 'A';
-- Don't commit yet

-- In terminal 2 (run separately):
BEGIN TRANSACTION;
UPDATE deadlock_test SET balance = balance - 100 WHERE account = 'B';
-- Don't commit yet

-- Back to terminal 1:
UPDATE deadlock_test SET balance = balance + 100 WHERE account = 'B';
-- This will wait for terminal 2's lock on account B

-- In terminal 2:
UPDATE deadlock_test SET balance = balance + 100 WHERE account = 'A';
-- This will wait for terminal 1's lock on account A
-- Deadlock detected! One transaction will be rolled back

-- Check what happened
SELECT * FROM deadlock_test;

-- Clean up
ROLLBACK; -- In both terminals

-- ==========================
-- SUMMARY QUERIES
-- ==========================

-- Check current isolation level
SHOW transaction_isolation;

-- Check if we're in a transaction
SELECT txid_current() AS current_tx_id, 
       txid_snapshot_xmin(txid_current_snapshot()) AS snapshot_xmin,
       txid_snapshot_xmax(txid_current_snapshot()) AS snapshot_xmax,
       txid_snapshot_xip_list(txid_current_snapshot()) AS snapshot_xip_list;

-- Check lock information
SELECT * FROM pg_locks WHERE relation = 'accounts'::regclass;

-- Check transaction statistics
SELECT * FROM pg_stat_database WHERE datname = current_database();