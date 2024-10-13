/* a.Hiển thị job_title, số lượng nhân viên và lương trung bình theo từng job_title.*/

SELECT 	job_title , 
		COUNT(E.employee_id) OVER(PARTITION BY job_title  ) AS so_luong_nhan_vien , 
		ROUND(AVG(E.salary) OVER(PARTITION BY job_title ),2) AS luong_trung_binh_theo_jobs
FROM jobs J JOIN employees E ON J.job_id=E.job_id
ORDER BY job_title

/* b.Với mỗi nhân viên, hiển thị first_name, last_name, salary và tổng salary của các nhân viên trong công ty.*/
SELECT 
	first_name,
	last_name, 
	salary,
	SUM(salary) OVER () AS tong_salary_cong_ty
FROM employees

/* c.Với mỗi nhân viên, hiển thị first_name, last_name, salary, trung bình lương của các nhân viên 
--trong công ty và sự chênh lệch lương của từng nhân viên với lương trung bình của công ty.*/

SELECT 
	first_name, 
	last_name, 
	salary ,
	ROUND(AVG(salary) OVER(),2) AS trung_binh_luong_nhan_vien,
	ROUND(salary - AVG(salary)  OVER() , 2) AS su_chenh_lech_luong
FROM employees

/*d.Với mỗi nhân viên của phòng ban ‘IT': hiển thị first_name, last_name, salary và chênh lệch giữa 
--lương của từng nhân viên với lương trung bình của các nhân viên trong phòng ban ‘IT'.*/
SELECT E.first_name, 
	   E.last_name, 
	   E.salary,
	   ROUND(salary - AVG(salary) OVER (PARTITION BY department_name),2) AS su_chenh_lech_luong
FROM employees E JOIN departments D ON E.department_id=D.department_id
WHERE department_name = 'IT'

/* e.Với mỗi nhân viên có mức lương hơn 7000, hiển thị first_name, last_name, salary và số 
--lượng nhân viên có lương cao hơn 7000, sắp xếp theo lương từ cao đến thấp.*/

SELECT first_name, 
	   last_name, 
	   salary ,
	   COUNT(*) OVER (ORDER BY salary DESC)
FROM employees
WHERE salary > 7000

/* f.Hiển thị first_name, last_name, tháng nhân viên đó được tuyển và số lượng nhân viên được 
--tuyển trong tháng đó.*/
SELECT
	first_name, 
	last_name,
	EXTRACT(month from hire_date) AS hire_month,
	COUNT(*) OVER(PARTITION BY EXTRACT(month from hire_date)) AS hire_count
FROM employees
ORDER BY hire_count

/*g.Hiển thị employee_id, first_name, last_name, tháng được tuyển, salary, manager_id, tên manager,
lương cao nhất trong nhóm các nhân viên được tuyển cùng tháng và cùng manager, sắp xếp theo
manager_id và tháng được tuyển.*/

	-- tạo ra cte EmployeeSummary tính lương cao nhất nhân viên được tuyển cùng một tháng cùng một 
	--manager , dùng row_number phân loại xếp hạng lương cùng một tháng và cùng manager
WITH EmployeeSummary AS (
	SELECT 
		employee_id,
		first_name,
		last_name,
		EXTRACT(month from hire_date) AS hire_month,
		salary,
		manager_id,
		MAX(salary) OVER(PARTITION BY EXTRACT(month from hire_date), manager_id) AS max_salary_in_month_and_manager,
		ROW_NUMBER() OVER(PARTITION BY EXTRACT(month from hire_date), manager_id ORDER BY salary DESC) AS rank_salary		
	FROM employees
)
	--từ cte truy vấn ra các thông tin cần  với nhân viên có mức lương cao nhất , sắp xếp theo
	--manager_id và tháng được tuyển
SELECT 
	employee_id,
	first_name,
	last_name,
	hire_month,
	salary,
	manager_id,
	(SELECT CONCAT(first_name,'',last_name) FROM employees e WHERE e.employee_id=ES.manager_id) AS manager_name 
FROM EmployeeSummary ES
WHERE rank_salary = 1
ORDER BY manager_id, hire_month;

/* h.Với mỗi nhân viên, hiển thị employee_ id, job_title, tên phòng ban nhân viên đó làm việc, 
số lượng nhân viên trong phòng ban cùng job_title và số lượng nhân viên cùng phòng ban. */
SELECT 
	employee_id,
	job_title,
	department_name,
	COUNT(*) OVER(PARTITION BY e.department_id, e.job_id) AS count_same_job_in_department,
	COUNT(*) OVER(PARTITION BY e.department_id) AS count_same_department
