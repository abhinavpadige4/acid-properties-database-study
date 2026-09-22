# Day 3: Durability, ACID vs BASE, and Summary

## Durability

### Definition
Durability ensures that once a transaction is committed, its effects persist even in the event of system failure (power loss, crash, disk failure, etc.).

### The Guarantee
When a transaction commits and returns success to the user, the user can be absolutely certain that:
- The transaction's effects are permanently recorded
- The data will survive any subsequent system failure
- No committed transaction will ever be lost

### Implementation Mechanisms

#### Write-Ahead Logging (WAL)
**Core Principle**: Never modify database files on disk until the corresponding log record has been written to stable storage.

##### How WAL Works
1. **Begin Transaction**: Log transaction start record
2. **Modify Data**: For each modification:
   - Write UPDATE log record (containing old and new values) to WAL buffer
   - Apply change to in-memory buffer (not yet to disk)
3. **Prepare to Commit**: 
   - Flush WAL buffer to disk (ensuring log records are on stable storage)
   - Log COMMIT record
   - Flush COMMIT record to disk
4. **Return Success**: Only after COMMIT record is safely on disk
5. **Background Process**: Periodically write dirty pages from buffer pool to disk

##### Recovery Process Using WAL
After system crash:
1. **Analysis Phase**: 
   - Scan WAL forward to identify:
     - All committed transactions (need redo)
     - All uncommitted transactions (need undo)
   - Identify last checkpoint
2. **Redo Phase**:
   - Reapply all changes from committed transactions (from last checkpoint forward)
   - Restores database to state at time of crash
3. **Undo Phase**:
   - Rollback all uncommitted transactions (working backward from end of log)
   - Restores database to consistent state

##### WAL Record Structure
```
<LSN, PrevLSN, TransactionID, Type, Data...>
```
- LSN: Log Sequence Number (monotonically increasing)
- PrevLSN: Pointer to previous log record from same transaction
- TransactionID: ID of transaction that generated this record
- Type: BEGIN, COMMIT, UPDATE, INSERT, DELETE, etc.
- Data: Actual change information (old/new values, etc.)

#### Checkpointing
**Purpose**: Reduce recovery time by establishing known good points in the log.

##### How Checkpointing Works
1. **Begin Checkpoint**:
   - Write CHECKPOINT BEGIN record to WAL
   - Record all dirty pages in buffer pool
   - Record all active transactions
2. **End Checkpoint**:
   - Flush all dirty pages to disk
   - Write CHECKPOINT END record to WAL (includes pointers to begin record)
   - Update control file with checkpoint location

##### Recovery Optimization
Instead of replaying WAL from beginning:
1. Start from last checkpoint
2. Redo only changes made after checkpoint
3. Undo only transactions active at checkpoint time

#### Dual Storage Approach
Some systems maintain:
- **Primary storage**: Main database files
- **Secondary storage**: Log/archive or mirror
- Updates written to both before commit acknowledgment

#### Group Commit
**Optimization**: Batch multiple commit operations together
- Multiple transactions commit simultaneously
- Single WAL flush serves multiple commits
- Significantly improves throughput for commit-heavy workloads

#### SSD Optimization
Modern WAL implementations optimize for SSD characteristics:
- Sequential writes preferred over random
- Larger batch sizes to amortize erase costs
- Wear leveling considerations

### Failure Scenarios Durability Protects Against

#### 1. Power Loss
- **Scenario**: Transaction commits, power fails before data written to disk
- **WAL Protection**: Commit record already on disk, recovery replays transaction

#### 2. System Crash
- **Scenario**: Kernel panic, hardware failure
- **WAL Protection**: Log records survive, recovery restores consistent state

#### 3. Disk Failure (Partial)
- **Scenario**: Some sectors become unreadable
- **WAL Protection**: Log may be on different disk, or replicated

#### 4. Network Partition (in distributed systems)
- **Scenario**: Node isolated from cluster
- **WAL Protection**: Local log ensures durability until reconnection

## ACID vs BASE

### ACID Properties (Traditional Databases)

#### Atomicity
- **Guarantee**: All-or-nothing execution
- **Mechanism**: Undo logs, rollback capability
- **Example**: Bank transfer - either both accounts updated or neither

#### Consistency
- **Guarantee**: Valid state transitions (constraints preserved)
- **Mechanism**: Constraint checking, triggers, validation
- **Example**: Account balance never negative despite withdrawal

