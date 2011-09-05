#! /usr/bin/octave -q

data = receive(1000);

i = bitxor(data(:,1),data(:,2)) == data(:,3);
dt = data(i,2) - data(i,1);
sd = [min(dt); max(dt); mean(dt); sqrt(var(dt))];

printf("N & %d & %d & %1.4f & %1.4f \\\\\n",sd);

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "data", "dt", "sd");
