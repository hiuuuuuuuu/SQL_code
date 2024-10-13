--a.Hiển thị danh sách các phòng ban (department_name, city) kèm theo số lượng nhân viên,
--mức lương thấp nhất, cao nhất, trung bình và tổng lương của phòng ban tương ứng, sắp xếp theo id.
SELECT D.department_name , L.city,COUNT(E.employee_id),MAX(E.salary),MIN(E.salary),AVG(E.salary),
	    SUM(E.SALARY)
FROM departments AS D JOIN locations AS L ON D.location_id=L.location_id
					  LEFT JOIN employees AS E ON E.department_id=D.department_id
GROUP BY D.department_id,D.department_name,L.city
ORDER BY D.department_id ASC;

--b.Hiển thị danh sách các phòng ban (department_name, city) chỉ thuộc khu vực Americas kèm theo số 
--lượng nhân viên, tổng lương của phòng ban tương ứng, sắp xếp theo tổng lương từ cao đến thấp 
--và chỉ hiển thị danh sách có tổng lương > 30000.
WITH department_name_city AS (
SELECT D.department_name , L.city,
		COUNT(E.employee_id) AS employee_count ,
		SUM(E.salary) AS total_salary
FROM departments AS D JOIN locations AS L ON D.location_id=L.location_id
					  JOIN countries AS C ON L.country_id=C.country_id
					  JOIN regions AS R ON C.region_id=R.region_id
					  LEFT JOIN employees AS E ON D.department_id=E.department_id
WHERE R.region_name = 'Americas'
GROUP BY D.department_id , D.department_name ,L.city
)
SELECT * FROM department_name_city
WHERE total_salary > 30000
ORDER BY  total_salary DESC;

--c.Hiển thị danh sách các nhân viên được tuyển dụng vào tháng 6 
--nhưng loại trừ những nhân viên ở London.
SELECT E.*
FROM employees AS E JOIN departments AS D ON E.department_id=D.department_id
					JOIN locations AS L ON D.location_id=L.location_id
WHERE EXTRACT(MONTH FROM E.hire_date) = 6 AND L.city <> 'London';

--d.Hiển thị danh sách các manager (id, first_name, salary, job_title) có mức
--lương thuộc vào top 5 mức lương cao nhất.
			
WITH top_5_salary AS ( 	--Top 5 mức lương cao nhất trên toàn bộ nhân viên  (top_5_salary)
    SELECT DISTINCT salary
 	FROM employees 
    ORDER BY salary DESC
    LIMIT 5
),
Managers AS(   --Lọc manager 
    SELECT DISTINCT m.employee_id,
					m.first_name,
					m.salary,
					m.job_id
	FROM employees e 
 	JOIN employees m ON e.manager_id = m.employee_id
)
SELECT
    m.employee_id,
    m.first_name,
    m.salary,
	j.job_title
FROM Managers m  
JOIN jobs j ON m.job_id=j.job_id 
WHERE    --So sánh lương manager với MIN(top_5_salary)
	m.salary >= (SELECT MIN(salary) FROM top_5_salary); 

--e.Hiển thị first_name, last_name, salary, manager_id của những nhân viên
--chịu sự quản lý của các manager làm việc ở 'United States of America' mà
--có mức lương lớn hơn mức lương trung bình của các thành viên trong
--nhóm tương ứng.

			--Lọc manager làm việc ở 'United States of America' (CTE - us_manager)
WITH us_manager AS( 
SELECT DISTINCT m.employee_id 
FROM employees e 
JOIN employees m ON e.manager_id = m.employee_id
JOIN departments d ON e.department_id = d.department_id
JOIN locations l ON d.location_id = l.location_id
JOIN countries c ON l.country_id = c.country_id
WHERE c.country_id = 'US'
),	         --Tính avg_salary của các nhân viên chịu sự quản lý của us_manager tương ứng
avg_salaries AS (
	SELECT 
		m.employee_id AS manager_id,
		AVG(e.salary) AS avg_salary
	FROM employees e
	JOIN us_manager m ON e.manager_id=m.employee_id
	GROUP BY m.employee_id
)
			--So sánh lương của từng nhân viên với avg_salary (cùng manager)
SELECT
	e.first_name,
	e.last_name,
	e.salary,
	a.avg_salary,
	e.manager_id
FROM employees e
JOIN us_manager m ON e.manager_id=m.employee_id
JOIN avg_salaries a ON e.manager_id=a.manager_id
WHERE e.salary > a.avg_salary
ORDER BY e.manager_id;



--Dùng CTE đệ quy phân chia cây như sau: level 0 là người đứng đầu công
--ty (employee có manager_id là NULL), level 1 là manager chịu sự quản lý
--của người ở level 0, level 2 là manager chịu sự quản lý của người ở level
--1,...

WITH RECURSIVE ManagementTree AS (
    SELECT 
        e.employee_id,
        e.manager_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        NULL AS manager_name,
        0 AS level
    FROM  employees e
    WHERE  e.manager_id IS NULL
	
    UNION ALL

    SELECT 
        e.employee_id,
        e.manager_id,
        e.first_name  || ' ' || e.last_name  AS employee_name,
        m.first_name  || ' ' || m.last_name  AS manager_name,
        mt.level + 1 AS level
    FROM employees e JOIN ManagementTree mt ON e.manager_id = mt.employee_id
 					 JOIN employees m ON e.manager_id = m.employee_id
)
SELECT employee_id, manager_id, employee_name, manager_name, level
FROM  ManagementTree;

--Dùng CTE đệ quy phân chia cây như sau: Mức 0 là region, mức 1 là country
--thuộc region đó, mức 2 là city thuộc region-country đó.

WITH RECURSIVE region_tree AS(
	
	SELECT 
		region_id, region_name,
		NULL AS country_id,
		NULL AS city,
		0 AS level
	FROM regions
	
	UNION ALL
	
	SELECT c.region_id , c.country_id , c.country_name , NULL AS city , 1 AS level
	FROM countries c JOIN region_tree rt ON C.region_id=rt.region_id
	WHERE rt.level = 0
	
	UNION ALL
	
	SELECT l.region_id , l.country_id , l.country_name , l.city , 2 AS level 
	FROM locations l JOIN region_tree  rt ON l.country_id=rt.country_id
	WHERE rt.level = 1
)
SELECT * FROM region_tree


SELECT DISTINCT m.employee_id 
FROM employees e 
 JOIN employees m ON e.manager_id = m.employee_id


JOIN departments d ON e.department_id = d.department_id
JOIN locations l ON d.location_id = l.location_id
JOIN countries c ON l.country_id = c.country_id
WHERE c.country_name = 'United States of America';