#### Isolation
- **Guarantee**: Serializable execution (transactions don't interfere)
- **Mechanism**: Locking, MVCC, isolation levels
- **Example**: Concurrent transfers don't interfere with each other

#### Durability
- **Guarantee**: Permanent storage of committed transactions
- **Mechanism**: Write-Ahead Logging, checkpointing
- **Example**: Committed transfer survives power failure

**Characteristics**: Strong consistency, predictable behavior, lower availability during partitions

### BASE Properties (Modern Distributed Systems)

#### Basically Available
- **Guarantee**: System guarantees availability
- **Mechanism**: Replication, partitioning, graceful degradation
- **Example**: System responds even if some nodes are down

#### Soft State
- **Guarantee**: State may change over time without input
- **Mechanism**: Background processes, eventual consistency protocols
- **Example**: Cached values expire and get refreshed automatically

#### Eventual Consistency
- **Guarantee**: System will become consistent over time
- **Mechanism**: Conflict resolution, anti-entropy processes, read repair
- **Example**: Social media post eventually appears on all friends' feeds

**Characteristics**: High availability, partition tolerance, eventual consistency

### Detailed Comparison

| Aspect | ACID | BASE |
|--------|------|------|
| **Consistency Model** | Strong consistency | Eventual consistency |
| **Availability** | Lower (may block during partitions) | Higher (continues operating) |
| **Partition Tolerance** | Lower priority | Higher priority |
| **Transaction Support** | Full ACID transactions | Limited or no transactions |
| **Data Model** | Often relational | Often NoSQL (key-value, document, etc.) |
| **Use Cases** | Banking, healthcare, inventory | Social media, caching, analytics |
| **Performance** | Predictable, lower throughput | Higher throughput, variable latency |
| **Complexity** | Well-understood, mature | Evolving, application-level consistency |

### When to Use Which

#### Use ACID When:
- **Data correctness is paramount**: Financial transactions, medical records
- **Business rules are complex**: Inventory systems with multiple constraints
- **Audit trails are required**: Legal compliance, financial reporting
- **Low tolerance for inconsistency**: Airline reservations, stock trading

#### Use BASE When:
- **Availability is critical**: Social media platforms, search engines
- **Data can tolerate temporary inconsistency**: Likes, comments, views counters
- **Read-heavy workloads**: Content delivery, recommendation systems
- **Geographic distribution**: Global services with high latency tolerance
- **Massive scale**: Systems handling billions of operations per day

### Hybrid Approaches

#### Tunable Consistency
- **Cassandra**: Choose consistency level per query (ONE, QUORUM, ALL)
- **DynamoDB**: Eventually consistent reads vs strongly consistent reads
- **MongoDB**: Read concern levels (local, available, majority, linearizable)

#### Async Replication with Sync Commit
- **Primary-Secondary**: Commit waits for primary + one secondary
- **Background**: Async replication to additional secondaries
- **Balance**: Good durability with reasonable performance

#### Conflict-Free Replicated Data Types (CRDTs)
- **Mathematical properties**: Ensure convergence regardless of delivery order
- **Use cases**: Collaborative editing, counters, sets
- **Limitation**: Only works for specific data types and operations

## NoSQL Systems with ACID Support

### MongoDB
- **Multi-document ACID transactions**: Introduced in v4.0 (2018)
- **Isolation**: Serializable
- **Durability**: Write-ahead logging with journaling
- **Limitations**: 
  - Transaction size limit (1000 operations)
  - Performance overhead (~2x slower than single document)
  - Sharded cluster transactions more complex

### Amazon DynamoDB
- **Transactions**: ACID properties across multiple items/tables
- **Isolation**: Serializable
- **Durability**: 
  - Synchronous replication across multiple AZs
  - Commit waits for write to durable storage on primary + backup
- **Limits**: 
  - Maximum 4 seconds transaction duration
  - Maximum 100 items or 4MB transaction size

### Google Cloud Spanner
- **Strong Consistency**: External consistency (stronger than serializable)
- **ACID Transactions**: Fully supported across globally distributed data
- **Implementation**:
  - TrueTime API for global clock synchronization
  - Paxos replication across zones
  - Lock-based concurrency control with wound-wait deadlock prevention
- **Performance**: 
  - Read-only transactions: Fast (use stale reads if allowed)
  - Read-write: Higher latency due to coordination

### FoundationDB
- **ACID Transactions**: Core design principle
- **Isolation**: Serializable
- **Architecture**: 
  - Separation of concerns: storage layer vs transaction layer
  - Optimistic concurrency control
  - Deterministic simulation testing for correctness

### CockroachDB
- **Inspired by**: Google Spanner
- **Consistency**: Strong consistency (serializable)
- **Implementation**:
  - Raft replication for each range
  - Timestamp-based ordering
  - Automatic rebalancing and recovery
- **SQL Interface**: PostgreSQL wire protocol compatible

## Comprehensive ACID Summary

### Atomicity - The All-or-Nothing Principle
**Core Idea**: Transaction indivisibility
**Failure Modes Protected**: 
- System crashes during execution
- Application errors mid-transaction
- Resource exhaustion (disk full, memory exhausted)
**Key Mechanisms**:
- Undo/redo logging
- Atomic write operations (sector-level atomicity)
- Transaction state tracking
**Verification**: After recovery, no partial transaction effects visible

### Consistency - Validity Preservation
**Core Idea**: Database rules invariance
**Types of Constraints**:
- Structural: Keys, nulls, data types
- Semantic: Business rules, application logic
- Referential: Foreign key relationships
**Key Mechanisms**:
- Declarative constraints (SQL DDL)
- Triggers and stored procedures
- Application-level validation
- Deferred constraint checking
**Verification**: Every transaction maps valid state → valid state

### Isolation - Concurrency Control
**Core Idea**: Apparent serial execution
**Anomalies Prevented**:
- Dirty reads (read uncommitted)
- Non-repeatable reads (change during read)
- Phantom reads (new rows in range query)
**Key Mechanisms**:
- Locking protocols (2PL, strict 2PL)
- Multiversion Concurrency Control (MVCC)
- Snapshot isolation variants
- Serializable snapshot isolation (SSI)
**Verification**: Concurrent execution equivalent to some serial order

### Durability - Permanence Guarantee
**Core Idea**: Commit = permanent
**Failure Modes Protected**:
- Power loss
- System crashes
- Disk/media failure
- Network partitions (in distributed systems)
**Key Mechanisms**:
- Write-Ahead Logging (WAL)
- Checkpointing and log archiving
- Mirroring and replication
- Solid-state storage optimizations
**Verification**: Committed transaction survives any single-point failure

### The ACID Guarantee in Practice
When a database system claims ACID compliance, it promises:
1. **Atomicity**: Your money transfer won't leave money in limbo
2. **Consistency**: Your account balance won't mysteriously go negative
3. **Isolation**: Your concurrent transactions won't interfere
4. **Durability**: Your confirmed transaction won't vanish after reboot

### Trade-offs and Realities

#### Performance Costs
- **ACID overhead**: Typically 2-10x slower than non-ACID alternatives
- **Locking contention**: Reduces throughput under high concurrency
- **Logging I/O**: Disk writes for durability can bottleneck
- **Coordination**: Distributed ACID adds network latency

#### Implementation Variations
- **"ACID-ish" systems**: Relax one property for performance
- **Single-node ACID**: Easier to achieve than distributed ACID
- **Hardware-assisted**: NVRAM, persistent memory reduce logging overhead
- **Application-level**: Some guarantees implemented in app rather than DB

#### The CAP Theorem Connection
- **ACID systems**: Generally favor Consistency and Partition tolerance (CP)
- **BASE systems**: Generally favor Availability and Partition tolerance (AP)
- **Network partitions**: Force choice between consistency and availability

## Interview Preparation: Key Talking Points

### Explaining ACID Simply
> "ACID is like a safety contract for database transactions. Atomicity means 'all or nothing' - like a light switch that's either fully on or fully off. Consistency means the database always follows its rules - like ensuring your bank account never goes negative. Isolation means transactions don't step on each other's toes - like having separate checkout lines at a store. Durability means once you've paid, the store can't claim you didn't - like getting a receipt that's proof of purchase."

### Concrete Examples for Each Property

#### Atomicity Example
"Imagine transferring $1000 from savings to checking. Atomicity ensures that either both accounts are updated (savings -$1000, checking +$1000) or neither is changed. If the system crashes after debiting savings but before crediting checking, the transaction is rolled back so savings remains unchanged."

#### Consistency Example
"Consider a database rule that says 'total inventory = sum of warehouse stock'. Consistency ensures that any transaction updating warehouse quantities automatically maintains this relationship. If you add 100 units to Warehouse A, the system either also adjusts the total inventory field or rejects the transaction entirely."

#### Isolation Example
"Two cashiers trying to refund the same $50 item simultaneously. Without isolation, both might read the current balance as $100, each refund $50, and write back $50 - resulting in $50 being refunded twice. With proper isolation, one transaction waits for the other to complete, ensuring correct final balance."

#### Durability Example
"After purchasing an airplane ticket online and receiving confirmation, durability ensures that even if the airline's systems crash immediately after, your ticket reservation is still there when systems come back online. The commitment was written to durable storage before confirmation was sent."

### Common Follow-up Questions

#### Q: "Can you have durability without atomicity?"
A: "Technically yes, but it's meaningless. Durability ensures committed transactions persist, but without atomicity, you might have partially applied transactions that are 'durably wrong'. A system could durably store inconsistent or incomplete data."

#### Q: "Isolation levels seem confusing - when would you use each?"
A: "READ COMMITTED is good default for most web apps. REPEATABLE READ when you need consistent reads within a transaction (like generating reports). SERIALIZABLE for financial systems where you absolutely cannot tolerate anomalies. READ UNCOMMITTED only for approximate statistics where speed matters more than accuracy."

#### Q: "How do NoSQL databases handle ACID?"
A: "It varies. MongoDB added multi-document ACID transactions in v4.0. DynamoDB offers ACID transactions across items. Cassandra focuses on tunable consistency rather than full ACID. Google Spanner provides strong consistency globally. The trend is increasing ACID support in NoSQL as use cases demand it."

#### Q: "What's the biggest challenge in implementing ACID?"
A: "Distributed ACID transactions are notoriously difficult due to the need for coordination across nodes while maintaining performance. The two-phase commit protocol can block, and network partitions create challenging trade-offs between consistency and availability."

#### Q: "How does MVCC improve upon traditional locking?"
A: "MVCC allows readers to access consistent snapshots without blocking writers, and writers to create new versions without blocking readers. This eliminates the classic reader-writer conflict that limits concurrency in pure locking systems, while still preventing the anomalies that locking prevents."

## One-Page Summary: Key Takeaways

### The Four Pillars

| Property | Guarantee | Mechanism | Real-World Analogy |
|----------|-----------|-----------|-------------------|
| **Atomicity** | All-or-nothing | Undo logs | Light switch: fully ON or fully OFF |
| **Consistency** | Valid states | Constraint checking | Bank account: never negative balance |
| **Isolation** | Serial execution | Locking/MVCC | Checkout lines: separate, non-interfering |
| **Durability** | Permanent storage | WAL/checkpointing | Receipt: proof that purchase happened |

### Violation Symptoms

| Property | Violation Looks Like | Root Cause |
|----------|---------------------|------------|
| **Atomicity** | Partial updates, "half-done" transactions | System failure mid-transaction |
| **Consistency** | Constraint violations, invalid data | Business rules not enforced |
| **Isolation** | Inconsistent reads, lost updates | Concurrent transaction interference |
| **Durability** | Lost confirmed transactions | Data not persisted to stable storage |

### Decision Framework

**Choose ACID when**:
- Financial accuracy is critical
- Business rules are complex and interdependent
- Legal/compliance requirements exist
- Single source of truth is required

**Consider BASE when**:
- User experience depends on availability
- Data can tolerate brief inconsistency
- System must handle massive scale
- Geographic distribution creates latency challenges

### Best Practices

1. **Understand your isolation level**: Don't assume DEFAULT is appropriate
2. **Design for failure**: Assume crashes will happen, test recovery
3. **Monitor transaction health**: Watch for long-running transactions, deadlocks
4. **Test edge cases**: Power failure simulation, network partition testing
5. **Consider hardware**: Modern NVMe and persistent memory change trade-offs
6. **Document assumptions**: Clearly state which ACID properties your application relies on

## References and Further Reading

### Foundational Papers
- Gray, J. & Reuter, A. (1993). *Transaction Processing: Concepts and Techniques*
- Bernstein, P.A., Hadzilacos, V., & Goodman, N. (1987). *Concurrency Control and Recovery in Database Systems*
- Lamport, L. (1978). "Time, Clocks, and the Ordering of Events in a Distributed System"

### Modern Systems
- Google Spanner: https://research.google/pubs/pub39966/
- CockroachDB: https://www.cockroachlabs.com/blog/distributed-transactions/
- FoundationDB: https://foundationdb.com/

### Practical Guides
- PostgreSQL Documentation: WAL and Reliability
- MySQL InnoDB: Transaction Model and Locking
- MongoDB Documentation: Transactions
- AWS DynamoDB: Transactions Documentation

### Video Resources
- ACID Properties Explained: https://www.youtube.com/watch?v=0Z4w0fBQJcE
- Database Transaction Internals: https://www.youtube.com/watch?v=JrVlxPEnerM
- Distributed Transactions: https://www.youtube.com/watch?v=tlhJ_eeYWGI