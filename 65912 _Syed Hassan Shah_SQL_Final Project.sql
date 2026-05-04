-- ==========================================================
-- HS BANKING SYSTEM (FINAL COMPLETE FILE)
-- AUTHOR: SYED HASSAN SHAH (65912)
-- DATABASE: MySQL
-- ==========================================================

-- ===============================
-- RESET DATABASE (CLEAN START)
-- ===============================
DROP DATABASE IF EXISTS HS_Banking_System;
CREATE DATABASE HS_Banking_System;
USE HS_Banking_System;

-- ===============================
-- 1. BRANCH
-- ===============================
CREATE TABLE Branch (
    BranchID INT PRIMARY KEY,
    BranchCode VARCHAR(10) UNIQUE NOT NULL,
    BranchName VARCHAR(50) NOT NULL,
    City VARCHAR(50),
    Address TEXT
);

-- ===============================
-- 2. CUSTOMER
-- ===============================
CREATE TABLE Customer (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    CNIC VARCHAR(15) UNIQUE NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    DOB DATE,
    Gender ENUM('M','F'),
    Phone VARCHAR(15),
    Email VARCHAR(100),
    KYC_Status VARCHAR(20) DEFAULT 'Verified'
);

-- ===============================
-- 3. EMPLOYEE
-- ===============================
CREATE TABLE Employee (
    EmpID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    JobTitle VARCHAR(50),
    Department VARCHAR(50),
    Salary DECIMAL(10,2),
    BranchID INT,
    JoinDate DATE,
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- ===============================
-- 4. ACCOUNT
-- ===============================
CREATE TABLE Account (
    AccountNo INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    BranchID INT NOT NULL,
    AccountType ENUM('Savings','Current','Fixed Deposit','Business'),
    Balance DECIMAL(15,2) DEFAULT 0 CHECK (Balance >= 0),
    Status VARCHAR(20) DEFAULT 'Active',
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- ===============================
-- 5. TRANSACTIONS
-- ===============================
CREATE TABLE Transactions (
    TxnID INT AUTO_INCREMENT PRIMARY KEY,
    AccountNo INT,
    ToAccountNo INT NULL,
    TxnType ENUM('Deposit','Withdrawal','Transfer','Bill Payment'),
    Amount DECIMAL(15,2),
    TxnDateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (AccountNo) REFERENCES Account(AccountNo),
    FOREIGN KEY (ToAccountNo) REFERENCES Account(AccountNo)
);

-- ===============================
-- 6. LOAN
-- ===============================
CREATE TABLE Loan (
    LoanID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    EmpID INT,
    LoanType ENUM('Personal','Home','Car','Business'),
    Amount DECIMAL(15,2),
    InterestRate DECIMAL(5,2),
    Tenure INT,
    Status ENUM('Pending','Approved','Rejected','Closed') DEFAULT 'Approved',
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
);

-- ===============================
-- 7. LOAN REPAYMENT
-- ===============================
CREATE TABLE Loan_Repayment (
    RepayID INT AUTO_INCREMENT PRIMARY KEY,
    LoanID INT,
    DueDate DATE,
    PaidDate DATE,
    AmountPaid DECIMAL(15,2),
    Status ENUM('Paid','Unpaid') DEFAULT 'Unpaid',
    FOREIGN KEY (LoanID) REFERENCES Loan(LoanID)
);

-- ===============================
-- 8. CARD
-- ===============================
CREATE TABLE Card (
    CardID INT AUTO_INCREMENT PRIMARY KEY,
    AccountNo INT,
    CardType ENUM('Debit','Credit'),
    ExpiryDate DATE,
    Status ENUM('Active','Blocked','Expired') DEFAULT 'Active',
    FOREIGN KEY (AccountNo) REFERENCES Account(AccountNo)
);

-- ===============================
-- 9. ATM
-- ===============================
CREATE TABLE ATM (
    ATMID INT PRIMARY KEY,
    BranchID INT,
    Location VARCHAR(100),
    CashAvailable DECIMAL(15,2) DEFAULT 500000,
    Status ENUM('Active','Out of Service') DEFAULT 'Active',
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- ===============================
-- 10. ATM TRANSACTION
-- ===============================
CREATE TABLE ATM_Transaction (
    ATM_TxnID INT AUTO_INCREMENT PRIMARY KEY,
    ATMID INT,
    CardID INT,
    Amount DECIMAL(15,2),
    TxnDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ATMID) REFERENCES ATM(ATMID),
    FOREIGN KEY (CardID) REFERENCES Card(CardID)
);

-- ===============================
-- 11. NOTIFICATION
-- ===============================
CREATE TABLE Notification (
    NotifID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    Message TEXT,
    SentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Channel ENUM('SMS','Email'),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- ===============================
-- 12. AUDIT LOG
-- ===============================
CREATE TABLE Audit_Log (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50),
    ActionType VARCHAR(20),
    OldValue TEXT,
    ChangeDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===============================
-- TRIGGER: BALANCE UPDATE
-- ===============================
DELIMITER //
CREATE TRIGGER After_Transaction_Balance_Update
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.TxnType = 'Deposit' THEN
        UPDATE Account 
        SET Balance = Balance + NEW.Amount 
        WHERE AccountNo = NEW.AccountNo;

    ELSEIF NEW.TxnType IN ('Withdrawal','Bill Payment','Transfer') THEN
        UPDATE Account 
        SET Balance = Balance - NEW.Amount 
        WHERE AccountNo = NEW.AccountNo;
    END IF;
END //
DELIMITER ;

-- ===============================
-- TRIGGER: AUDIT LOG
-- ===============================
DELIMITER //
CREATE TRIGGER Audit_Account_Update
AFTER UPDATE ON Account
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (TableName, ActionType, OldValue)
    VALUES ('Account', 'UPDATE', CONCAT('Old Balance: ', OLD.Balance));
END //
DELIMITER ;

-- ===============================
-- VIEW: MANAGEMENT DASHBOARD
-- ===============================
CREATE VIEW Management_Dashboard AS
SELECT 
    b.BranchName,
    COUNT(a.AccountNo) AS TotalAccounts,
    SUM(a.Balance) AS TotalDeposits,
    (SELECT COUNT(*) FROM Loan WHERE Status = 'Approved') AS TotalActiveLoans
FROM Branch b
LEFT JOIN Account a ON b.BranchID = a.BranchID
GROUP BY b.BranchName;

-- ===============================
-- SAMPLE DATA
-- ===============================

-- Branch
INSERT INTO Branch VALUES (1, 'ISB01', 'Islamabad Main', 'Islamabad', 'I-14');
INSERT INTO Branch VALUES (2, 'RWP01', 'Rawalpindi Branch', 'Rawalpindi', 'Saddar');

-- Customers
INSERT INTO Customer (CNIC, FullName, Gender) VALUES 
('37405-1111111-1', 'Syed Hassan Shah', 'M'),
('37405-2222222-2', 'Mohammad Ali', 'M');

-- Employee
INSERT INTO Employee (Name, JobTitle, Department, Salary, BranchID) VALUES
('Ali Khan', 'Manager', 'Admin', 80000, 1),
('Usman Tariq', 'Loan Officer', 'Finance', 60000, 2);

-- Accounts
INSERT INTO Account (CustomerID, BranchID, AccountType, Balance) VALUES
(1,1,'Current',50000),
(2,2,'Savings',25000);

-- Transactions
INSERT INTO Transactions (AccountNo, TxnType, Amount) VALUES
(1,'Deposit',10000),
(2,'Withdrawal',5000);

-- Loan
INSERT INTO Loan (CustomerID, EmpID, LoanType, Amount, InterestRate, Tenure) VALUES
(1,1,'Car',1500000,12.5,60);

-- ATM
INSERT INTO ATM VALUES (1,1,'Main Hall',500000,'Active');

-- Card
INSERT INTO Card (AccountNo, CardType) VALUES (1,'Debit');

-- ATM Transaction
INSERT INTO ATM_Transaction (ATMID, CardID, Amount) VALUES (1,1,2000);

-- Notification
INSERT INTO Notification (CustomerID, Message, Channel) VALUES
(1,'Transaction Alert','SMS');

-- ===============================
--  FINAL CHECK
-- ===============================
SELECT * FROM Management_Dashboard;


INSERT INTO Account (CustomerID, BranchID, AccountType, Balance)
VALUES (1, 1, 'Savings', 0);

INSERT INTO Transactions (AccountNo, TxnType, Amount)
VALUES (2, 'Withdrawal', 10000);

SELECT AccountNo, Balance FROM Account WHERE AccountNo = 2;