#! /usr/bin/octave -q

n = 100000;
C = 1/60;

data = receive(n);

i = find(bitxor(data(:,1),data(:,2)) == data(:,3));
o = C * data(i,1);
x = C * data(i,2);

hist(x,100);

o_min  = min(o);
o_max  = max(o);
o_mean = mean(o);

printf("Min  & %8.4e \\\\\n", o_min);
printf("Max  & %8.4e \\\\\n", o_max)
printf("Mean & %8.4e \\\\\n", o_mean);

save("test.dat", "data", "o", "x");
