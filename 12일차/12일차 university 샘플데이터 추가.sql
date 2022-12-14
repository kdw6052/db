use university;

insert into department values
	(160,'컴퓨터 공학부','KH교육원 1관 1층','02-123-4567',null),
    (123,'기계 공학부','KH교육원 1관 2층','02-123-4568',null),
    (135,'전자 공학부','KH교육원 2관 3층','02-123-1234',null);

-- 컴퓨터 공학부에 2022년 홍길동 교수님이 오셨다. 이 때 홍길동 교수님의 정보를 추가하는 작업
-- 이때, 교수님 학번은 2022 160 001이 할당되어야 함
-- 교수 정보를 추가하기 위한 프로시저(입학년도, 이름, 학부명, 교수직위, 전화번호)
drop procedure if exists insert_professor;
delimiter //
create procedure insert_professor(
	in _year int,
    in _name varchar(20),
    in _dep varchar(20),
    in _state varchar(10),
    in _tel varchar(13)
)
begin
	declare _dep_num int;
    declare _professor_count int default 0;
    declare _professor_num char(10);
    
    -- _dep_num에 검색 결과인 160이 들어가도록 쿼리작성
    set _dep_num = (select de_num from department where de_name like _dep);
    if _dep_num is not null then
		set _professor_count = 
		(select count(*)+1 from professor where pr_num like concat(_year,_dep_num,'%'));
		set _professor_num = (concat(_year,_dep_num,lpad(_professor_count,3,'0')));
		insert into professor(pr_num,pr_name,pr_state,pr_de_num,pr_tel)
			values(_professor_num,_name,_state,_dep_num,_tel);
    end if;
end //
delimiter ;
call insert_professor(2022,'홍길동','컴퓨터 공학부', null,null);
call insert_professor(2022,'임꺽정','컴퓨터 공학부','정교수','010-1234-5678');

-- 학생 정보 추가를 위한 프로시저
-- 2022년에 고길동 학생이 컴퓨터 공학부에 입학, 지도 교수님은 같은과 홍길동 교수님.
-- 같은 과에 같은 이름을 가지는 교수가 없다고 가정
drop procedure if exists insert_student;
delimiter //
create procedure insert_student(
	in _year int,
    in _name varchar(20),
    in _dep varchar(20),
    in _pr_name varchar(20)
    
)
begin
	declare _pr_num char(10);
    declare _std_num char(10);
    declare _dep_num int;
    declare _std_count int;
    
	set _dep_num = (select de_num from department where de_name like _dep);
    if _dep_num is not null then
		set _std_count = 
			(select count(*)+1 from student where st_num like concat(_year,_dep_num,'%'));
		set _pr_num = 
			(select pr_num from professor where substring(pr_num,5,3) like _dep_num 
				and pr_name like _pr_name);
		set _std_num = (concat(_year,_dep_num,lpad(_std_count,3,'0')));
        if _pr_num is not null then
			insert into student
				values(_std_num,_name,1,'재학',_pr_num);
			insert into mojor(mo_st_num,mo_de_num)values(_std_num,_dep_num);
        end if;    
	end if;
end //
delimiter ;
call insert_student('2022','고길동','컴퓨터 공학부','홍길동');

-- '컴퓨터 개론', '월1,2', 3,1,2022,1,'2022160001'
-- '자바', '월1,2,3,4', 3,1,2022,1,'2022160001'
insert into lecture values
	(null,'컴퓨터 개론', '월1,2', 3, 1, 2022, 1, '2022160001'),
	(null,'자바', '화1,2,3,4', 3, 1, 2022, 1, '2022160001');
    
call insert_student(2022,'나길동','컴퓨터 공학부', '임꺽정');

-- 고길동 학생이 2022년 1학기 컴퓨터 개론과 2022년 1학기 자바를 수강
-- 나길동 학생이 2022년 1학기 자바를 수강
insert into course(co_st_num, co_le_num)
	select'2022160001',le_num from lecture
		where le_name like '컴퓨터 개론' and le_term like 1 and le_year = 2022;
insert into course(co_st_num, co_le_num)
	select'2022160001',le_num from lecture
		where le_name like '자바' and le_term like 1 and le_year = 2022;
insert into course(co_st_num, co_le_num)
	select'2022160002',le_num from lecture
		where le_name like '자바' and le_term like 1 and le_year = 2022;
-- 2022년 1학기 컴퓨터 개론을 수강하는 고길동 학생의 성적을 등록하려고 한다.
-- 중간은 100, 기말은 80, 출석 100, 과제 90점이고,비율은 중간4,기말4,출석1,과제1로
-- 성적이 계산되어 총점에 저장
-- 학점은 100이하 90이상 A, 90미만 80이상 B, 80미만 70이상 C, 70미만 60이상 D, 나머지 F
drop procedure if exists insert_score;
delimiter //
create procedure insert_score(
    in _st_num char(10),
    in _le_num int,
    in _mid int,
    in _final int,
    in _att int,
    in _home int
)
begin
	declare _total int default 0;
    declare _grade varchar(5);
    declare _co_num int;
    declare _type varchar(5);
        
    set _total = _mid*0.4 + _final*0.4 + _home*0.1 + _att*0.1;
    set _co_num = 
		(select co_num from course where co_st_num like _st_num and co_le_num = _le_num);
    insert into score
		values(null,_mid,_final,_home,_att,_total,_co_num);
	
    set _type = (select co_type from course where co_num = _co_num);
    if _type = '학점' then
		set _grade = 
			(case when _total <=100 and _total >=90 then 'A'
				when _total <90 and _total >=80 then 'B'
				when _total <80 and _total >=70 then 'C'
				when _total <70 and _total >=60 then 'D'
				when _total <60 then 'F' 
				end);
		update course set co_grade = _grade where co_num = _co_num;
	end if;
end //
delimiter ;
call insert_score('2022160001', 1, 100, 80, 100, 90);

-- 트리거를 이용하여 성적을 추가하는 작업
-- 2022년 1학기 자바를 수강하는 고길동 학생의 성적을 등록(학번과 강좌번호 이용)
-- 중간은 100, 기말은 80, 출석 100, 과제 90점이고, 비율은 중간4기말4출석1과제1로 성적 계산해 총점에 저장
-- 학점은 100이하 90이상 A, 90미만 80이상 B, 80미만 70이상 C, 70미만 60이상 D, 나머지 F
-- 수강번호가 2번이고, 중간은 100, 기말은 80, 출석100, 과제 90
-- insert전에 total과 학점을 계산하기 위한 트리거

drop trigger if exists insert_score;
delimiter //
create trigger insert_score before insert
on score
for each row
begin
	declare _grade varchar(5);
	declare _type varchar(5);
    declare _total int;
    
	set new.sc_total = 
		new.sc_mid*0.4 + new.sc_final*0.4 + new.sc_homework*0.1 + new.sc_attendance*0.1;
    set _total = new.sc_total;
    set _type = (select co_type from course where co_num = new.sc_co_num);
    
	if _type = '학점' then
		set _grade = 
			(case when _total <=100 and _total >=90 then 'A'
				when _total <90 and _total >=80 then 'B'
				when _total <80 and _total >=70 then 'C'
				when _total <70 and _total >=60 then 'D'
				when _total <60 then 'F' 
				end);
		update course set co_grade = _grade where co_num = new.sc_co_num;
	end if;
end //
delimiter ;
insert into score
	values(null, 90, 30, 100, 100, 0, 2);