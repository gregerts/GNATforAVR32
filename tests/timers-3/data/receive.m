function [data, t] = receive (n)

  % Initially empty data
  data = [];

  % Restart AVR32
  system("avr32program reset -r 2> /dev/null");

  % Configure USART to 56700 bauds, ignore CR
  system("stty -F /dev/ttyS0 57600 igncr");

  % Open USART file
  usart = fopen("/dev/ttyS0", "r");

  % Sync with device
  while (!strcmp("SYNC",fgetl(usart))); endwhile

  % Start taking time
  tic;

  % Read n samples into data
  for i = 1:n

    if mod(i, n/50) == 1
      printf(".");
    endif

    data = [data; transpose(hex2dec(split(fgetl(usart),":")))];

  endfor

  % Record elapsed time
  t = toc;

  % Close USART file
  fclose(usart);

endfunction
