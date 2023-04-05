create table test.tDepartment
(
	Id int identity(1, 1),
	Name varchar(100) not null
);

create table test.tEmployee
(
	Id int identity(1, 1),
	DepartmentId int not null,
	ChiefId int,
	Name varchar(100) not null,
	Salary float not null
);

-- Seed data
insert into test.tDepartment
(
	Name
)
values
(
	'Dep1'
),
(
	'Dep2'
),
(
	'Dep3'
);

insert into test.tEmployee
(
	DepartmentId,
	ChiefId,
	Name,
	Salary
)
values
-- dep1
(
	1,
	null,
	'Emp1 of Dep1',
	100000
),
(
	1,
	1,
	'Emp2 of Dep1',
	90000
),
(
	1,
	2,
	'Emp3 of Dep1',
	80000
),
-- dep2
(
	2,
	null,
	'Emp1 of Dep2',
	100000
),
(
	2,
	4,
	'Emp2 of Dep2',
	90000
),
(
	2,
	5,
	'Emp3 of Dep2',
	80000
),
(
	2,
	6,
	'Emp4 of Dep2',
	90000
),
(
	2,
	7,
	'Руковичкин',
	80000
),
--dep3
(
	3,
	null,
	'Emp1 of Dep3',
	100000
),
(
	3,
	null,
	'Emp2 of Dep3',
	90000
);

select * from test.tDepartment;
select * from test.tEmployee;
select 
	*
from 
	test.tEmployee as a
left join
	test.tDepartment as b
	on a.DepartmentId = b.Id;

-- task 1 emp with max salary
declare @maxSalary float = (select max(Salary) from test.tEmployee);
select
	Id,
	Name
from 
	test.tEmployee
where
	Salary = @maxSalary;

-- task 2 tree depth
with recursiveCte as
(
	select
		Id,
		ChiefId,
		0 as Depth
	from 
		test.tEmployee
	where
		ChiefId is null
	union all
	select
		a.Id,
		a.ChiefId,
		b.Depth + 1
	from 
		test.tEmployee as a
	inner join
		recursiveCte as b
		on a.ChiefId = b.Id

)
select 
	max(Depth) as MaxDepth
from 
	recursiveCte;

-- task 3 dep with max summary salary
with summarySalary as 
(
	select 
		a.DepartmentId,
		sum(a.Salary) as SumSalary
	from
		test.tEmployee as a
	group by 
		a.DepartmentId
),
maxSalaryDepartment as 
(
	select 
		DepartmentId,
		SumSalary 
	from 
		summarySalary
	where
		SumSalary = (select max(SumSalary) from summarySalary)
)
select
	b.Id,
	b.Name,
	a.SumSalary
from
	maxSalaryDepartment as a
left join
	test.tDepartment as b
	on a.DepartmentId = b.Id;

with numberedSalaries as 
(
	select 
		a.DepartmentId,
		sum(a.Salary) as SumSalary,
		ROW_NUMBER() over (order by sum(a.Salary) desc) as RowNumber
	from
		test.tEmployee as a
	group by 
		a.DepartmentId
)
select 
	 b.Id,
	 b.Name,
	 a.SumSalary
from 
	numberedSalaries as a
left join
	test.tDepartment as b
	on a.DepartmentId = b.Id
where
	a.RowNumber = 1;

-- task 4 like 
select 
	a.Id as EmpId,
	b.Name as DepartmentName,
	c.Name as ChiefName,
	a.Name as EmpName,
	a.Salary
from
	test.tEmployee as a
left join 
	test.tDepartment as b
	on a.DepartmentId = b.Id
left join 
	test.tEmployee as c
	on a.ChiefId = c.Id
where 
	a.Name like 'р%н'; -- careful for case sensitive