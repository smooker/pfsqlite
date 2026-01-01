#!/bin/bash
sqlite3 test.db < create.sql
./dbitest.pl