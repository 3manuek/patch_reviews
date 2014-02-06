#!/bin/bash

LOG=/tmp/machine_simon_test
PATCH_LOG=/tmp/_patch
NO_PATCH_LOG=/tmp/_nopatch
LOOP=20
CONN=60
TXSS=100

cat /dev/null > $LOG

echo "Start"
echo "stats NOPATCH" >> $LOG
pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -x -c 'select blks_read , blks_hit from pg_stat_database where datname = $$postgres$$ ' >> $LOG
echo "stats PATCHED" >> $LOG
pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -x -c 'select blks_read , blks_hit from pg_stat_database where datname = $$postgres$$ ' >> $LOG

pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -x -c 'select * from pg_settings where name = $$prune_page_dirty_limit$$' >> $LOG

pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -c 'select pg_stat_reset(); select pg_stat_get_db_stat_reset_time(12913)' >> $LOG
pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -c 'select pg_stat_reset(); select pg_stat_get_db_stat_reset_time(12913)' >> $LOG


echo "PGBENCH start"
echo "PGBENCH TESTS" >> $LOG
echo "" >>$LOG
echo "WITH PATCH" >>$LOG

for i in $(seq 1 $LOOP) ; do pg_SIMON_PATCH/bin/pgbench -c$CONN -t$TXSS -Sn -Upostgres -p7777 ; done | grep tps > $PATCH_LOG

cat $PATCH_LOG | awk ' {sum+=$3} END {print "Average: ",sum/NR} ' >> $LOG

echo "" >>$LOG
echo "NO PATCH" >>$LOG

for i in $(seq 1 $LOOP) ; do pg_NO_SIMON_PATCH/bin/pgbench -c$CONN -t$TXSS -Sn -Upostgres -p8888 ; done | grep tps > $NO_PATCH_LOG

cat $NO_PATCH_LOG | awk ' {sum+=$3} END {print "Average: ",sum/NR} ' >> $LOG

echo "Report"
echo "REPORT" >> $LOG

echo "stats NOPATCH" >> $LOG
pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -x -c 'select blks_read , blks_hit from pg_stat_database where datname = $$postgres$$ ' >> $LOG
echo "stats PATCHED" >> $LOG
pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -x -c 'select blks_read , blks_hit from pg_stat_database where datname = $$postgres$$ ' >> $LOG

#pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -c 'select * from pg_stat_database' >> $LOG
#pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -c 'select * from pg_stat_database' >> $LOG
