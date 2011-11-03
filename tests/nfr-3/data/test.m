#! /usr/bin/octave -q

offset = getoffset("../main", "test__r")
data = hexload("nfr-3.hex", offset, [1 100], false);

sd = [min(data(1,:)); max(data(1,:)); mean(data(1,:))];

printf("N & %d & %d & %d \\\\\n", sd);

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "data", "sd");
