#!/bin/bash
LOG=/tmp/machine_simon_test
PATCH_LOG=/tmp/_patch
NO_PATCH_LOG=/tmp/_nopatch
LOOP=2
CONN=60
TXSS=100

cat /dev/null > $LOG

echo "Start"
pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -x -c 'select * from pg_settings where name = $$prune_page_dirty_limit$$' >> $LOG

pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -c 'select pg_stat_reset(); select pg_stat_get_db_stat_reset_time(12913)' >> $LOG
pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -c 'select pg_stat_reset(); select pg_stat_get_db_stat_reset_time(12913)' >> $LOG

I_NOP_READ=$(pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -At -c 'select blks_read from pg_stat_database where datname = $$postgres$$')
I_NOP_HIT=$(pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -At -c 'select blks_hit from pg_stat_database where datname = $$postgres$$')

I_PAT_READ=$(pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -At -c 'select blks_read from pg_stat_database where datname = $$postgres$$')
I_PAT_HIT=$(pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -At -c 'select blks_hit from pg_stat_database where datname = $$postgres$$')

echo "DEBUG" 
echo $I_NOP_READ
echo $I_NOP_HIT
echo $I_PAT_READ
echo $I_PAT_HIT

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

L_NOP_READ=$(pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -At -c 'select blks_read from pg_stat_database where datname = $$postgres$$')
L_NOP_HIT=$(pg_NO_SIMON_PATCH/bin/psql -p8888 -Upostgres -At -c 'select blks_hit from pg_stat_database where datname = $$postgres$$')

L_PAT_READ=$(pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -At -c 'select blks_read from pg_stat_database where datname = $$postgres$$')
L_PAT_HIT=$(pg_SIMON_PATCH/bin/psql -p7777 -Upostgres -At -c 'select blks_hit from pg_stat_database where datname = $$postgres$$')

F_NOP_READ=$((L_NOP_READ-I_NOP_READ))
F_NOP_HIT=$(( L_NOP_HIT- I_NOP_HIT))
F_PAT_READ=$((L_PAT_READ-I_PAT_READ))
F_PAT_HIT=$(( L_PAT_HIT- I_PAT_HIT))

echo "DEBUG"
echo $I_NOP_READ
echo $I_NOP_HIT
echo $I_PAT_READ
echo $I_PAT_HIT
echo $L_NOP_READ
echo $L_NOP_HIT
echo $L_PAT_READ
echo $L_PAT_HIT

echo "RESULTS DIFFERENCES" >> $LOG

echo "F_NOP_READ " $F_NOP_READ >> $LOG
echo "F_NOP_HIT  " $F_NOP_HIT >> $LOG
echo "F_PAT_READ " $F_PAT_READ >> $LOG
echo "F_PAT_HIT  " $F_PAT_HIT >> $LOG
