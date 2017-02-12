#!/usr/bin/env bash

# args: min, mix, file - function check if
# all numbers in file are in range (min,max)
function columnInRange
{
    min="$1";
    max="$2";

    cat | while read n
    do
        echo $n;
        assertTrue '[ 1 -eq $(echo $min"<"$n | bc -l) ]'
        assertTrue '[ 1 -eq $(echo $n"<"$max | bc -l) ]'
    done
}

# args: col, method and parameter for 1 file, method and parameter for 2 file
# function print ratio of given column form two files "log/out.[method][parameter].log
# col number | meaning
# 3          | size
# 4          | time
# 5          | speed
function ratioOfColumns
{
    col="$1";

    awk -F "|" 'FNR==NR{a[FNR] = $'$col'; next} {if(/inc/) printf "%12.6f\n", $'$col'/a[FNR]}' \
        log/out.$2.log log/out.$3.log
}

oneTimeSetUp() {

    for n in 1 2
    do
        for method in "l" "t"
        do
#                echo "$method$n";
              bash inc.bash -$method $n | tee log/out.$method$n.log
        done
    done
}

oneTimeTearDown() {
    rm -rf log/out.*.log
}


# in database there are 16 columns of parameters
test_parameters_are_proporly_estimated()
{
    infile=$(grep inc config/parameters.csv | wc -l);
    inbase=$(sqlite3 log/log.db "SELECT count(*) FROM result WHERE a>ea and b>eb");
    echo $infile;
    echo $inbase;
    assertEquals $infile $inbase;
}

# ratio of loops for 2 sec to 1 sec is between 1.9 and 2.1
test_ratio_of_loops_in_proper_range()
{
     ratioOfColumns 3 t1 t2 | columnInRange 1.95 2.2
}


# ratio of time for test with 2 sec and 1 sec should be near to 2
test_ratio_of_time_should_be_near_2_for_time_based_test()
{
    ratioOfColumns 4 t1 t2 | columnInRange 1.7 2.3;
}

# ratio of time for test with 2 and 1 loop should be near to 1
test_ratio_of_time_should_be_near_1_for_loop_based_test()
{
    ratioOfColumns 4 l1 l2 | columnInRange 0.8 1.7;
}

# any free language (without matlab and mathematica) start in time small than 0.2 sec
test_start_no_longer_than_150_milisecond()
{
    # time of programs for 1 loop
    awk '/inc/ {print $6}' log/out.l1.log | columnInRange 0.001 0.15;
}

# ratio of speed for time based test should be near to 1
test_speed_should_be_not_dependent_from_loops_in_limit()
{
    ratioOfColumns 5 t1 t2 | columnInRange 0.8 1.3;
}

# ratio of speed for 2 and 1 loop should be near to 2
test_ratio_of_speed_for_small_loop_number_in_proper_range()
{
    ratioOfColumns 5 l1 l2 | columnInRange 1.2 2.5;
}

test_ratio_of_speed_for_1_and_2_loops_form_database()
{
    for n in 1 2
    do
        sqlite3 log/log.db "SELECT name, avg(size/time) as speed FROM \
            log WHERE size="$n" AND name!='inc.m.sh' AND name!='inc.wl' GROUP BY name" \
            > log/out.l$n.speed.log
    done

    ratioOfColumns 2 l1.speed l2.speed | columnInRange 1.6 2.4;
}

. shunit2-2.1.6/src/shunit2