CREATE DATABASE Library_Management;

USE Library_Management;
GO

--Creating Tables
CREATE TABLE Members_Info(
member_id int NOT NULL PRIMARY KEY,
member_name nvarchar(50) NOT NULL,
address_line nvarchar(50) NOT NULL,
member_dob date NOT NULL,
username nvarchar(50) NOT NULL,
user_password nvarchar(200) NOT NULL,
email nvarchar(50) NULL,
telephone nvarchar(20) NULL,
membership_endingdate date NULL
);

ALTER TABLE Members_Info
ALTER COLUMN membership_endingdate date NOT NULL;
-- for password hasing
ALTER TABLE  Members_Info
ADD  Salt UNIQUEIDENTIFIER;

INSERT INTO Members_Info (member_id, member_name, address_line, member_dob, username, user_password, email, telephone, membership_endingdate)
VALUES 
(1, 'Joy Paul', '123 Main St', '1980-01-01', 'joy', 'password1', 'joy@email.com', '555-1234', '2024-01-01'),
(2, 'Jane Smith', '456 Oak St', '1990-02-15', 'jsmith', 'password2', 'jsmith@email.com', '555-5678', '2023-05-01'),
(3, 'Bob Johnson', '789 Pine St', '1985-06-30', 'bjohnson', 'password3', NULL, '555-9876', '2022-12-31'),
(4, 'Emily Brown', '321 Elm St', '1995-12-25', 'ebrown', 'password4', 'ebrown@email.com', NULL, '2025-06-30'),
(5, 'David Lee', '555 Cedar St', '1978-09-10', 'dlee', 'password5', 'dlee@email.com', '555-4321', NULL);

UPDATE Members_Info
SET membership_endingdate = '2025-12-31'
WHERE member_id = 5;

SELECT * FROM Members_Info;

-- Library catelogue table
CREATE TABLE Library_Catalogue(
item_id int NOT NULL PRIMARY KEY,
title_of_item nvarchar(50) NOT NULL,
itemtype nvarchar(15) NOT NULL,
author nvarchar(50) NOT NULL,
publication_year int NOT NULL,
ISBN nvarchar(20) NULL,
date_of_collection date NOT NULL,
current_status nvarchar(20) NOT NULL,
identified_date date NULL
);

INSERT INTO Library_Catalogue (item_id, title_of_item, itemtype, author, publication_year, ISBN, date_of_collection, current_status, identified_date)
VALUES
(101, 'To Kill a Mockingbird', 'Book', 'Harper Lee', 1960, '9780446310789', '1961-05-11', 'Available', NULL),
(223, '1984', 'DVD', 'George Orwell', 1949, '9780451524935', '1950-06-08', 'On Loan', NULL),
(135, 'The Great Gatsby', 'Book', 'F. Scott Fitzgerald', 1925, '9780743273565', '1925-04-10', 'Lost', '2022-04-01'),
(506, 'The Catcher in the Rye', 'Journal', 'J.D. Salinger', 1951, '9780316769488', '1951-07-16', 'Over Due', NULL),
(443, 'Pride and Prejudice', 'DVD', 'Jane Austen', 1813, '9780486284736', '1813-01-28', 'On Loan', NULL);

UPDATE Library_Catalogue
SET ISBN = NULL
WHERE item_id = 506;

UPDATE Library_Catalogue
SET current_status = 'On Loan'
WHERE item_id = 223;

SELECT * FROM Library_Catalogue;

--Loan table
CREATE TABLE Loan(
member_id int NOT NULL FOREIGN KEY (member_id) REFERENCES Members_Info (member_id),
item_id int NOT NULL FOREIGN KEY (item_id) REFERENCES Library_Catalogue (item_id),
item_taken_out date NOT NULL,
item_due_back date NOT NULL,
item_actually_return date NOT NULL,
overduefee decimal(8,2) NOT NULL
);

ALTER TABLE Loan
ALTER COLUMN item_actually_return date NULL;

ALTER TABLE Loan
ADD loan_id int NOT NULL PRIMARY KEY;


INSERT INTO Loan (loan_id,member_id, item_id, item_taken_out, item_due_back, item_actually_return, overduefee) 
VALUES 
(11,1, 101, '2023-04-18', '2023-01-02', '2023-01-01', 0.00),
(12,2, 223, '2023-01-19', '2023-03-03', NULL, 0.00),
(13,3, 135, '2021-04-20', '2021-05-04', '2021-05-04', 0.00),
(14,4, 506, '2023-04-21', '2023-05-05', '2023-06-05', 3.00),
(15,5, 443, '2023-02-15', '2023-04-06', NULL, 0.00);

SELECT * from Loan;



--repayment table
CREATE TABLE Repayment(
member_id int NOT NULL FOREIGN KEY (member_id) REFERENCES Members_Info (member_id),
repaid_amount decimal(8,2) NULL,
timedate_of_repayment datetime NULL,
repayment_method nvarchar(10) NULL,
outstanding_balance decimal(8,2) NULL
);

ALTER TABLE Repayment
ADD repayment_id int NOT NULL PRIMARY KEY;

INSERT INTO Repayment (member_id, repaid_amount, timedate_of_repayment, repayment_method, outstanding_balance, repayment_id)
VALUES 
(4, 0.50, '2023-05-10 16:30:00', 'Card', 2.50, 1);

SELECT * FROM Repayment;


--2a : search catelogue mor matching charecter string
CREATE PROCEDURE SearchCatalogueByTitle
    @titleSearch nvarchar(50)
