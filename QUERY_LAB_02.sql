--a. Hiển thị name (first_name, last_name), salary và 15% salary cho tất cả
--nhân viên.
SELECT first_name , last_name , salary , salary*0.15 AS bonus
FROM employees;

--b. Tổng số tiền lương phải trả cho nhân viên là bao nhiêu?
SELECT SUM(salary) AS total_salary
FROM employees;

--c. Mức lương tối đa, tối thiểu, mức lương trung bình và số lượng nhân viên
--của công ty là bao nhiêu? (làm tròn sau dấu , 2 chữ số thập phân)
SELECT 
	ROUND(MAX(salary),2) AS max_salary,
	ROUND(MIN(salary),2) AS min_salary,
	ROUND(AVG(salary),2) AS avg_salary,
	COUNT(*) AS employee_count
FROM employees;

--d. Hiển thị các job_id và job_title khác nhau hiện có trong bảng employees,
--sắp xếp theo job_id?
SELECT DISTINCT job_id , job_title
FROM jobs
ORDER BY job_id;

-- e. Mức lương tối đa của nhân viên ở vị trí Programmer?
SELECT MAX(salary) 
FROM employees 
WHERE job_id = (SELECT job_id FROM jobs WHERE job_title = 'Programmer');

--f. Chênh lệch giữa mức lương tối đa và mức lương tối thiểu của tất cả nhân
--viên là bao nhiêu?
SELECT max(salary) - min(salary) as salary_difference
FROM employees

--g. Hiển thị id, first_name, last_name của tất cả manager
SELECT employee_id , first_name , last_name
FROM employees
WHERE employee_id IN (SELECT DISTINCT manager_id FROM employees);

--h. Hiển thị manager ID và mức lương thấp nhất của nhân viên chịu sự quản
--lý của manager ID tương ứng.
SELECT manager_id , MIN(salary) AS min_salary
FROM employees
WHERE manager_id IS NOT NULL
GROUP BY manager_id;

'''i. Hiển thị department ID, tên department và tổng số lương phải trả tương
ứng của từng phòng ban, chỉ hiển thị những phòng ban có tổng lương lớn
hơn 30000 và sắp xếp theo department_id'''

SELECT D.department_id , D.department_name , SUM(E.salary) AS sum_salary_departments
FROM departments AS D JOIN employees AS E ON D.department_id=E.department_id
GROUP BY D.department_id , D. department_name
HAVING SUM(E.salary) > 30000
ORDER BY department_id;

'''j. Hiển thị name, job_title, salary của những nhân viên không phải làm ở vị
trí Programmer hoặc Shipping Clerk, và không có mức lương là $4,500,
$10,000, hoặc $15,000'''
SELECT CONCAT (first_name,' ',last_name) AS name_employees , job_title, salary
FROM employees AS E JOIN jobs AS J ON E.job_id = J.job_id
WHERE job_title NOT IN ('Programmer', 'Shipping Clerk')
AND salary NOT IN (4500, 10000, 15000);


--k. Mức lương trung bình của các phòng ban có trên 5 nhân viên?
SELECT D.department_id , D.department_name , AVG(E.salary) AS avg_salary
FROM employees AS E JOIN departments AS D ON E.department_id=D.department_id
GROUP BY D.department_id , D.department_name
HAVING COUNT(E.employee_id) > 5;

--l. Hiển thị job title và mức lương trung bình tương ứng
SELECT job_title , AVG(salary) AS avg_salary
FROM jobs AS J join employees AS E ON J.job_id = E .job_id
GROUP BY job_title

--m. Hiển thị tên manager, tên phòng ban và thành phố tương ứng
SELECT CONCAT(first_name,'',last_name) AS name_manager , D.department_name , L.city
FROM employees AS E JOIN departments AS D ON E.department_id=D.department_id
					JOIN locations AS L ON D.location_id= L.location_id
WHERE 	employee_id IN (SELECT DISTINCT manager_id FROM employees WHERE manager_id IS NOT NULL );

'''n. Hiển thị job title, tên employee và sự khác biệt giữa lương của từng nhân
viên với mức lương thấp nhất trong công ty và chỉ hiển thị 3 kết quả có
mức lương chênh lệch nhiều nhất.'''








