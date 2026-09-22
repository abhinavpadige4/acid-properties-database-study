# Day 2: Isolation and Concurrency Control

## Isolation

### Definition
Isolation controls how and when changes made by one transaction become visible to other concurrent transactions, preventing interference.

### The Problem
Without proper isolation, concurrent transactions can interfere with each other, leading to inconsistent database states.

### Isolation Levels
ANSI SQL standard defines four isolation levels, each preventing certain types of anomalies:

## Concurrency Anomalies

### 1. Dirty Read
**Definition**: A transaction reads data that has been written by another concurrent transaction that has not yet been committed.

**Scenario**:
- Time T1: Transaction T1 reads row R (value = 100)
- Time T2: Transaction T2 updates row R to 200 (uncommitted)
- Time T3: Transaction T1 reads row R again (value = 200)
- Time T4: Transaction T2 rolls back (row R restored to 100)
- **Problem**: T1 read uncommitted data that was later rolled back

**Example**:
```
Account balance = $1000
T1: READ balance ($1000)
T2: UPDATE balance = $1500 (uncommitted)
T1: READ balance ($1500)  // Dirty read!
T2: ROLLBACK  // Balance actually $1000
T1: Made decision based on $1500 (incorrect)
```

### 2. Non-Repeatable Read
**Definition**: A transaction re-reads data it has previously read and finds that data has been modified by another committed transaction.

**Scenario**:
- Time T1: Transaction T1 reads row R (value = 100)
- Time T2: Transaction T2 updates row R to 150 and commits
- Time T3: Transaction T1 reads row R again (value = 150)
- **Problem**: T1 got different values for same query

**Example**:
```
T1: SELECT salary FROM employees WHERE id = 123  // Returns $5000
T2: UPDATE employees SET salary = $5500 WHERE id = 123; COMMIT;
T1: SELECT salary FROM employees WHERE id = 123  // Returns $5500
```
T1 sees inconsistent data for same employee

### 3. Phantom Read
**Definition**: A transaction re-executes a query returning a set of rows that satisfy a search condition and finds that the set of rows has changed due to another committed transaction.

**Scenario**:
- Time T1: Transaction T1 executes query Q (returns 5 rows)
- Time T2: Transaction T2 inserts new row that satisfies Q and commits
- Time T3: Transaction T1 executes query Q again (returns 6 rows)
- **Problem**: T1 got different number of rows for same query

**Example**:
```
T1: SELECT * FROM orders WHERE amount > $1000  // Returns 5 orders
T2: INSERT INTO orders VALUES (..., $1500); COMMIT;
T1: SELECT * FROM orders WHERE amount > $1000  // Returns 6 orders
```
T1 sees phantom order that wasn't there initially

## Isolation Levels Explained

