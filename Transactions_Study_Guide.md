# Database Transactions Study Guide - Complete Beginner's Reference

## Table of Contents
1. [What is a Transaction?](#what-is-a-transaction)
2. [ACID Properties](#acid-properties)
3. [Transaction Control Commands](#transaction-control-commands)
4. [COMMIT](#commit)
5. [ROLLBACK](#rollback)
6. [SAVEPOINT](#savepoint)
7. [AUTOCOMMIT](#autocommit)
8. [Transaction States](#transaction-states)
9. [Practical Examples](#practical-examples)
10. [Best Practices](#best-practices)

---

## What is a Transaction?

A **transaction** is a logical unit of work that consists of one or more SQL statements. All statements in a transaction either **succeed together** or **fail together**.

### Real-World Analogy:

**Bank Transfer:**
```
1. Deduct $100 from Account A
2. Add $100 to Account B
```

**Problem:** What if the system crashes after step 1 but before step 2?
- Account A lost $100
- Account B didn't receive it
- Money disappeared! 💸

**Solution:** Use a **Transaction**
- Both steps complete successfully, OR
- Both steps are cancelled (rolled back)
- Money is never lost

### In Database Terms:

```sql
BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 'B';
COMMIT;  -- Make changes permanent
```

If anything fails, use:
```sql
ROLLBACK;  -- Undo all changes
```

---

## ACID Properties

Every transaction must follow **ACID** principles:

### A - Atomicity (All or Nothing)
**Definition:** Transaction is indivisible - either all operations complete or none do.

**Example:**
```sql
BEGIN
    INSERT INTO orders VALUES (1, 100, SYSDATE);
    UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 100;
    -- If second statement fails, first is also undone
    COMMIT;
END;
```

### C - Consistency (Data Integrity)
**Definition:** Database moves from one valid state to another valid state.

**Example:**
```sql
-- Before: Total balance = $10,000
-- After transfer: Total balance = $10,000 (still consistent)

-- This violates consistency:
UPDATE accounts SET balance = balance - 100 WHERE account_id = 'A';
-- Forgot to add to Account B! Total is now $9,900 ❌
```

### I - Isolation (Concurrent Transactions)
**Definition:** Transactions are isolated from each other until completed.

**Example:**
```
Transaction 1: Reading account balance
Transaction 2: Updating account balance

Transaction 1 won't see changes from Transaction 2 until it commits.
```

### D - Durability (Permanent Changes)
**Definition:** Once committed, changes are permanent (survive crashes/power loss).

**Example:**
```sql
UPDATE employees SET salary = 10000 WHERE employee_id = 100;
COMMIT;  -- Now saved to disk, even if server crashes
```

---

## Transaction Control Commands

Oracle provides these commands to control transactions:

| Command                   | Purpose                                |
| ------------------------- | -------------------------------------- |
| **COMMIT**                | Save all changes permanently           |
| **ROLLBACK**              | Undo all changes since last COMMIT     |
| **SAVEPOINT**             | Create a checkpoint within transaction |
| **SET TRANSACTION**       | Set transaction properties             |
| **ROLLBACK TO SAVEPOINT** | Undo changes to a specific point       |

---

## COMMIT

**COMMIT** makes all changes in the current transaction permanent.

### Syntax:
```sql
COMMIT;
```

### What Happens on COMMIT?
1. ✅ All changes are saved to the database
2. ✅ Locks are released
3. ✅ Changes become visible to other users
4. ✅ Transaction ends

### Example 1: Simple COMMIT
```sql
-- Start making changes
INSERT INTO employees (employee_id, first_name, salary)
VALUES (9999, 'John', 5000);

UPDATE employees 
SET salary = salary * 1.1 
WHERE department_id = 50;

-- Save changes permanently
COMMIT;

-- Now all users can see these changes
```

### Example 2: Bank Transfer with COMMIT
```sql
BEGIN
    -- Deduct from sender
    UPDATE accounts 
    SET balance = balance - 500 
    WHERE account_id = 101;
    
    -- Add to receiver
    UPDATE accounts 
    SET balance = balance + 500 
    WHERE account_id = 102;
    
    -- Make permanent
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Transfer successful');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Undo if error
        DBMS_OUTPUT.PUT_LINE('Transfer failed: ' || SQLERRM);
END;
/
```

### When Does Auto-COMMIT Occur?

Oracle automatically commits in these cases:
- ✅ DDL statements (CREATE, ALTER, DROP)
- ✅ DCL statements (GRANT, REVOKE)
- ✅ Exiting SQL*Plus normally
- ✅ When AUTOCOMMIT is ON

```sql
-- This auto-commits
CREATE TABLE test (id NUMBER);

-- These require manual COMMIT
INSERT INTO test VALUES (1);
UPDATE test SET id = 2;
DELETE FROM test;
```

---

## ROLLBACK

**ROLLBACK** undoes all changes since the last COMMIT.

### Syntax:
```sql
ROLLBACK;
```

### What Happens on ROLLBACK?
1. ❌ All changes are discarded
2. ✅ Database returns to previous state
3. ✅ Locks are released
4. ✅ Transaction ends

### Example 1: Simple ROLLBACK
```sql
-- Make changes
UPDATE employees SET salary = 99999 WHERE employee_id = 100;
DELETE FROM employees WHERE department_id = 50;

-- Oh no! That was a mistake!
ROLLBACK;

-- All changes undone, data is safe ✅
```

### Example 2: Conditional ROLLBACK
```sql
DECLARE
    v_balance NUMBER;
BEGIN
    -- Attempt withdrawal
    UPDATE accounts 
    SET balance = balance - 1000 
    WHERE account_id = 101
    RETURNING balance INTO v_balance;
    
    -- Check if balance is negative
    IF v_balance < 0 THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Insufficient funds');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Withdrawal successful');
    END IF;
END;
/
```

### Example 3: Error Handling with ROLLBACK
```sql
BEGIN
    INSERT INTO orders (order_id, customer_id, amount)
    VALUES (1001, 999, 5000);  -- Customer 999 doesn't exist
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed: ' || SQLERRM);
END;
/
```

---

## SAVEPOINT

**SAVEPOINT** creates a checkpoint within a transaction. You can rollback to this point without undoing the entire transaction.

### Syntax:
```sql
SAVEPOINT savepoint_name;
ROLLBACK TO SAVEPOINT savepoint_name;
```

### Why Use SAVEPOINTS?

Think of savepoints like **checkpoints in a video game**:
- You can go back to a checkpoint without restarting the entire game
- You can have multiple checkpoints
- You can choose which checkpoint to return to

### Example 1: Basic SAVEPOINT
```sql
BEGIN
    -- Step 1: Insert customer
    INSERT INTO customers (customer_id, name, balance)
    VALUES (101, 'Alice', 10000);
    
    SAVEPOINT customer_added;  -- Checkpoint 1
    
    -- Step 2: Insert order
    INSERT INTO orders (order_id, customer_id, amount)
    VALUES (1001, 101, 2000);
    
    SAVEPOINT order_added;  -- Checkpoint 2
    
    -- Step 3: Update inventory
    UPDATE inventory 
    SET quantity = quantity - 5 
    WHERE product_id = 50;
    
    -- Oops! Product out of stock, undo last step
    ROLLBACK TO SAVEPOINT order_added;
    
    -- Customer and order are still there, only inventory update undone
    COMMIT;
END;
/
```

### Example 2: Multiple SAVEPOINTS
```sql
BEGIN
    -- Initial balance: $10,000
    DECLARE
        v_balance NUMBER := 10000;
    BEGIN
        -- Purchase 1
        v_balance := v_balance - 1000;
        DBMS_OUTPUT.PUT_LINE('After purchase 1: $' || v_balance);
        SAVEPOINT after_purchase_1;
        
        -- Purchase 2
        v_balance := v_balance - 500;
        DBMS_OUTPUT.PUT_LINE('After purchase 2: $' || v_balance);
        SAVEPOINT after_purchase_2;
        
        -- Purchase 3
        v_balance := v_balance - 2000;
        DBMS_OUTPUT.PUT_LINE('After purchase 3: $' || v_balance);
        SAVEPOINT after_purchase_3;
        
        -- Realized purchase 3 was too expensive, undo it
        ROLLBACK TO SAVEPOINT after_purchase_2;
        
        -- Final balance: $8,500 (purchases 1 and 2 only)
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Final balance: $' || v_balance);
    END;
END;
/
```

**Output:**
```
After purchase 1: $9000
After purchase 2: $8500
After purchase 3: $6500
Final balance: $8500
```

### Example 3: Real-World Scenario - Shopping Cart
```sql
BEGIN
    DECLARE
        v_customer_id NUMBER := 101;
        v_total NUMBER := 0;
    BEGIN
        -- Add item 1
        INSERT INTO cart VALUES (v_customer_id, 'Laptop', 1200);
        v_total := v_total + 1200;
        SAVEPOINT item_1_added;
        
        -- Add item 2
        INSERT INTO cart VALUES (v_customer_id, 'Mouse', 25);
        v_total := v_total + 25;
        SAVEPOINT item_2_added;
        
        -- Add item 3
        INSERT INTO cart VALUES (v_customer_id, 'Monitor', 400);
        v_total := v_total + 400;
        SAVEPOINT item_3_added;
        
        -- Check if over budget ($1500)
        IF v_total > 1500 THEN
            -- Remove last item (monitor)
            ROLLBACK TO SAVEPOINT item_2_added;
            DBMS_OUTPUT.PUT_LINE('Monitor removed - over budget');
            v_total := v_total - 400;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Final total: $' || v_total);
        COMMIT;
    END;
END;
/
```

### SAVEPOINT Rules:

1. **Names must be unique** within a transaction
2. **Rolling back to a savepoint** releases all later savepoints
3. **COMMIT** releases all savepoints
4. **ROLLBACK** (without TO) undoes entire transaction

```sql
SAVEPOINT sp1;
SAVEPOINT sp2;
SAVEPOINT sp3;

ROLLBACK TO sp2;  -- sp3 is lost
ROLLBACK TO sp1;  -- sp2 is lost
ROLLBACK;         -- Everything undone, all savepoints lost
```

---

## AUTOCOMMIT

**AUTOCOMMIT** automatically commits after every DML statement.

### Check AUTOCOMMIT Status:
```sql
SHOW AUTOCOMMIT;
```

### Enable AUTOCOMMIT:
```sql
SET AUTOCOMMIT ON;
```

### Disable AUTOCOMMIT (default):
```sql
SET AUTOCOMMIT OFF;
```

### Example 1: With AUTOCOMMIT ON
```sql
SET AUTOCOMMIT ON;

-- Each statement commits automatically
INSERT INTO employees (employee_id, first_name, salary)
VALUES (9991, 'Alice', 5000);  -- Commits immediately

INSERT INTO employees (employee_id, first_name, salary)
VALUES (9992, 'Bob', 6000);  -- Commits immediately

-- Can't rollback previous statements!
ROLLBACK;  -- Does nothing
```

### Example 2: With AUTOCOMMIT OFF
```sql
SET AUTOCOMMIT OFF;

-- Statements are part of a transaction
INSERT INTO employees (employee_id, first_name, salary)
VALUES (9993, 'Charlie', 5500);

INSERT INTO employees (employee_id, first_name, salary)
VALUES (9994, 'David', 6500);

-- Still can rollback
ROLLBACK;  -- Both inserts undone ✅

-- Or commit
COMMIT;  -- Both inserts saved ✅
```

### When to Use AUTOCOMMIT?

| Use AUTOCOMMIT ON                | Use AUTOCOMMIT OFF                    |
| -------------------------------- | ------------------------------------- |
| ✅ Simple, independent operations | ✅ Related operations (all or nothing) |
| ✅ Data loading scripts           | ✅ Business transactions               |
| ✅ Testing individual queries     | ✅ Multiple-step processes             |

**Best Practice:** Keep AUTOCOMMIT OFF for transaction safety!

---

## Transaction States

A transaction goes through these states:

```
1. BEGIN → Transaction starts (implicit with first DML)
2. ACTIVE → Executing statements
3. PARTIALLY COMMITTED → Last statement executed
4. COMMITTED → Changes saved permanently (COMMIT)
5. ABORTED → Changes undone (ROLLBACK)
```

### Visual Flow:

```
Start
  ↓
BEGIN Transaction (implicit)
  ↓
INSERT INTO customers...  ← ACTIVE
  ↓
UPDATE orders...          ← ACTIVE
  ↓
Error? ───No──→ COMMIT ─→ COMMITTED ✅
  │
  Yes
  ↓
ROLLBACK ─→ ABORTED ❌
```

---

## Practical Examples

### Example 1: Product Inventory Management
```sql
CREATE TABLE product_inventory (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(100),
    stock NUMBER,
    price NUMBER(10,2)
);

BEGIN
    -- Insert products
    INSERT INTO product_inventory VALUES (1, 'Laptop', 50, 999.99);
    INSERT INTO product_inventory VALUES (2, 'Mouse', 200, 25.50);
    INSERT INTO product_inventory VALUES (3, 'Keyboard', 150, 75.00);
    
    -- Reduce stock of laptop
    UPDATE product_inventory 
    SET stock = stock - 10 
    WHERE product_id = 1;
    
    -- Create savepoint after stock update
    SAVEPOINT stock_update;
    
    -- Try to reduce stock below 0
    UPDATE product_inventory 
    SET stock = stock - 100 
    WHERE product_id = 1;
    
    -- Check if stock is negative
    DECLARE
        v_stock NUMBER;
    BEGIN
        SELECT stock INTO v_stock
        FROM product_inventory
        WHERE product_id = 1;
        
        IF v_stock < 0 THEN
            -- Rollback to savepoint
            ROLLBACK TO SAVEPOINT stock_update;
            DBMS_OUTPUT.PUT_LINE('Insufficient stock - last update rolled back');
        END IF;
    END;
    
    -- Commit valid changes
    COMMIT;
END;
/
```

### Example 2: Employee Salary Update with Savepoints
```sql
BEGIN
    -- Add new employee
    INSERT INTO employees (employee_id, first_name, last_name, 
                          email, hire_date, job_id, salary)
    VALUES (9995, 'Test', 'Employee', 'test@company.com',
            SYSDATE, 'IT_PROG', 5000);
    
    -- First increase: 10%
    UPDATE employees
    SET salary = salary * 1.10
    WHERE employee_id = 9995;
    
    SAVEPOINT salary_increase_10;
    
    -- Second increase: 5%
    UPDATE employees
    SET salary = salary * 1.05
    WHERE employee_id = 9995;
    
    SAVEPOINT salary_increase_15;
    
    -- Third increase: 5%
    UPDATE employees
    SET salary = salary * 1.05
    WHERE employee_id = 9995;
    
    -- Check final salary
    DECLARE
        v_salary NUMBER;
    BEGIN
        SELECT salary INTO v_salary
        FROM employees
        WHERE employee_id = 9995;
        
        DBMS_OUTPUT.PUT_LINE('Final salary: $' || v_salary);
        
        -- If over budget, rollback to 10% increase only
        IF v_salary > 6000 THEN
            ROLLBACK TO SAVEPOINT salary_increase_10;
            DBMS_OUTPUT.PUT_LINE('Rolled back to 10% increase');
        END IF;
    END;
    
    COMMIT;
END;
/
```

### Example 3: Customer and Order Transaction
```sql
CREATE TABLE customer (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100),
    balance NUMBER(10,2)
);

CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER REFERENCES customer(customer_id),
    order_amount NUMBER(10,2),
    order_date DATE DEFAULT SYSDATE
);

BEGIN
    -- Start transaction
    DECLARE
        v_customer_id NUMBER := 500;
        v_order_amount NUMBER := 2500;
        v_balance NUMBER;
    BEGIN
        -- Insert new customer
        INSERT INTO customer (customer_id, customer_name, balance)
        VALUES (v_customer_id, 'Jane Doe', 10000);
        
        SAVEPOINT customer_added;
        
        -- Check if sufficient balance
        SELECT balance INTO v_balance
        FROM customer
        WHERE customer_id = v_customer_id;
        
        IF v_balance >= v_order_amount THEN
            -- Create order
            INSERT INTO orders (order_id, customer_id, order_amount)
            VALUES (2001, v_customer_id, v_order_amount);
            
            -- Deduct from balance
            UPDATE customer
            SET balance = balance - v_order_amount
            WHERE customer_id = v_customer_id;
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Order placed successfully');
        ELSE
            -- Insufficient funds
            ROLLBACK TO SAVEPOINT customer_added;
            DBMS_OUTPUT.PUT_LINE('Insufficient balance');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Transaction failed: ' || SQLERRM);
    END;
END;
/
```

### Example 4: Multiple Savepoints for Transaction History
```sql
CREATE TABLE transactions (
    transaction_id NUMBER PRIMARY KEY,
    account_id NUMBER,
    transaction_type VARCHAR2(10),
    amount NUMBER(10,2),
    balance NUMBER(10,2),
    transaction_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

BEGIN
    DECLARE
        v_balance NUMBER := 10000;
        v_account_id NUMBER := 1001;
        v_trans_id NUMBER := 1;
    BEGIN
        -- Credit 1
        INSERT INTO transactions 
        VALUES (v_trans_id, v_account_id, 'CREDIT', 2000, 
                v_balance + 2000, SYSTIMESTAMP);
        v_balance := v_balance + 2000;
        v_trans_id := v_trans_id + 1;
        SAVEPOINT after_credit_1;
        DBMS_OUTPUT.PUT_LINE('Balance after credit 1: $' || v_balance);
        
        -- Debit 1
        INSERT INTO transactions 
        VALUES (v_trans_id, v_account_id, 'DEBIT', 500,
                v_balance - 500, SYSTIMESTAMP);
        v_balance := v_balance - 500;
        v_trans_id := v_trans_id + 1;
        SAVEPOINT after_debit_1;
        DBMS_OUTPUT.PUT_LINE('Balance after debit 1: $' || v_balance);
        
        -- Credit 2
        INSERT INTO transactions 
        VALUES (v_trans_id, v_account_id, 'CREDIT', 1500,
                v_balance + 1500, SYSTIMESTAMP);
        v_balance := v_balance + 1500;
        v_trans_id := v_trans_id + 1;
        SAVEPOINT after_credit_2;
        DBMS_OUTPUT.PUT_LINE('Balance after credit 2: $' || v_balance);
        
        -- Debit 2 (large amount)
        INSERT INTO transactions 
        VALUES (v_trans_id, v_account_id, 'DEBIT', 5000,
                v_balance - 5000, SYSTIMESTAMP);
        v_balance := v_balance - 5000;
        SAVEPOINT after_debit_2;
        DBMS_OUTPUT.PUT_LINE('Balance after debit 2: $' || v_balance);
        
        -- Undo last debit (it was too large)
        ROLLBACK TO SAVEPOINT after_credit_2;
        v_balance := v_balance + 5000;
        
        DBMS_OUTPUT.PUT_LINE('Final balance: $' || v_balance);
        COMMIT;
    END;
END;
/
```

---

## Best Practices

### ✅ DO:

1. **Always use transactions for related operations**
   ```sql
   BEGIN
       UPDATE table1...
       UPDATE table2...
       COMMIT;
   END;
   ```

2. **Handle exceptions with ROLLBACK**
   ```sql
   EXCEPTION
       WHEN OTHERS THEN
           ROLLBACK;
           -- Log error
   END;
   ```

3. **Use SAVEPOINT for complex transactions**
   ```sql
   SAVEPOINT before_risky_operation;
   -- Risky operation
   IF error THEN
       ROLLBACK TO SAVEPOINT before_risky_operation;
   END IF;
   ```

4. **Keep transactions short**
   - Locks are held during transaction
   - Long transactions = more lock contention

5. **Commit at logical boundaries**
   ```sql
   -- Good: One business operation
   BEGIN
       INSERT INTO orders...
       UPDATE inventory...
       COMMIT;
   END;
   ```

### ❌ DON'T:

1. **Don't forget to COMMIT**
   ```sql
   UPDATE employees SET salary = 10000;
   -- Forgot COMMIT! Changes not saved
   ```

2. **Don't use AUTOCOMMIT for multi-step operations**
   ```sql
   SET AUTOCOMMIT ON;
   UPDATE accounts SET balance = balance - 100;  -- Commits
   -- If crash here, money is lost!
   UPDATE accounts SET balance = balance + 100;  -- Never executes
   ```

3. **Don't hold transactions open too long**
   ```sql
   -- Bad: User input during transaction
   BEGIN
       UPDATE accounts...
       -- Wait for user input (locks held!)
       v_input := &user_input;
       UPDATE accounts...
       COMMIT;
   END;
   ```

4. **Don't nest transactions** (Oracle doesn't support)
   ```sql
   -- Not supported in Oracle
   BEGIN TRANSACTION;
       BEGIN TRANSACTION;  -- ❌ Can't nest
       COMMIT;
   COMMIT;
   ```

---

## Locking and Concurrency

### Transaction Isolation Levels

Determines how transactions interact with each other:

| Level                           | Dirty Read  | Non-Repeatable Read | Phantom Read |
| ------------------------------- | ----------- | ------------------- | ------------ |
| Read Uncommitted                | ✅ Possible  | ✅ Possible          | ✅ Possible   |
| Read Committed (Oracle default) | ❌ Prevented | ✅ Possible          | ✅ Possible   |
| Repeatable Read                 | ❌ Prevented | ❌ Prevented         | ✅ Possible   |
| Serializable                    | ❌ Prevented | ❌ Prevented         | ❌ Prevented  |

### Set Transaction Isolation:
```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

### Example: Read Consistency
```sql
-- Session 1
UPDATE employees SET salary = 10000 WHERE employee_id = 100;
-- Not committed yet

-- Session 2
SELECT salary FROM employees WHERE employee_id = 100;
-- Still sees old value (read consistency)

-- Session 1
COMMIT;

-- Session 2
SELECT salary FROM employees WHERE employee_id = 100;
-- Now sees new value (10000)
```

---

## Quick Reference

### Transaction Commands
```sql
-- Begin (implicit with first DML)
INSERT INTO table...

-- Save permanently
COMMIT;

-- Undo everything
ROLLBACK;

-- Create checkpoint
SAVEPOINT name;

-- Undo to checkpoint
ROLLBACK TO SAVEPOINT name;

-- Set properties
SET TRANSACTION READ ONLY;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

### Transaction Properties
```sql
-- Enable/disable autocommit
SET AUTOCOMMIT ON;
SET AUTOCOMMIT OFF;

-- Check status
SHOW AUTOCOMMIT;
```

---

## Summary

**Key Concepts:**

1. **Transaction**: Group of SQL statements (all or nothing)
2. **ACID**: Atomicity, Consistency, Isolation, Durability
3. **COMMIT**: Make changes permanent
4. **ROLLBACK**: Undo changes
5. **SAVEPOINT**: Create checkpoint for partial rollback
6. **AUTOCOMMIT**: Auto-save after each statement (usually OFF)

**For Your Exam:**

- Understand ACID properties
- Know when to use COMMIT vs ROLLBACK
- Understand SAVEPOINT concept
- Know AUTOCOMMIT behavior
- Practice multi-step transaction scenarios

**Common Exam Questions:**
- What happens if you don't COMMIT?
- Difference between ROLLBACK and ROLLBACK TO SAVEPOINT?
- What is ACID?
- When to use AUTOCOMMIT ON vs OFF?

---

## Transaction Decision Tree

```
Is this a single independent operation?
│
├─ Yes → AUTOCOMMIT ON is OK
│
└─ No → Multiple related operations?
    │
    └─ Yes → Use transaction
        │
        ├─ Simple (2-3 steps)?
        │   └─ Use COMMIT/ROLLBACK only
        │
        └─ Complex (many steps)?
            └─ Use SAVEPOINT for checkpoints
```

---

Remember: Transactions are like **safety nets** - they ensure your data stays consistent even when things go wrong!

**Practice Tip:** Try creating scenarios where you intentionally cause errors and see how ROLLBACK saves your data!
