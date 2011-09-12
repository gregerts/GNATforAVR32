#! /usr/bin/octave -q

data = receive(1000);

i = bitxor(bitxor(data(:,1),data(:,2)),data(:,3)) == data(:,4);
dt = data(i,3) - data(i,2);
sd = [min(dt); max(dt); mean(dt); sqrt(var(dt))];

printf("N & %d & %d & %1.4f & %1.4f \\\\\n",sd);

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "data", "dt", "sd");
