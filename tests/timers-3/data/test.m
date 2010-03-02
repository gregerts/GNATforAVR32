#! /usr/bin/octave -q

C = 32/60e6;

a =    0;
b =  600;
m = 1000;
n =  100;

report = fopen("report.txt", "w");

range = 1:128;
select = [1 2 4 8 16 32 64 128];

r = zeros(max(range), 7);

for i = range

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

  r(i,1) = timers;
  r(i,2) = 1e6*d_min;
  r(i,3) = 1e6*d_max;
  r(i,4) = 1e6*d_mean;
  r(i,5) = u_min;
  r(i,6) = u_max;
  r(i,7) = u_mean;

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
       "d_min", "d_max", "d_mean" ,"d_svar",
       "util", "u_min", "u_max", "u_mean");

  printf(" Done %f [s]\n", t);

endfor

fclose (report);

%% Create tabel to use in report

tabel = fopen("tabel.txt", "w");

for i = select
  fprintf(tabel, "    %d &\n    %g & %g & %g &\n    %g & %g & %g \\\\\n\n", r(i,:));
endfor;

fclose(tabel);

% Create figures to use in report

figure(1);
plot(r(:,1),r(:,2:4));
xlim([0 max(r(:,1))]);
xlabel("T");
ylabel("Overhead [us]");
print -deps -solid -FTimes:14 plot-te-1.eps
print -deps -solid -mono -FTimes:14 plot-te-1-mono.eps

figure(2);
plot(r(:,1),r(:,5:7));
xlim([0 max(r(:,1))]);
xlabel("T");
ylabel("Utilization");
print -deps -solid -FTimes:14 plot-te-2.eps
print -deps -solid -mono -FTimes:14 plot-te-2-mono.eps

system("epstopdf plot-te-1.eps");
system("epstopdf plot-te-1-mono.eps");
system("epstopdf plot-te-2.eps");
system("epstopdf plot-te-2-mono.eps");