AS
BEGIN
    SELECT * FROM Library_Catalogue
    WHERE itemtype LIKE '%' + @titleSearch + '%'
    ORDER BY publication_year DESC;
END
EXEC SearchCatalogueByTitle 'Book';

--2b creating a user define function to Return a full list of all items currently on loan which have a due date of less than five days from the current date

CREATE FUNCTION dbo.ItemOnLoan()
RETURNS TABLE
AS
RETURN (
    SELECT LC.title_of_item, LC.current_status, L.item_due_back
    FROM Loan AS L
    INNER JOIN Library_Catalogue AS LC ON L.item_id = LC.item_id
    WHERE L.item_due_back <= DATEADD(day, 5, GETDATE())
    AND L.item_actually_return IS NULL
)

SELECT * FROM dbo.ItemOnLoan() ; 


--2c : inserting member normally
INSERT INTO Members_Info (member_id, member_name, address_line, member_dob, username, user_password, email, telephone, membership_endingdate)
VALUES (6, 'Marium Jahan', '45 station Rd', '1995-01-19', 'mjahan', 'gvytd56ygfuk', 'mjahan@email.com', '559-1234', '2024-11-23');

--2c: inserting member with password hashing by creating  procedure
--password hashing
CREATE PROCEDURE Addmemberpass
@member_id int ,
@member_name nvarchar(50) ,
@address_line nvarchar(50) ,
@member_dob date ,
@username nvarchar(50) ,
@user_password nvarchar(200) ,
@email nvarchar(50) ,
@telephone nvarchar(20) ,
@membership_endingdate date 
AS
DECLARE @salt UNIQUEIDENTIFIER=NEWID()


INSERT INTO Members_Info(member_id, member_name, address_line, member_dob, username, user_password, email, telephone, membership_endingdate, Salt)
VALUES(@member_id, @member_name, @address_line, @member_dob,@username ,HASHBYTES('SHA2_512', @user_password+CAST(@salt AS NVARCHAR(36))),@email,@telephone, @membership_endingdate, @salt);

EXECUTE Addmemberpass @member_id = 8,
@member_name = 'Zerin Jahan', @address_line = '64 highway St', 
@member_dob = '1997-07-28', @username= 'zjahan', @user_password= 'experiment101',
@email= 'zjahan@gmail',
@telephone='675-1234', @membership_endingdate= '2025-04-28';


--2d : update members detail by creating procedure
UPDATE Members_Info
SET user_password = '65vbjh98gyvh'
WHERE member_id = 5;
SELECT * FROM Members_Info;

CREATE PROCEDURE UpdateMemberInfo
    @memberId INT,
    @password NVARCHAR(200)
AS
BEGIN
    UPDATE Members_Info
    SET user_password = @password
    WHERE member_id = @memberId;

    SELECT * FROM Members_Info WHERE member_id = @memberId;
END;

EXEC UpdateMemberinfo @memberId = 5, @password = 'new784yhjh';



--ques 3 : view the loan history, showing all previous and current loans, and including details of the item borrowed, borrowed date, due date and any associated fines for each loan

CREATE VIEW LoanHistory AS
SELECT L.loan_id, L.member_id, M.member_name, LC.item_id, LC.title_of_item, L.item_taken_out, L.item_due_back, L.item_actually_return, L.overduefee
FROM Loan L
INNER JOIN Members_Info M ON L.member_id = M.member_id
INNER JOIN Library_Catalogue LC ON L.item_id = LC.item_id;

SELECT * FROM LoanHistory;

--ques 4: Creating a trigger so that the current status of an item automatically updates to Available when the book is returned

CREATE TRIGGER update_item_status
ON Loan
AFTER UPDATE
AS
BEGIN
  IF UPDATE(item_actually_return)
  BEGIN
    UPDATE Library_Catalogue
    SET current_status = 'Available'
    FROM Library_Catalogue LC
    INNER JOIN inserted i ON LC.item_id = i.item_id
    WHERE i.item_actually_return IS NOT NULL;
  END
END;
-- checking if the trigger is working after updating a value
UPDATE Loan
SET item_actually_return = NULL
WHERE member_id = 2;  



--ques 5: A view which allows the library to identify the total number of loans made on a specified date.

CREATE VIEW LoanCountByDate AS
SELECT item_taken_out AS loan_date, COUNT(*) AS loan_count
FROM Loan
WHERE item_actually_return IS NULL
GROUP BY item_taken_out;

SELECT loan_date, loan_count
FROM LoanCountByDate
WHERE loan_date = '2023-01-19';


--overdue fee calculation
-- ques 7: extra feature adding
CREATE TRIGGER CalculateOverdueFee
ON Loan
AFTER UPDATE
AS
BEGIN
  DECLARE @member_id int
  DECLARE @item_id int
  DECLARE @item_due_back date
  DECLARE @item_actually_return date
  DECLARE @days_late int
  DECLARE @overdue_fee decimal(8,2)

  SELECT @member_id = member_id,
         @item_id = item_id,
         @item_due_back = item_due_back,
         @item_actually_return = item_actually_return
  FROM inserted

  IF @item_actually_return > @item_due_back
  BEGIN
    SET @days_late = DATEDIFF(day, @item_due_back, @item_actually_return)
    SET @overdue_fee = @days_late * 0.1
    UPDATE Loan SET overduefee = @overdue_fee WHERE member_id = @member_id AND item_id = @item_id
  END
END


UPDATE Loan
SET item_actually_return = '2023-03-24'
WHERE member_id = 2;

SELECT * from Loan;