FROM employees e JOIN jobs j ON e.job_id=j.job_id
				 JOIN departments d ON e.department_id=d.department_id

/* i.Với mỗi nhân viên, hiển thị employee_id, salary, department_name, và ratio. Ratio được tính
 bằng lương của nhân viên trên tổng lương nhân viên trong cùng phòng ban, sắp xếp theo phòng ban.*/
SELECT 
	employee_id,
	salary,
	department_name,
	salary/(SUM(salary) OVER(PARTITION BY d.department_id)) AS ratio
FROM employees e JOIN departments d ON e.department_id=d.department_id
ORDER BY d.department_name

/* j.Sắp xếp nhân viên tăng dần theo salary, và tìm 20% nhân viên có lương cao nhất (Dùng ROW_NUMBER )*/

       --tạo ra một bảng tạm dùng row_number để để phân loại xếp hạng lương(sắp xếp 
	   -- lương tăng dần theo salary ) , đếm tổng số nhân viên 
WITH RankedEmployees AS(
	SELECT 
		employee_id,
		CONCAT(first_name,'',last_name) AS name_employee,
		salary,
		ROW_NUMBER() OVER(ORDER BY salary DESC) AS salary_rank,
		COUNT(*) OVER() AS total_employees
	FROM employees

)
       -- từ bảng tạm tìm ra 20% nhân viên có mức lương cao nhất
SELECT 
	employee_id,
	name_employee,
	salary
FROM RankedEmployees
WHERE salary_rank <= 0.2 * total_employees;

/* k.Với thành phố ’Seattle‘, hiển thị tên thành phố, tên các phòng ban và số lượng nhân viên trong 
 từng phòng ban, đồng thời hiển thị số phần trăm nhân viên của phòng ban đó trên tổng nhân viên 
 trong thành phố.*/
 																									
   -- tìm số lượng nhân viên trong từng phòng ban thành phố Seattle , tổng số nhân viên trong thành phố 
WITH Seattle_Employees AS (
	SELECT
		l.city,
		d.department_name,
		COUNT(*) AS num_employee_department,
		SUM(COUNT(*)) OVER(PARTITION BY l.city) AS total_employees_city
	FROM employees e 
	JOIN departments d ON e.department_id=d.department_id
	JOIN locations l ON l.location_id=d.location_id
	WHERE city = 'Seattle'
	GROUP BY l.city, d.department_name
)
   --tính phần trăm nhân viên của phòng ban đó với tổng số nhân viên 
SELECT
	city,
	department_name,
	num_employee_department,
	ROUND((num_employee_department/total_employees_city)*100,2) as percent_of_total	
FROM Seattle_Employees

/*l.Hiển thị first_name, last_name, tên phòng ban, phân hạng DENSE_RANK theo lương từ cao đến thấp
và chia thành 3 nhóm theo lương từ cao đến thấp (chia thành 3 nhóm dùng hàm NTILE()).*/
 
SELECT 
	e.first_name,
	e.last_name,
	d.department_name,
	DENSE_RANK() OVER(ORDER BY salary DESC) AS dense_rank_salary,
	NTILE(3) OVER(ORDER BY salary DESC) AS group_salary
FROM employees e
JOIN departments d ON e.department_id=d.department_id;
 
/* m.Với mỗi quốc gia, hiển thị số lượng nhân viên, tổng lương phải trả, lương trung bình và
sự chênh lệch lương trung bình giữa 2 quốc gia liền kề nhau, sắp xếp theo thứ tự lương
trung bình giảm dần.*/

	--tìm số lượng nhân viên, tổng lương phải trả, lương trung bình của mỗi quốc gia
WITH country_salary AS (
SELECT 
	c.country_name,
	COUNT(e.employee_id)  AS num_emp,
	ROUND(SUM(e.salary),2)  AS sum_sal,
	ROUND(AVG(e.salary),2) AS avg_sal
FROM employees e
JOIN departments d ON e.department_id=d.department_id
JOIN locations l ON d.location_id=l.location_id
JOIN countries c ON l.country_id=c.country_id
GROUP BY country_name
)	
	--tính sự chênh lệch  lương trung bình giữa hai quốc gia liền kề nhau   
SELECT
	country_name,
	num_emp,
	sum_sal,
	avg_sal,
	ROUND( ABS(LEAD(avg_sal) OVER(ORDER BY avg_sal DESC) - avg_sal) ,2) AS diff
	
FROM country_salary
ORDER BY avg_sal DESC;


