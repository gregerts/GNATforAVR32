#! /usr/bin/octave -q

C = 32/60e6;

a = 250;
b = 750;
m = 100;
n = 100000;

report = fopen("report.txt", "w");
  
printf("Test: ");

file = fopen("../test_instance.ads", "w");

fprintf(file, "with Test;\n");
fprintf(file, "\n");
fprintf(file, "package Test_Instance is new Test (%d, %d, %d);\n", a, b, m);

fclose(file);

system("make -C ../         -s --no-print-directory 2> /dev/null");
system("make -C ../ install -s --no-print-directory 2> /dev/null");

[data, t] = receive(n);

o = C * data(:,1);
x = C * data(:,2);

o_min  = min(o);
o_max  = max(o);
o_mean = mean(o);
o_var  = var(o);
o_svar = sqrt(o_var);

fprintf(report, "%d %d %d ", a, b, m);
fprintf(report, "%8.4e ", o_min);
fprintf(report, "%8.4e ", o_max)
fprintf(report, "%8.4e ", o_mean);
fprintf(report, "%8.4e ", o_svar);
fprintf(report, "%8.4f\n", t);

fflush(report);

save("test.dat", "data", "o", "x", "t");

printf(" Done %f [s]\n", t);

fclose (report);
