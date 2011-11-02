#! /usr/bin/octave -q

d = receive(100);
s = size(d);

c = zeros(s(1),1);

for i = 1:s(2)
  c = bitxor(c,d(:,i));
endfor

i = !c;

dtr = d(i,2) - d(i,1);

sd = [min(dtr) max(dtr) mean(dtr) sqrt(var(dtr))];

printf("N & %d & %d & %1.4f & %1.4f \\\\\n",sd');

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "d", "dtr", "sd");
