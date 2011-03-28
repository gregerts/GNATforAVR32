function data = receive (n)

  % Initially empty data
  data = [];

  % Restart AVR32
  system("avr32program reset -r 2> /dev/null");

  % Configure USART to 56700 bauds, ignore CR
  system("stty -F /dev/ttyUSB0 115200 igncr");

  % Open USART file
  usart = fopen("/dev/ttyUSB0", "r");

  % Sync with device
  while (!strcmp("SYNC",fgetl(usart))); endwhile

  % Read n samples into data
  try
    for i = 1:n
      data = [data; transpose(hex2dec(split(fgetl(usart),":")))];
    endfor
  end_try_catch

  % Close USART file
  fclose(usart);

endfunction
