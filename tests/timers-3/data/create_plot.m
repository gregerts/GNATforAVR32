C = 32/60;
a = -25;
b = 15;

%f = fopen("raw4.dat", "r");
%while (!strcmp("SYNC",fgetl(f))); endwhile
%[data, n] = fscanf(f, "%x:%x:%x\n", [3 n]);
%fclose(f);
%data = transpose(data);

load -ascii data-tmp.dat
data = data_tmp;

n = size(data, 1);
u = unique(data(:,1));

printf("obs = %d\n", n);
printf("min = %g\n", C * min(u));
printf("max = %g\n", C * max(u));
printf("avg = %g\n", C * mean(data(:,1)));

for i = min(u):max(u)
  o = size(find(data(:,1) == i),1);
  printf("    %d & %#.5g & %10.d & %.5g \\\\\n", i, C*i, o, o/n * 100);
endfor;

offset = mod(data(:,3) + 2^15,2^16) - 2^15;

k = find(a <= offset & offset <= b);

figure(1);

plot(offset(k),data(k,1),'+');

ylim([15 35]);
xlim([a b]);
ylabel("Overhead");
xlabel("Offset");
axis("square");
grid on;

print -deps -mono -Ftimes:14 plot-te-3.eps

