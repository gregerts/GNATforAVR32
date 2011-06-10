#! /usr/bin/octave -q

C = 60e6;

data = receive(10000);

[l s] = size(data);

t = data(:,1) / C;
d = data(:,2:s) / C;

dt = diff(t);
dd = diff(d) ./ (dt*ones(1,s-1));

%figure(1);
%plot(t(1:l-1),ds,'.');

sd = [max(dd); min(dd); mean(dd); sqrt(var(dd))];
printf("N & %1.4f & %1.4f & %1.4f & %1.4f \\\\\n",sd);

save "run.dat"

% hold on;
% plot(t(odd), d(odd), '+');

% xlabel("t [s]");
% ylabel("d [us]");

% print -deps "plots/tmu-1-plot.eps";

%figure(2);
%hist(d(normal),32);

%print -deps "plots/tmu-1-hist.eps";
