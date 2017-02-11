#!/usr/bin/env bash

testEquality() {
	assertEquals 1 1
}

testPartyLikeItIs1999()
{
  year=`date '+%Y'`
  assertEquals "It's not 2017 :-(" \
      '2017' "${year}"
}

. shunit2-2.1.6/src/shunit2