#! /usr/bin/octave -q

C = 60e6;

data = receive(500);

t = 32 * data(:,1) / C;
d = (t - sum(data(:,2:11),2) / C) * 1e6;

top = min(d) + 32/12;

odd    = find(d > top);
normal = find(d <= top);

figure(1);
plot(t,d,'.');

# hold on;
# plot(t(odd), d(odd), '+');

# xlabel("t [s]");
# ylabel("d [us]");

# print -deps "plots/tmu-1-plot.eps";

%figure(2);
%hist(d(normal),32);

%print -deps "plots/tmu-1-hist.eps";
