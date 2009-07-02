#! /usr/bin/octave -q

C = 60e6;

data = receive(25000);

l = size(data,1);
s = size(data,2);

t = 32 * data(:,1) / C;
d = data(:,2:s) / C;

dt = (t(2:l) - t(1:l-1));
dd = (d(2:l,:) - d(1:l-1,:)) ./ (dt*ones(1,s-1));
ds = sum(dd(:,1:s-2),2);

figure(1);
plot(t(1:l-1),ds,'.');

save "run.dat"

% hold on;
% plot(t(odd), d(odd), '+');

% xlabel("t [s]");
% ylabel("d [us]");

% print -deps "plots/tmu-1-plot.eps";

%figure(2);
%hist(d(normal),32);

%print -deps "plots/tmu-1-hist.eps";
