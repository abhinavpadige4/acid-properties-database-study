# ACID Properties Interview Preparation

## Basic Level Questions

### Q1: What does ACID stand for?
**A**: ACID stands for Atomicity, Consistency, Isolation, and Durability. These are the four key properties that guarantee reliable processing of database transactions.

### Q2: Explain Atomicity with a real-world example.
**A**: Atomicity ensures that a transaction is treated as a single, indivisible unit of work. Either all operations within the transaction are completed successfully, or none are applied.

**Example**: Consider a bank transfer of $100 from Account A to Account B:
1. Debit $100 from Account A
2. Credit $100 to Account B

If the system crashes after step 1 but before step 2, atomicity ensures that the debit is rolled back, leaving both accounts unchanged (A still has original amount, B unchanged).

### Q3: What is Consistency in the context of ACID?
**A**: Consistency ensures that a transaction brings the database from one valid state to another, preserving all database rules, constraints, and invariants. The database must satisfy all defined constraints before and after the transaction.

**Example**: If a database has a constraint that "account balance cannot be negative," consistency ensures that no transaction can leave an account with a negative balance, even if intermediate steps during the transaction would temporarily violate this rule.

### Q4: How does Isolation prevent concurrency problems?
**A**: Isolation controls how and when changes made by one transaction become visible to other concurrent transactions, preventing interference. It ensures that concurrent transactions execute as if they were running serially, one after another.

**Example**: Without isolation, two transactions trying to withdraw money from the same account could both read the same balance, each withdraw $50, and write back the new balance, resulting in $100 being withdrawn but only $50 actually deducted from the account.

### Q5: What does Durability guarantee?
**A**: Durability ensures that once a transaction is committed, its effects persist even in the event of system failure (power loss, crash, disk failure, etc.). The user can be certain that committed data will survive any subsequent system failure.

**Example**: After purchasing an airplane ticket online and receiving confirmation, durability ensures that even if the airline's systems crash immediately after, your ticket reservation is still there when systems come back online.

## Intermediate Level Questions

### Q6: What isolation level prevents dirty reads but allows non-repeatable reads?
**A**: READ COMMITTED isolation level prevents dirty reads (reading uncommitted data) but allows non-repeatable reads (re-reading data and finding it changed by another committed transaction) and phantom reads.

### Q7: Explain the difference between pessimistic and optimistic locking.
**A**: 
- **Pessimistic locking**: Assumes conflicts are likely, so it locks data before reading to prevent others from modifying it. Used when write conflicts are frequent.
- **Optimistic locking**: Assumes conflicts are rare, so it allows transactions to proceed without locking, then checks for conflicts at commit time. If a conflict is detected, the transaction is rolled back and retried. Used when read operations vastly outnumber writes.

### Q8: How does Write-Ahead Logging (WAL) ensure durability?
**A**: WAL ensures durability by never modifying database files on disk until the corresponding log record has been written to stable storage. The sequence is:
1. Log the change to WAL buffer
2. Flush WAL buffer to disk (making it durable)
3. Apply change to in-memory buffer
4. Only after commit record is flushed to disk, return success to user

On recovery, the system can replay the WAL to redo committed transactions that may not have been written to disk yet.

### Q9: What is a phantom read and how is it prevented?
**A**: A phantom read occurs when a transaction re-executes a query returning a set of rows that satisfy a search condition and finds that the set of rows has changed due to another committed transaction inserting or deleting rows.

**Example**: 
- T1: SELECT * FROM orders WHERE amount > $1000 (returns 5 rows)
- T2: INSERT INTO orders VALUES (..., $1500); COMMIT;
- T1: SELECT * FROM orders WHERE amount > $1000 (returns 6 rows)

Phantom reads are prevented at the SERIALIZABLE isolation level through range locking or predicate locking, which locks not just the accessed rows but the range that could produce phantom results.

### Q10: What is the difference between Consistency in ACID and Consistency in the CAP theorem?
**A**: 
- **ACID Consistency**: Refers to database validity - ensuring that any transaction brings the database from one valid state to another, preserving all defined rules, constraints, and invariants.
- **CAP Consistency**: Refers to linearizability - ensuring that all nodes in a distributed system see the same data at the same time (strong consistency across nodes).

They address different concerns: ACID consistency is about transactional correctness within a single database, while CAP consistency is about distributed system agreement.

## Advanced Level Questions

### Q11: How does MVCC improve concurrency compared to traditional locking?
**A**: MVCC (Multiversion Concurrency Control) improves concurrency by allowing readers to access consistent snapshots of data without blocking writers, and writers to create new versions without blocking readers. 

**Traditional locking problems**:
- Readers block writers and writers block readers
- Read-write conflicts limit concurrency
- Long-running readers can block writers indefinitely

**MVCC advantages**:
- Readers access snapshots based on transaction start time
- Writers create new versions rather than overwriting
- No reader-writer blocking
- Better performance for read-heavy workloads
- Eliminates deadlocks from reader-writer conflicts

