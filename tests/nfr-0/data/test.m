#! /usr/bin/octave -q

data = receive(100000);
dt = data(:,2) - data(:,1);

sd = [min(dt); max(dt); mean(dt); sqrt(var(dt))];
printf("N & %d & %d & %1.4f & %1.4f \\\\\n",sd);
