#! /usr/bin/octave -q

C = 32/60e6;

a =    0;
b =  600;
m = 1000;
n =  100;

report = fopen("report.txt", "w");

for i = 1:128

  timers = 2*i;
  
  printf("Test %d: ", i);

  file = fopen("../test_instance.ads", "w");

  fprintf(file, "with Test;\n");
  fprintf(file, "\n");
  fprintf(file, "package Test_Instance is new Test (%d, %d, %d, %d);\n",
	  a, b*i, timers, m);

  fclose(file);

  system("make -C ../         -s --no-print-directory 2> /dev/null");
  system("make -C ../ install -s --no-print-directory 2> /dev/null");

  [data, t] = receive(n);

  set       = sum(data(:,1));
  cancelled = sum(data(:,2));
  expired   = sum(data(:,3));

  d_min  = C * min(data(:,4));
  d_max  = C * max(data(:,5));

  x = C * data(:,6) / m;

  d_mean = mean(x);
  d_var  = var(x);
  d_svar = sqrt(d_var);

  util = data(:,8) ./ (32 * data(:,7));

  u_min = min(util);
  u_max = max(util);
  u_mean = mean(util);

  fprintf(report, "%d %d %d %d ", a, b*i, timers, m);
  fprintf(report, "%d ", set - (cancelled + expired));
  fprintf(report, "%8.4e ", d_min);
  fprintf(report, "%8.4e ", d_max)
  fprintf(report, "%8.4e ", d_mean);
  fprintf(report, "%8.4e ", d_svar);
  fprintf(report, "%8.4e ", u_min);
  fprintf(report, "%8.4e ", u_max)
  fprintf(report, "%8.4e ", u_mean);
  fprintf(report, "%8.4f\n", t);

  fflush(report);

  save(sprintf("test-%d.dat", i),
       "timers", "t",
       "data", "set", "cancelled", "expired",
       "d_min", "d_max", "d_mean" ,"d_svar");

  printf(" Done %f [s]\n", t);

endfor

fclose (report);
