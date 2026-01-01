DROP TABLE tbl2;
CREATE TABLE tbl2 (
				id integer primary key,
				password varchar(30) unique,
				pid text,
				status integer,
				ts DATETIME DEFAULT CURRENT_TIMESTAMP
			);
ALTER TABLE  tbl2  ADD COLUMN lu_ts DATETIME DEFAULT NULL;
ALTER TABLE  tbl2  ADD COLUMN mail varchar(30) DEFAULT NULL;

#insert into tbl2 values('hello!',10, 1);
#insert into tbl2 values('byr!',20, 1);