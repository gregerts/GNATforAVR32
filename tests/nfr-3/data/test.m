#! /usr/bin/octave -q

K = 4;
d = receive(1000);
s = size(d);

c = zeros(s(1),1);

for i = 1:s(2)
  c = bitxor(c,d(:,i));
endfor

i = !c;

sd = K * [min(d(i,1)); max(d(i,1)); mean(d(i,1))];

printf("N & %d & %d & %d \\\\\n", sd);

fn = sprintf("%s-%s.dat", date, get_branch);
save(fn, "d", "sd");
