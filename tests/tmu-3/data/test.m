#! /usr/bin/octave -q

a =     0;
b = 10000;
n =   100;
m =  1000;

printf("Test: ");

file = fopen("../test_instance.ads", "w");

fprintf(file, "with Test;\n");
fprintf(file, "\n");
fprintf(file, "package Test_Instance is new Test (%d, %d, %d);\n",
	a, b, m);

fclose(file);

system("make -C ../         -s --no-print-directory 2> /dev/null");
system("make -C ../ install -s --no-print-directory 2> /dev/null");

[data, t] = receive(n);

set       = sum(data(:,1));
cancelled = sum(data(:,2));
expired   = sum(data(:,3));

d_min  = min(data(:,4));
d_max  = max(data(:,5));
d_mean = mean(data(:,6)) / m;
d_var  = sum(data(:,7)) / (n - 1) - n / (n - 1) * d_mean^2;
d_svar = sqrt(d_var);

report = fopen("report.txt", "w");

fprintf(report, "Test (%d, %d, %d)\n", a, b, m);
fprintf(report, "\n");  
fprintf(report, "\tTime:      %8.4f [s]\n", t);
fprintf(report, "\n");  
fprintf(report, "\tSet:       %d\n", set);
fprintf(report, "\tCancelled: %d\n", cancelled)
fprintf(report, "\tExpired:   %d\n", expired);
fprintf(report, "\tLost:      %d\n", set - cancelled - expired);
fprintf(report, "\n");
fprintf(report, "\tD_Min:     %d\n",    d_min);
fprintf(report, "\tD_Max:     %d\n",    d_max)
fprintf(report, "\tD_Mean:    %8.4e\n", d_mean);
fprintf(report, "\tD_SVar:    %8.4e\n", d_svar);
fprintf(report, "\n");

fclose (report);

save test.dat

printf(" Done %f [s]\n", t);
