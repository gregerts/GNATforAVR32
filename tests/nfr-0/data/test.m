#! /usr/bin/octave -q

data = receive(1000);

i = bitxor(data(:,1),data(:,2)) == data(:,3);
dt = data(i,2) - data(i,1);

mm = mean(dt);
iu = find(dt <= mm);
io = find(dt > mm);

sd = [min(dt(iu)); max(dt(iu)); mean(dt(iu)); sqrt(var(dt(iu)));
      min(dt(io)); max(dt(io)); mean(dt(io)); sqrt(var(dt(io)))];

printf("N & %d & %d & %1.4f & %1.4f \\\\\n",sd);

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "data", "dt", "sd");
