#! /usr/bin/octave -q

data = receive(10000);

i = find(bitxor(data(:,1),data(:,2)) == data(:,3));
sd = [min(data(i,1)); max(data(i,1)); mean(data(i,1))];

printf("N & %d & %d & %d \\\\\n", sd);

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "data", "sd");
