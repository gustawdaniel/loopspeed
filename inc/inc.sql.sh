#!/usr/bin/env bash

mysql -u root inc -e "CALL inc_loop($1)";