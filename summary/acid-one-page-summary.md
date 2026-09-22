# ACID Properties: One-Page Summary

## The Four Pillars of Reliable Transactions

### ATOMICITY
**Guarantee**: All-or-nothing execution
**Mechanism**: Undo logs, rollback capability
**Violation**: Partial transaction execution
**Real Example**: Bank transfer where only debit occurs
**Key Point**: "Either all operations succeed or none are applied"

### CONSISTENCY
**Guarantee**: Valid state transitions (constraints preserved)
**Mechanism**: Constraint checking, triggers, validation
**Violation**: Database rules broken after transaction
**Real Example**: Account balance going negative despite CHECK constraint
**Key Point**: "Database moves from one valid state to another"

### ISOLATION
**Guarantee**: Serializable execution (transactions don't interfere)
**Mechanism**: Locking, MVCC, isolation levels
**Violation**: Dirty reads, non-repeatable reads, phantom reads
**Levels**: READ UNCOMMITTED → READ COMMITTED → REPEATABLE READ → SERIALIZABLE
**Key Point**: "Concurrent transactions appear to execute sequentially"

### DURABILITY
**Guarantee**: Permanent storage of committed transactions
**Mechanism**: Write-Ahead Logging (WAL), checkpointing
**Violation**: Lost committed transaction after crash
**Real Example**: Transaction acknowledged but lost due to power failure before disk write
**Key Point**: "Once committed, data survives any system failure"

## Quick Reference Table

| Property | Guarantee | Mechanism | Anomaly Prevented |
|----------|-----------|-----------|-------------------|
| **Atomicity** | All-or-nothing | Undo/redo logs | Partial updates |
| **Consistency** | Valid states | Constraints/triggers | Invalid data states |
| **Isolation** | Serial execution | Locking/MVCC | Dirty/non-repeatable/phantom reads |
| **Durability** | Permanent storage | WAL/checkpointing | Lost committed transactions |

## Isolation Levels Compared

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Use Case |
|-------|------------|---------------------|--------------|----------|
| READ UNCOMMITTED | Possible | Possible | Possible | Rare (analytics only) |
| READ COMMITTED | Prevented | Possible | Possible | Default in many DBs |
| REPEATABLE READ | Prevented | Prevented | Possible | MySQL InnoDB default |
| SERIALIZABLE | Prevented | Prevented | Prevented | Financial systems |

## ACID vs BASE

### ACID (Traditional DBs)
- **Consistency**: Strong, immediate
- **Availability**: Lower during partitions
- **Use Case**: Banking, healthcare, inventory
- **Example**: Financial transactions where accuracy is critical

### BASE (Distributed Systems)
- **Consistency**: Eventual, temporary inconsistency allowed
- **Availability**: Higher, continues during partitions
- **Use Case**: Social media, caching, analytics
- **Example**: Likes, comments, views that can tolerate brief delays

## Common Interview Examples

### Atomicity Violation
**Scenario**: Money transfer where debit succeeds but credit fails
**Result**: Money disappears from source account
**Prevention**: Proper rollback mechanisms

### Consistency Violation
**Scenario**: Transfer resulting in negative balance despite constraint
**Result**: Database contains invalid state
**Prevention**: Constraint validation before/after transaction

### Isolation Violation (Dirty Read)
**Scenario**: 
- T1 reads uncommitted balance of $1000
- T2 credits $500 then rolls back
- T1 decides based on $1000 (actual $500)
**Result**: Incorrect business decision
**Prevention**: READ COMMITTED or higher isolation level

### Durability Violation
**Scenario**: Transaction commits, system crashes before disk write
**Result**: Committed transaction lost
**Prevention**: Write-Ahead Logging with proper flush

## Key Implementation Mechanisms

### Write-Ahead Logging (WAL)
1. Log changes to WAL buffer
2. Flush WAL to disk before applying changes
3. Only return success after commit record is on disk
4. Recovery: Replay WAL to redo committed transactions

### Multiversion Concurrency Control (MVCC)
- Each transaction sees snapshot at start time
- Readers don't block writers, writers don't block readers
- Multiple versions maintained with timestamps
- Used by: PostgreSQL, MySQL InnoDB, Oracle

### Two-Phase Locking (2PL)
- Growing phase: Acquire locks
- Shrinking phase: Release locks
- Prevents: Lost updates, ensures serializability
- Variants: Strict 2PL (holds X-locks until commit)

## Decision Framework

**Choose ACID when**:
- Financial accuracy is paramount
- Business rules are complex and interdependent
- Legal/compliance requirements exist
- Single source of truth is required

**Consider BASE when**:
- User experience depends on availability
- Data can tolerate brief inconsistency
- System must handle massive scale
- Geographic distribution creates latency challenges

## Remember: The ACID Promise
When a database claims ACID compliance, it guarantees:
- Your money transfers won't leave money in limbo (Atomicity)
- Your account balance won't mysteriously go negative (Consistency)
- Your concurrent transactions won't interfere with each other (Isolation)
- Your confirmed transaction won't vanish after reboot (Durability)

---
*This summary captures the essential concepts for understanding and interviewing on ACID properties in database systems.*