### Level 1: READ UNCOMMITTED
- **Allows**: Dirty reads, non-repeatable reads, phantom reads
- **Prevents**: Nothing
- **Implementation**: No read locks, can read uncommitted data
- **Use case**: Rarely used (only when absolute consistency isn't required)
- **Performance**: Highest concurrency, lowest consistency

### Level 2: READ COMMITTED
- **Allows**: Non-repeatable reads, phantom reads
- **Prevents**: Dirty reads
- **Implementation**: 
  - Read only committed data (acquire shared lock, read, release immediately)
  - Or use MVCC to read snapshot of committed data
- **Use case**: Default in Oracle, SQL Server
- **Performance**: Good balance of concurrency and consistency

### Level 3: REPEATABLE READ
- **Allows**: Phantom reads
- **Prevents**: Dirty reads, non-repeatable reads
- **Implementation**:
  - Hold shared locks on all read data until transaction ends
  - Or use MVCC with repeatable read snapshot
- **Use case**: Default in MySQL InnoDB
- **Performance**: Moderate concurrency, good consistency

### Level 4: SERIALIZABLE
- **Allows**: Nothing (highest isolation)
- **Prevents**: Dirty reads, non-repeatable reads, phantom reads
- **Implementation**:
  - Range locks: Lock not just accessed rows, but ranges that could produce phantom rows
  - Predicate locking: Lock based on WHERE clause conditions
  - Or use Serializable snapshot isolation (SSI)
- **Use case**: Financial systems requiring absolute consistency
- **Performance**: Lowest concurrency, highest consistency

## Concurrency Control Mechanisms

### Locking-Based Concurrency Control

#### Lock Types
1. **Shared Lock (S)**:
   - Allows multiple transactions to read same data
   - Blocks writers (exclusive locks)
   - Compatible with other shared locks

2. **Exclusive Lock (X)**:
   - Allows one transaction to write data
   - Blocks all readers and writers
   - Not compatible with any other lock

3. **Update Lock (U)**:
   - Used during update to prevent deadlocks
   - Compatible with shared locks, not with other update/exclusive locks

#### Locking Protocols

##### Two-Phase Locking (2PL)
- **Growing Phase**: Transactions can acquire locks but cannot release any
- **Shrinking Phase**: Transactions can release locks but cannot acquire any
- **Guarantees**: Serializability if followed strictly

##### Strict Two-Phase Locking (Strict 2PL)
- Like 2PL but exclusive locks held until transaction commit
- **Prevents**: Cascading rollbacks
- **Used by**: Most commercial databases

##### Rigorous Two-Phase Locking (Rigorous 2PL)
- All locks (shared and exclusive) held until transaction commit
- **Prevents**: Both cascading rollbacks and dirty reads from uncommitted data

#### Lock Compatibility Matrix
```
        | S  | X  | U
--------|----|----|----
S       | ✓  | ✗  | ✓
X       | ✗  | ✗  | ✗
U       | ✓  | ✗  | ✗
```
✓ = Compatible, ✗ = Incompatible

#### Deadlock Handling

##### Prevention
- **Timeout**: Abort transaction after waiting too long
- **Ordered locking**: Always acquire locks in predefined order
- **No waiting**: Abort immediately if lock not available

##### Detection
- **Wait-for graph**: Track which transactions are waiting for which locks
- **Cycle detection**: If cycle exists, deadlock detected
- **Victim selection**: Choose transaction to abort (usually youngest or least work done)

### Multiversion Concurrency Control (MVCC)

#### Concept
Instead of locking data for readers, maintain multiple versions of each data item:
- Each version has associated timestamp or transaction ID
- Readers access appropriate version based on their transaction start time
- Writers create new versions rather than overwriting existing data

#### Implementation Details

##### Version Storage
- Each row contains pointer to current version
- Old versions stored in separate area or linked list
- Each version has: begin timestamp, end timestamp, transaction ID

##### Read Operation
```
READ(x) at time T:
1. Find version of x with begin_timestamp <= T < end_timestamp
2. Return value of that version
```

##### Write Operation
```
WRITE(x, value) by transaction T:
1. Create new version of x with:
   - begin_timestamp = T.start_time
   - end_timestamp = ∞
   - value = value
   - transaction_id = T.id
2. Set old version's end_timestamp = T.start_time
```

#### Advantages Over Locking
- **Readers don't block writers**
- **Writers don't block readers**
- **Better concurrency for read-heavy workloads**
- **No deadlocks from reader-writer conflicts**

#### Disadvantages
- **Storage overhead**: Multiple versions maintained
- **Cleanup needed**: Old versions must be garbage collected
- **Long-running transactions**: Can prevent version cleanup

#### MVCC in Popular Databases

##### PostgreSQL
- Uses transaction IDs (XIDs) for versioning
- Each row has xmin (creation) and xmax (deletion/expiration)
- Uses snapshot isolation for READ COMMITTED and REPEATABLE READ
- Serializable Snapshot Isolation (SSI) for SERIALIZABLE level

##### MySQL InnoDB
- Similar approach with row versions
- Uses undo logs to maintain old versions
- Repeatable read is default isolation level

##### Oracle
- Uses undo segments to maintain read-consistent views
- Each query sees database as of query start time (statement-level consistency)

## Snapshot Isolation

### Definition
Each transaction sees a consistent snapshot of the database as of the transaction start time.

### Guarantees
- Prevents dirty reads and non-repeatable reads
- Does NOT prevent phantom reads (unless extended)
- Allows write skew anomalies

### Write Skew Anomaly
**Scenario**:
```
Constraint: At least one doctor must be on call
Initial: DrA.on_call = true, DrB.on_call = false (constraint satisfied) ✓

T1 (DrA): READ DrA.on_call (true), READ DrB.on_call (false)
         IF (no one on call) THEN SET DrA.on_call = false
T2 (DrB): READ DrB.on_call (false), READ DrA.on_call (true)
         IF (no one on call) THEN SET DrB.on_call = false

Both T1 and T2 see: one doctor on call (constraint satisfied)
Both conclude: they can go off call
Both commit: DrA.on_call = false, DrB.on_call = false
Result: No doctor on call (constraint violated) ✗
```

### Serializable Snapshot Isolation (SSI)
- Extension of MVCC that detects and prevents write skew
- Tracks dangerous structures (patterns that could lead to anomalies)
- Aborts one transaction when dangerous structure detected

## Practical Implementation Examples

### Testing Isolation Levels in PostgreSQL

```sql
-- Setup
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    balance DECIMAL(10,2)
);

INSERT INTO accounts (name, balance) VALUES 
('Alice', 1000.00), 
('Bob', 500.00);

-- Terminal 1: Test READ COMMITTED
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice'; -- Reads 1000.00

-- Terminal 2: 
BEGIN TRANSACTION;
UPDATE accounts SET balance = 1500.00 WHERE name = 'Alice';
COMMIT;

-- Back to Terminal 1:
SELECT balance FROM accounts WHERE name = 'Alice'; -- Sees 1500.00 (non-repeatable read possible)

-- Terminal 1: 
COMMIT;

-- Terminal 1: Test REPEATABLE READ
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name = 'Alice'; -- Reads 1000.00

-- Terminal 2: 
BEGIN TRANSACTION;
UPDATE accounts SET balance = 2000.00 WHERE name = 'Alice';
COMMIT;

-- Back to Terminal 1:
SELECT balance FROM accounts WHERE name = 'Alice'; -- Still sees 1000.00 (repeatable read)

-- Terminal 1:
COMMIT;
```

### Testing Phantom Reads

```sql
-- Setup
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    amount DECIMAL(10,2),
    customer_id INT
);

INSERT INTO orders (amount, customer_id) VALUES 
(1500.00, 1), (2000.00, 2), (800.00, 3);

-- Terminal 1: REPEATABLE READ
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM orders WHERE amount > 1000; -- Returns 2

-- Terminal 2:
BEGIN TRANSACTION;
INSERT INTO orders (amount, customer_id) VALUES (3000.00, 4);
COMMIT;

-- Back to Terminal 1:
SELECT COUNT(*) FROM orders WHERE amount > 1000; -- Still returns 2 (no phantom in REPEATABLE READ)

-- Terminal 1:
COMMIT;

-- Terminal 1: SERIALIZABLE
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM orders WHERE amount > 1000; -- Returns 2

-- Terminal 2: 
BEGIN TRANSACTION;
INSERT INTO orders (amount, customer_id) VALUES (2500.00, 5);
COMMIT;

-- Back to Terminal 1:
SELECT COUNT(*) FROM orders WHERE amount > 1000; -- Would need to retry due to serialization failure

-- Terminal 1:
COMMIT;  // Might fail with serialization error
```

## Performance Considerations

### Locking Overhead
- **Lock acquisition/release**: CPU cost for lock management
- **Lock storage**: Memory to maintain lock table
- **Contention**: Waiting for locks reduces throughput
- **Deadlock handling**: Detection and resolution costs

### MVCC Overhead
- **Version storage**: Additional space for multiple versions
- **Version creation**: CPU cost for creating new versions
- **Garbage collection**: Background process to remove old versions
- **Long transactions**: Can prevent version cleanup, increasing storage

### Optimization Techniques

#### Index Locking
- Lock index pages instead of individual rows when appropriate
- Reduces lock granularity overhead

#### Lock Escalation
- Convert many row locks to fewer page/table locks when threshold exceeded
- Reduces lock table size but increases contention

#### Adaptive Locking
- Dynamically choose locking strategy based on workload characteristics
- Switch between locking and MVCC approaches

#### Partitioning
- Split data into partitions to reduce contention
- Different transactions can work on different partitions concurrently

## Summary

Isolation ensures that concurrent transactions execute as if they were running serially, preventing interference:

### Key Takeaways
1. **Isolation levels trade consistency for concurrency**
   - Lower levels: More concurrency, more anomalies
   - Higher levels: Less concurrency, fewer anomalies

2. **MVCC vs Locking**
   - MVCC: Better for read-heavy workloads, no reader-writer blocking
   - Locking: Better predictability, handles write-write conflicts naturally

3. **Choosing the right level**
   - READ COMMITTED: Good default for most applications
   - REPEATABLE READ: When you need consistent reads within transaction
   - SERIALIZABLE: When absolute consistency is required (financial systems)
   - READ UNCOMMITTED: Only for analytics/stats where approximate results OK

4. **Implementation matters**
   - Same isolation level can have different characteristics across databases
   - Always test with your specific workload and database