#!/usr/bin/env bash

mariadb inc -e "CALL inc_loop($1)";