### Q12: Explain the write skew anomaly and how it's prevented.
**A**: Write skew is an anomaly that can occur even with snapshot isolation, where two transactions concurrently read overlapping data, make decisions based on what they read, and then update disjoint data, resulting in a constraint violation.

**Example**:
```
Constraint: At least one doctor must be on call
Initial: DrA.on_call = true, DrB.on_call = false (constraint satisfied)

T1 (DrA): READ DrA.on_call (true), READ DrB.on_call (false)
          IF (no one on call) THEN SET DrA.on_call = false
T2 (DrB): READ DrB.on_call (false), READ DrA.on_call (true)
          IF (no one on call) THEN SET DrB.on_call = false

Both T1 and T2 see: one doctor on call (constraint satisfied)
Both conclude: they can go off call
Both commit: DrA.on_call = false, DrB.on_call = false
Result: No doctor on call (constraint violated)
```

**Prevention**: 
- Serializable Snapshot Isolation (SSI) detects dangerous patterns and aborts one transaction
- SERIALIZABLE isolation level with predicate locking
- Application-level constraint checking

### Q13: How do distributed databases achieve ACID properties?
**A**: Distributed databases achieve ACID through various techniques:

**Atomicity**: 
- Two-phase commit (2PC) protocol
- Three-phase commit (3PC) to reduce blocking
- Paxos/Raft consensus algorithms for replicated state machines

**Consistency**:
- Distributed consensus protocols
- Quorum-based reads and writes
- Conflict-free replicated data types (CRDTs) for eventual consistency models

