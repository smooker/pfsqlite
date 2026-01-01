#!/bin/bash
sqlite3 test.db <<SQL
#.mode columns
.mode table
#.width 6 70 10 10
#select  'ABCDEFGHIJKLM','ABCDEFGHIJKLM','ABC','ABCDEFGHIJKLM';
select * from tbl2 where status<>2 or status=255;
#select * from tbl2 where status=255;
#select * from tbl2;
SQL