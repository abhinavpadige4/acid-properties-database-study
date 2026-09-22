# ACID Properties in Databases: Comprehensive Study Guide

This repository contains comprehensive study materials on ACID (Atomicity, Consistency, Isolation, Durability) properties in database systems, designed for interview preparation and deep understanding.

## Table of Contents
- [Overview](#overview)
- [Day 1: Atomicity and Consistency](#day-1-atomicity-and-consistency)
- [Day 2: Isolation and Concurrency Control](#day-2-isolation-and-concurrency-control)
- [Day 3: Durability, ACID vs BASE, and Summary](#day-3-durability-acid-vs-base-and-summary)
- [Interview Preparation](#interview-preparation)
- [Hands-on Experiments](#hands-on-experiments)
- [References](#references)

## Overview

ACID is an acronym for Atomicity, Consistency, Isolation, and Durability - a set of properties that guarantee reliable processing of database transactions. These properties ensure data validity despite errors, power failures, and other mishaps.

### What is a Transaction?
A transaction is a logical unit of work that contains one or more database operations. It must be treated as an indivisible unit - either all operations succeed (commit) or none are applied (rollback).

## Day 1: Atomicity and Consistency

### Atomicity
**Definition**: Atomicity ensures that a transaction is treated as a single, indivisible unit of work. Either all operations within the transaction are completed successfully, or none are applied.

**Key Concepts**:
- **All-or-nothing principle**: No partial execution
- **Rollback mechanism**: Ability to undo changes if transaction fails
- **Undo logs**: Records of old values to enable rollback
- **Commit point**: Point of no return where transaction becomes permanent

**Example**: 
Consider a bank transfer of $100 from Account A to Account B:
1. Debit $100 from Account A
2. Credit $100 to Account B

If the system crashes after step 1 but before step 2, atomicity ensures that the debit is rolled back, leaving both accounts unchanged.

**Implementation Mechanisms**:
- **Undo logs**: Before modifying data, write old value to log
- **Shadow paging**: Maintain two copies of database pages
- **Checkpointing**: Periodic saving of consistent state

### Consistency
**Definition**: Consistency ensures that a transaction brings the database from one valid state to another, preserving all database rules, constraints, and invariants.

**Key Concepts**:
- **Valid state**: Database state that satisfies all constraints
- **Constraints**: Primary keys, foreign keys, unique constraints, check constraints
- **Triggers**: Automatic actions that maintain consistency
- **Application logic**: Business rules enforced at application level

**Example**:
Consider a database with constraint: "Account balance cannot be negative"
- Valid state: Account A: $500, Account B: $300
- Invalid state: Account A: -$100, Account B: $900 (violates constraint)

If a transaction tries to withdraw $600 from Account A (making it -$100), consistency ensures the transaction is aborted.

**Implementation Mechanisms**:
- **Constraint checking**: Validate constraints before/after transaction
- **Triggers**: Automatically enforce business rules
- **Stored procedures**: Encapsulate logic that maintains consistency
- **Declarative constraints**: Built-in database constraint mechanisms

## Day 2: Isolation and Concurrency Control

### Isolation
**Definition**: Isolation controls how and when changes made by one transaction become visible to other concurrent transactions, preventing interference.

**The Problem**: Without proper isolation, concurrent transactions can lead to inconsistent states.

### Isolation Levels
ANSI SQL standard defines four isolation levels:

#### 1. READ UNCOMMITTED
- **Allows**: Dirty reads, non-repeatable reads, phantom reads
- **Prevents**: Nothing (lowest isolation)
- **Use case**: Rarely used, only when absolute consistency isn't required

#### 2. READ COMMITTED
- **Allows**: Non-repeatable reads, phantom reads
- **Prevents**: Dirty reads
- **Use case**: Default in many databases (Oracle, SQL Server)
- **Mechanism**: Read only committed data

#### 3. REPEATABLE READ
- **Allows**: Phantom reads
- **Prevents**: Dirty reads, non-repeatable reads
- **Use case**: Default in MySQL InnoDB
- **Mechanism**: Locks rows read, prevents modification by others

#### 4. SERIALIZABLE
- **Allows**: Nothing (highest isolation)
- **Prevents**: Dirty reads, non-repeatable reads, phantom reads
- **Use case**: When absolute consistency is required
- **Mechanism**: Range locks, predicate locking

### Concurrency Anomalies

#### Dirty Read
**Scenario**: Transaction T1 reads uncommitted data from Transaction T2, then T2 rolls back.
**Example**:
- T1: Reads Account A balance ($1000) 
- T2: Updates Account A to $2000 (uncommitted)
- T1: Reads Account A again ($2000)
- T2: Rolls back (Account A actually $1000)
- **Problem**: T1 read inconsistent data

#### Non-Repeatable Read
**Scenario**: Transaction T1 reads same row twice, gets different values because T2 modified it.
**Example**:
- T1: Reads Account A balance ($1000)
- T2: Updates Account A to $1500 and commits
- T1: Reads Account A again ($1500)
- **Problem**: T1 got different values for same query

#### Phantom Read
**Scenario**: Transaction T1 re-executes a query, gets different set of rows because T2 inserted/deleted rows.
**Example**:
- T1: SELECT * FROM Accounts WHERE balance > $1000 (returns 5 rows)
- T2: INSERT new Account with balance $2000 and commits
- T1: SELECT * FROM Accounts WHERE balance > $1000 (returns 6 rows)
- **Problem**: T1 got different number of rows

### Implementation Mechanisms

#### Locking-Based Concurrency Control
- **Shared locks (S)**: Allow multiple readers, block writers
- **Exclusive locks (X)**: Allow one writer, block all readers/writers
- **Two-Phase Locking (2PL)**: 
  - Growing phase: Acquire locks
  - Shrinking phase: Release locks
- **Deadlock prevention**: Timeout, deadlock detection, wound-wait

#### Multiversion Concurrency Control (MVCC)
- **Concept**: Each transaction sees a snapshot of database at start time
- **Implementation**: 
  - Keep multiple versions of each row
  - Each version has timestamp or transaction ID
  - Readers don't block writers and vice versa
- **Used by**: PostgreSQL, MySQL InnoDB, Oracle

## Day 3: Durability, ACID vs BASE, and Summary

### Durability
**Definition**: Durability ensures that once a transaction is committed, its effects persist even in the event of system failure (power loss, crash, etc.).

**Key Concepts**:
- **Permanent storage**: Changes written to non-volatile storage
- **Recovery**: Ability to restore committed transactions after failure
- **No data loss**: Committed transactions survive crashes

**Implementation Mechanisms**:
- **Write-Ahead Logging (WAL)**:
  - Log changes before applying to database
  - Log must be written to disk before data pages
  - On recovery: replay log to redo committed transactions
- **Checkpointing**:
  - Periodically flush all dirty pages to disk
  - Record checkpoint position in log
  - On recovery: only need to replay log from last checkpoint
- **Redo logs**: Record new values to redo operations after crash
- **Mirroring/Replication**: Maintain copies on separate storage

### ACID vs BASE

#### ACID Properties
- **Atomicity**: All-or-nothing execution
- **Consistency**: Valid state transitions
- **Isolation**: Concurrent transaction isolation
- **Durability**: Permanent storage of committed transactions
- **Use case**: Financial systems, banking, airline reservations
- **Characteristics**: Strong consistency, predictable behavior

#### BASE Properties
- **Basically Available**: System guarantees availability
- **Soft state**: State may change over time without input
- **Eventual consistency**: System will become consistent over time
- **Use case**: Social media, caching systems, NoSQL databases
- **Characteristics**: High availability, partition tolerance, eventual consistency

**When to Use Which**:
- **Use ACID when**: Data correctness is paramount (banking, healthcare, inventory)
- **Use BASE when**: Availability and performance are more important than immediate consistency (social media, recommendation systems)

### NoSQL and ACID Support

#### MongoDB
- **Multi-document transactions**: Available since v4.0
- **ACID guarantees**: Atomicity, Consistency, Isolation, Durability
- **Limitations**: Transaction size limits, performance overhead

#### Amazon DynamoDB
- **Transactions**: ACID properties across multiple items
- **Isolation**: Serializable isolation
- **Durability**: Replicated across multiple availability zones

#### Google Cloud Spanner
- **Strong consistency**: External consistency (stronger than serializable)
- **ACID transactions**: Fully supported
- **Scalability**: Horizontal scaling with strong consistency

#### Cassandra
- **Tunable consistency**: Trade-off between consistency and availability
- **Lightweight transactions**: Provide linearizability (using Paxos)

## Interview Preparation

### Common Interview Questions

#### Basic Level
1. **What does ACID stand for?**
   - Atomicity, Consistency, Isolation, Durability

2. **Explain Atomicity with an example.**
   - Bank transfer example: Either both debit and credit happen, or neither.

3. **What is the difference between Consistency in ACID and Consistency in CAP theorem?**
   - ACID Consistency: Database rules validity
   - CAP Consistency: All nodes see same data at same time

#### Intermediate Level
4. **What isolation level prevents dirty reads but allows non-repeatable reads?**
   - READ COMMITTED

5. **How does Write-Ahead Logging ensure durability?**
   - Changes are logged to stable storage before being applied to database; on recovery, log is replayed to redo committed transactions.

6. **Explain the difference between pessimistic and optimistic locking.**
   - Pessimistic: Lock data before reading (assumes conflict likely)
   - Optimistic: Check for conflicts at commit time (assumes conflict rare)

#### Advanced Level
7. **How does MVCC improve concurrency compared to locking?**
   - Readers don't block writers and writers don't block readers by maintaining multiple versions of data.

8. **What is a phantom read and how is it prevented at SERIALIZABLE level?**
   - Phantom read: New rows appear in re-executed query. Prevented by range/predicate locking at SERIALIZABLE.

9. **Compare ACID and BASE approaches.**
   - ACID: Strong consistency, lower availability
   - BASE: Eventual consistency, higher availability

### Concrete Examples of Violations

#### Atomicity Violation
**Scenario**: Money transfer where debit succeeds but credit fails due to network error.
**Result**: Money disappears from source account but never reaches destination.

#### Consistency Violation
**Scenario**: Transfer that results in negative account balance despite constraint forbidding it.
**Result**: Database contains invalid state violating business rules.

#### Isolation Violation (Dirty Read)
**Scenario**: 
- T1: Reads uncommitted balance of $1000
- T2: Credits $500 (making it $1500) then rolls back due to error
- T1: Makes decision based on $1000 balance (actually should be $500)
**Result**: Incorrect business decision based on temporary data.

#### Durability Violation
**Scenario**: Transaction commits, system crashes before data written to disk.
**Result**: Committed transaction lost despite commit acknowledgment.

## Hands-on Experiments

### Setting Up PostgreSQL for Experiments

```bash
# Pull PostgreSQL Docker image
docker pull postgres:15

# Run PostgreSQL container
docker run --name aciddb -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:15

# Connect to database
docker exec -it aciddb psql -U postgres
```

### Experiment 1: Testing Atomicity

```sql
-- Create test table
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    balance DECIMAL(10,2) CHECK (balance >= 0)
);

-- Insert test data
INSERT INTO accounts (name, balance) VALUES ('Alice', 1000.00), ('Bob', 500.00);

-- Begin transaction
BEGIN;

-- Transfer $200 from Alice to Bob
UPDATE accounts SET balance = balance - 200.00 WHERE name = 'Alice';
-- Simulate error before second update
-- SELECT pg_sleep(10); -- Uncomment to test rollback
UPDATE accounts SET balance = balance + 200.00 WHERE name = 'Bob';

-- If error occurs, rollback
-- ROLLBACK;
-- Otherwise commit
COMMIT;
```

### Experiment 2: Testing Isolation Levels

```sql
-- In Terminal 1 (Transaction 1)
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice';

-- In Terminal 2 (Transaction 2)
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
COMMIT;

-- Back to Terminal 1
SELECT balance FROM accounts WHERE name = 'Alice'; -- Will see committed change
```

### Experiment 3: Testing Durability with WAL

```sql
-- Check WAL settings
SHOW wal_level;
SHOW checkpoint_timeout;
SHOW max_wal_size;

-- Force checkpoint
CHECKPOINT;

-- Insert data and immediately shutdown (simulate crash)
INSERT INTO accounts (name, balance) VALUES ('Charlie', 300.00);
-- In another terminal: docker stop aciddb
-- Then restart: docker start aciddb
-- Check if Charlie's account persists
```

## One-Page ACID Summary

### Atomicity
- **Guarantee**: All-or-nothing execution
- **Mechanism**: Undo logs, rollback capability
- **Violation**: Partial transaction execution
- **Example**: Bank transfer where only debit occurs

### Consistency
- **Guarantee**: Valid state transitions (constraints preserved)
- **Mechanism**: Constraint checking, triggers, validation
- **Violation**: Database rules broken after transaction
- **Example**: Account balance going negative despite CHECK constraint

### Isolation
- **Guarantee**: Concurrent transactions don't interfere
- **Mechanism**: Locking, MVCC, isolation levels
- **Violation**: Dirty reads, non-repeatable reads, phantom reads
- **Levels**: READ UNCOMMITTED → READ COMMITTED → REPEATABLE READ → SERIALIZABLE

### Durability
- **Guarantee**: Committed transactions survive crashes
- **Mechanism**: Write-Ahead Logging, checkpointing, redo logs
- **Violation**: Lost committed transaction after crash
- **Example**: Transaction acknowledged but lost due to power failure before disk write

### Quick Reference Table

| Property | Guarantee | Mechanism | Violation Example |
|----------|-----------|-----------|-------------------|
| **Atomicity** | All-or-nothing | Undo logs | Partial bank transfer |
| **Consistency** | Valid states | Constraint checking | Negative account balance |
| **Isolation** | Serializable execution | Locking/MVCC | Dirty read anomaly |
| **Durability** | Permanent storage | WAL/checkpointing | Lost committed transaction |

## References

### Textbooks
- "Database System Concepts" by Abraham Silberschatz, Henry F. Korth, S. Sudarshan
- "Transaction Processing: Concepts and Techniques" by Jim Gray and Andreas Reuter

### Online Resources
- PostgreSQL Documentation: https://www.postgresql.org/docs/current/transaction-iso.html
- MySQL InnoDB Isolation Levels: https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html
- Wikipedia ACID: https://en.wikipedia.org/wiki/ACID
- ACID vs BASE Article: https://queue.acm.org/detail.cfm?id=1394128

### Video Lectures
- ACID Properties Explained: https://www.youtube.com/watch?v=0Z4w0fBQJcE
- Database Transactions and Concurrency Control: https://www.youtube.com/watch?v=JrVlxPEnerM

## Files in This Repository

- `README.md` - This comprehensive guide
- `notes/day1-atomicity-consistency.md` - Detailed notes on Day 1 topics
- `notes/day2-isolation.md` - Detailed notes on Day 2 topics
- `notes/day3-durability-summary.md` - Detailed notes on Day 3 topics
- `experiments/postgresql-experiments.sql` - SQL scripts for hands-on experiments
- `summary/acid-one-page-summary.pdf` - One-page printable summary (placeholder)
- `interview/interview-questions.md` - Interview preparation questions and answers

---

*This study guide is designed to provide complete understanding of ACID properties for database interviews and practical implementation. Practice the hands-on experiments and review the interview questions thoroughly.*