**Isolation**:
- Distributed locking services (like Chubby or ZooKeeper)
- Timestamp ordering with synchronized clocks (Google Spanner's TrueTime)
- Partitioned locking with deadlock detection

**Durability**:
- Replication across multiple nodes/availability zones
- Persistent write-ahead logs on each node
- Geographic distribution for disaster recovery

**Examples**:
- Google Spanner: Uses TrueTime API for global clock synchronization + Paxos replication
- CockroachDB: Uses Raft replication + timestamp ordering
- FoundationDB: Uses layered architecture with deterministic simulation testing

### Q14: What are the trade-offs between ACID and BASE approaches?
**A**:

| Aspect | ACID | BASE |
|--------|------|------|
| **Consistency** | Strong, immediate | Eventual, temporary inconsistency allowed |
| **Availability** | Lower (may block during partitions) | Higher (continues operating during partitions) |
| **Performance** | Predictable, lower throughput | Higher throughput, variable latency |
| **Use Case** | Financial systems, healthcare | Social media, caching, analytics |
| **Complexity** | Well-understood, mature | Evolving, requires application-level consistency handling |
| **Failure Handling** | Blocks or aborts during partitions | Continues with potential inconsistency |

**Choose ACID when**: Data correctness is paramount (banking, medical records, inventory)
**Choose BASE when**: Availability and performance are more important than immediate consistency (social media feeds, likes/counts, recommendation systems)

### Q15: How would you test if a database system truly provides ACID guarantees?
**A**: To test ACID claims, I would design specific tests for each property:

**Atomicity Tests**:
1. Simulate system crash during transaction and verify rollback
2. Test constraint violations mid-transaction cause full rollback
3. Test power failure scenarios with transaction state verification

**Consistency Tests**:
1. Verify all constraints are enforced (check, foreign key, unique)
2. Test trigger execution maintains consistency
3. Verify business rules are preserved across complex transactions

**Isolation Tests**:
1. Test for dirty reads at different isolation levels
2. Test for non-repeatable reads and phantom reads
3. Test write skew anomaly detection
4. Measure actual concurrency levels achieved

**Durability Tests**:
1. Verify committed data survives power failure
2. Test recovery process after simulated crash
3. Validate WAL checkpointing and archiving
4. Check that commit acknowledgment only happens after durable storage

**Tools**: 
- Jepsen framework for distributed systems testing
- Custom failure injection scripts
- Performance benchmarking under failure conditions
- Log analysis to verify WAL behavior

## Scenario-Based Questions

### Q16: A user reports that their bank balance shows incorrect amounts after concurrent transactions. What ACID property is likely violated and how would you investigate?
**A**: This suggests an **Isolation** violation, likely a lost update or dirty read scenario.

**Investigation Steps**:
1. Check the isolation level being used (READ COMMITTED vs REPEATABLE READ vs SERIALIZABLE)
2. Look for missing locks or incorrect lock duration
3. Analyze the transaction code for proper locking patterns
4. Check if MVCC is implemented correctly (if applicable)
5. Look for read-modify-write patterns without proper protection
6. Test with transaction tracing to see actual execution order
7. Verify that balance updates are atomic operations

**Likely Causes**:
- Using READ COMMITTED when REPEATABLE READ is needed
- Application-level race conditions not protected by transactions
- Missing WHERE clauses causing broader locks than intended
- Long-held locks causing timeout and retry issues

### Q17: During a system maintenance window, the database crashed. After restart, some recently confirmed transactions were missing. What ACID property failed and why?
**A**: This indicates a **Durability** failure. The system acknowledged transaction commits but the data was not actually persisted to stable storage.

**Possible Causes**:
- Write-Ahead Logging not properly implemented (log not flushed before commit)
- I/O caching layer not being flushed (write-back cache without power loss protection)
- Storage subsystem lying about write completion (common with some consumer-grade disks)
- Commit acknowledgment sent before WAL flush completed
- Checkpointing process not functioning correctly

**Investigation**:
1. Check WAL configuration and flush settings
2. Verify storage subsystem reports write completion accurately
3. Check for battery-backed or capacitor-protected write cache
4. Review commit acknowledgment timing in database code
5. Test with controlled power failure scenarios
6. Verify checkpoint frequency and completion

### Q18: You're designing a system that needs to handle millions of social media posts per day with high availability. Would you choose ACID or BASE and why?
**A**: For a social media system handling millions of posts per day with high availability requirements, I would choose a **BASE approach** with selective use of ACID where needed.

**Reasoning**:
1. **Availability is critical**: Social media users expect the platform to be always available
2. **Temporary inconsistency is acceptable**: A post or like might take a few seconds to appear everywhere
3. **Read-heavy workload**: Most operations are reading feeds, not writing
4. **Geographic distribution**: Users worldwide need low-latency access
5. **Scale requirements**: Millions of operations per day demand high throughput

**Selective ACID Usage**:
- **User account operations**: ACID (login, profile changes, password updates)
- **Financial transactions** (if any): ACID (ad purchases, premium subscriptions)
- **Content moderation**: ACID (to ensure consistent state)
- **Posts, likes, comments, follows**: BASE (eventual consistency acceptable)
- **Feed generation**: BASE (can tolerate slightly stale data)
- **Analytics counters**: BASE (approximate counts acceptable)

**Implementation**:
- Use a distributed NoSQL database (like Cassandra or DynamoDB) as primary store
- Use ACID-compliant database (like PostgreSQL) for critical operations
- Implement application-level conflict resolution where needed
- Use caching layers (Redis/CDN) for read performance
- Implement eventual consistency protocols with conflict resolution

### Q19: Explain how you would explain ACID to a non-technical stakeholder.
**A**: I would use everyday analogies that map to each property:

**Atomicity**: "Think of a light switch - it's either completely ON or completely OFF. There's no 'half-on' state. Similarly, a database transaction either happens completely or not at all - like transferring money where either both accounts are updated or neither is changed."

**Consistency**: "Imagine the rules of a board game that everyone must follow. Consistency ensures that no matter what moves players make, the game state always follows the rules. In a database, this means things like account balances never going negative or inventory counts always matching the sum of warehouse stock."

**Isolation**: "Picture separate checkout lines at a grocery store. Each customer can complete their purchase without worrying about what others are doing in different lines. Similarly, database isolation ensures that one person's transaction doesn't interfere with another's, even when they're happening at the same time."

**Durability**: "Once you get a receipt for a purchase, you know the store has to honor it - even if their systems crash right after. Database durability means that once a transaction is confirmed, it's permanently recorded and will survive any system failure, just like that receipt is proof of purchase."

**Summary**: "ACID is the database's promise that your data will be correct, consistent, and safe - no matter what happens."

### Q20: What emerging trends are you seeing in ACID implementations for 2024-2025?
**A**: Several important trends are shaping ACID implementations:

1. **Hardware Acceleration**: 
   - Persistent memory (Intel Optane) reducing logging overhead
   - NVMe storage changing I/O performance characteristics
   - Smart NICs offloading network and processing tasks

2. **NewSQL Innovations**:
   - Google Spanner-style global distribution with strong consistency
   - CockroachDB and similar systems providing ACID at scale
   - FoundationDB's layered approach with simulation testing

3. **Cloud-Native Approaches**:
   - Serverless databases with automatic scaling
   - Multi-region ACID transactions with latency optimization
   - Kubernetes-native database operators

4. **AI/ML Integration**:
   - Predictive indexing and query optimization
   - Automated tuning of isolation levels based on workload
   - Anomaly detection for transaction patterns

5. **Formal Verification**:
   - Mathematically proving transaction correctness
   - Model checking for concurrency control algorithms
   - Automated proof generation for locking protocols

6. **Hybrid Models**:
   - Tunable consistency levels per transaction/operation
   - Adaptive systems that switch between ACID and BASE based on context
   - Application-controlled consistency with database guarantees as foundation

7. **Edge Computing**:
   - ACID transactions at the edge with synchronization to core
   - Conflict resolution strategies for disconnected operation
   - Local ACID with eventual consistency to central systems

These trends show that while the core ACID principles remain unchanged, their implementation is evolving to meet modern demands for scale, performance, and geographic distribution while maintaining the fundamental guarantees applications depend on.