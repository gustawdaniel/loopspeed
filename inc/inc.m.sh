#!/usr/bin/env bash

read -r -d '' VAR << EOM
for c = 1:$1
%  disp(c)
end
EOM

echo "$VAR" | matlab -nodesktop -nosplash 1>/dev/null
