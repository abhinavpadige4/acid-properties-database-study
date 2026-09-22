# Day 1: Atomicity and Consistency

## Atomicity

### Definition
Atomicity ensures that a transaction is treated as a single, indivisible unit of work. Either all operations within the transaction are completed successfully, or none are applied.

### Key Properties
1. **All-or-nothing principle**: No partial execution allowed
2. **Rollback mechanism**: System must be able to undo all changes if transaction fails
3. **Commit point**: Point of no return where transaction becomes permanent and visible to others

### Implementation Mechanisms

#### Undo Logs
- Before modifying any data, write the old value to a log
- If transaction fails, read log backwards and restore old values
- Log must be written to stable storage before data modifications

#### Shadow Paging
- Maintain two copies of database pages: current and shadow
- All modifications made to current copy
- On commit: switch pointers to make current copy the new shadow
- On crash: discard current copy, shadow remains consistent

#### Checkpointing
- Periodically save a consistent state of the database to disk
- Records all active transactions and dirty pages
- Reduces recovery time by limiting log replay needed

### Examples

#### Correct Atomicity
```
Transaction: Transfer $100 from A to B
1. READ balance_A (500)
2. balance_A = balance_A - 100 (400)
3. WRITE balance_A (400)
4. READ balance_B (300)
5. balance_B = balance_B + 100 (400)
6. WRITE balance_B (400)
COMMIT
```
Result: A=400, B=400 ✓

#### Atomicity Failure (System Crash)
```
Transaction: Transfer $100 from A to B
1. READ balance_A (500)
2. balance_A = balance_A - 100 (400)
3. WRITE balance_A (400)
4. SYSTEM CRASH
5. READ balance_B (300)  // Never executed
```
Recovery: Undo log shows A was 500, restore A=500
Result: A=500, B=300 (original state) ✓

#### Atomicity Failure (Constraint Violation)
```
Transaction: Transfer $600 from A to B (A has $500)
1. READ balance_A (500)
2. balance_A = balance_A - 600 (-100)  // Would violate constraint
3. Constraint check fails
4. ROLLBACK entire transaction
```
Result: A=500, B=300 (unchanged) ✓

## Consistency

### Definition
Consistency ensures that a transaction brings the database from one valid state to another, preserving all database rules, constraints, and invariants.

### Types of Constraints

#### 1. Domain Constraints
- Data types, ranges, formats
- Example: Age must be between 0 and 150

#### 2. Entity Integrity
- Primary key uniqueness and non-nullability
- Example: Each customer must have unique customer_id

#### 3. Referential Integrity
- Foreign key relationships
- Example: Order.customer_id must reference existing Customer.customer_id

#### 4. User-defined Constraints
- Check constraints, triggers, assertions
- Example: Account.balance >= 0
- Example: Salary must be >= minimum wage

### Implementation Mechanisms

#### Constraint Checking
- **Pre-condition checking**: Validate before transaction starts
- **Post-condition checking**: Validate after transaction completes
- **Invariant checking**: Validate database invariants

#### Triggers
- BEFORE triggers: Validate or modify data before change
- AFTER triggers: Perform actions after change
- INSTEAD OF triggers: Replace the triggering action

#### Stored Procedures
- Encapsulate multi-step operations that maintain consistency
- Provide transactional boundary for complex business rules

#### Declarative Constraints
- Built-in database mechanisms: PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK
- Automatically enforced by DBMS

### Examples

#### Consistency Maintenance
```
Constraint: Account.balance >= 0
Initial state: A=500, B=300 (both >= 0) ✓

Transaction: Transfer $200 from A to B
1. A = 500 - 200 = 300 (>= 0) ✓
2. B = 300 + 200 = 500 (>= 0) ✓
Final state: A=300, B=500 (both >= 0) ✓
```

#### Consistency Violation Prevention
```
Constraint: Account.balance >= 0
Initial state: A=500, B=300 (both >= 0) ✓

Transaction: Withdraw $600 from A
1. A = 500 - 600 = -100 (< 0) ✗
2. Constraint violation detected
3. Transaction ABORTED
Final state: A=500, B=300 (unchanged) ✓
```

#### Complex Consistency with Triggers
```
Constraint: Total department budget = sum of employee salaries
Trigger: AFTER UPDATE ON Employees.Salary
   UPDATE Departments 
   SET total_budget = (SELECT SUM(salary) FROM Employees WHERE dept_id = NEW.dept_id)
   WHERE dept_id = NEW.dept_id;
```

## Relationship Between Atomicity and Consistency

Atomicity alone doesn't guarantee consistency - a transaction could be atomic but leave database in inconsistent state if it violates constraints.

Consistency depends on both:
1. Starting from a consistent state
2. Transaction preserving consistency properties

If either fails, consistency is broken.

### Scenario: Atomic but Inconsistent
```
Constraint: AccountA.balance + AccountB.balance = 1000 (constant total)
Initial: A=600, B=400 (sum=1000) ✓

Transaction: 
1. A = A + 100 (700)
2. B = B - 50 (350)  // Forgot to maintain constant sum!
3. COMMIT
Final: A=700, B=350 (sum=1050) ✗
```
Atomic: Yes (all operations completed)
Consistent: No (constraint violated)

## Practical Implementation Notes

### Logging Strategy
- **Undo log**: Contains <transaction_id, data_item, old_value>
- **Redo log**: Contains <transaction_id, data_item, new_value> (used for durability)
- Log buffer flushed to disk before transaction commit

### Recovery Process
1. **Analysis phase**: Determine which transactions committed, which need undo/redo
2. **Redo phase**: Reapply all committed transactions from log
3. **Undo phase**: Rollback all incomplete transactions using undo log

### Performance Considerations
- Lock duration: Hold locks for minimum time needed
- Log I/O: Batch log writes, use group commit
- Checkpoint frequency: Balance between recovery time and runtime overhead

## Summary

Atomicity and Consistency work together to ensure reliable transaction processing:
- **Atomicity**: Protects against system failures during transaction execution
- **Consistency**: Protects against logical errors that violate business rules
- Together: Ensure database transitions only between valid states, even in presence of failures