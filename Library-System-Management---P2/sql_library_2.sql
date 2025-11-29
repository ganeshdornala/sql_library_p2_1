--SQL Project - Library Management System N2

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

/*
Task 13: 
Identify Members with Overdue Books 
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, 
member's name, book title, issue date, and days overdue.
*/

--issued_status==members==books==return_status
--filter books which is return
--overdue>30

SELECT m.member_id,m.member_name,b.book_title,is_st.issued_date,(CURRENT_DATE-is_st.issued_date) AS over_dues_days
FROM issued_status AS is_st
JOIN members AS m
ON is_st.issued_member_id=m.member_id
JOIN books AS b
ON is_st.issued_book_isbn=b.isbn
LEFT JOIN return_status AS re_st
ON is_st.issued_id=re_st.issued_id
WHERE 
re_st.return_date IS NULL
AND
(CURRENT_DATE-is_st.issued_date)>30
ORDER BY 1
;

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries 
in the return_status table).
*/

--Store Procedures
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10),p_issued_id VARCHAR(10),p_book_quality VARCHAR(15))
LANGUAGE plpgsql
AS $$
	
DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);
BEGIN
	--all logic and code
	--insert into returns based on users input
	INSERT INTO return_status(return_id,issued_id,return_date,book_quality)
	VALUES
	(p_return_id,p_issued_id,CURRENT_DATE,p_book_quality);

	SELECT issued_book_isbn,issued_book_name
	INTO v_isbn,v_book_name
	FROM issued_status
	WHERE issued_id=p_issued_id;

	UPDATE books
	SET status='yes'
	WHERE isbn=v_isbn;

	RAISE NOTICE 'Thank you for returning the book: %',v_book_name;
	
END;
$$

CALL add_return_records('RS138','IS135','Good');

CALL add_return_records('RS148', 'IS140', 'Good');


/*
Task 15: Branch Performance Report
Create a query that generates a performance report 
for each branch, showing the number of books issued, 
the number of books returned, and the total revenue 
generated from book rentals.
*/


CREATE TABLE branch_reports 
AS 
SELECT 
b.branch_id,
b.manager_id,
COUNT(ist.issued_id) AS number_books_issued,
COUNT(rst.return_id) AS number_books_returned,
SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN
employees AS e
ON e.emp_id=ist.issued_emp_id
JOIN
branch AS b
ON e.branch_id=b.branch_id
LEFT JOIN
return_status AS rst
ON ist.issued_id=rst.issued_id
JOIN 
books AS bk
ON ist.issued_book_isbn=bk.isbn
GROUP BY 1,2;


/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create 
a new table active_members containing members who 
have issued at least one book in the last 2 months.
*/

SELECT * FROM branch;
SELECT * FROM issued_status;
SELECT * FROM employees;
SELECT * FROM books;
SELECT * FROM return_status;


CREATE TABLE active_members AS
SELECT * FROM members WHERE member_id IN (
	SELECT 
DISTINCT issued_member_id
FROM issued_status
WHERE issued_date>=CURRENT_DATE-INTERVAL '2 month'
);

SELECT * FROM active_members;


/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have 
processed the most book issues. Display the 
employee name, number of books processed, and their 
branch.
*/

SELECT
	e.emp_name,
	b.*,
	COUNT(ist.issued_id) AS number_books_issued
FROM issued_status AS ist
JOIN
employees AS e
ON e.emp_id=ist.issued_emp_id
JOIN
branch AS b
ON e.branch_id=b.branch_id
GROUP BY 1,2
ORDER BY number_books_issued DESC
LIMIT 3;


/*
Task 18: Stored Procedure Objective: Create a stored
procedure to manage the status of books in a library
system. 
Description: Write a stored procedure that updates 
the status of a book in the library based on its 
issuance. 
The procedure should function as follows: 
The stored procedure should take the book_id as 
an input parameter. 
The procedure should first check if the book is 
available (status = 'yes').
If the book is available, it should be issued, and 
the status in the books table should be updated to 
'no'. 
If the book is not available (status = 'no'), 
the procedure should return an error message 
indicating that the book is currently not available.
*/


SELECT * FROM books;
SELECT * FROM issued_status;

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10),p_issued_member_id VARCHAR(30),p_issued_book_isbn VARCHAR(50),p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$
DECLARE
--all the vaiables
	v_status VARCHAR(10);
BEGIN
--all the code
--checking if book is available 'yes'
	SELECT status INTO v_status
	FROM books
	WHERE isbn=p_issued_book_isbn;
	IF v_status='yes' THEN 
		INSERT INTO issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		VALUES(p_issued_id,p_issued_member_id,CURRENT_DATE,p_issued_book_isbn,p_issued_emp_id);
		UPDATE books SET status='no' WHERE isbn=p_issued_book_isbn;
		RAISE NOTICE 'Book records added successfully for book isbn: %',p_issued_book_isbn;
	ELSE 
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %',p_issued_book_isbn;
	END IF;
END;
$$

CALL issue_book('IS155','C108','978-0-553-29698-2','E104');

CALL issue_book('IS156','C108','978-0-307-58837-1','E104');