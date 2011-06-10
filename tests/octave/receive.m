function d = receive (n)

  % Restart AVR32
  system("avr32program reset -r 2> /dev/null");

  % Configure USART to 115200 bauds, ignore CR
  system("stty -F /dev/ttyUSB0 115200 igncr");

  % Open USART file
  usart = fopen("/dev/ttyUSB0", "r");

  % Sync with device
  while (!strcmp("SYNC",fgetl(usart))); endwhile

  % Get number of rows and create data matrix
  m = hex2dec(fgetl(usart));
  p = sprintf("^([0-9A-F]+:){%d}[0-9A-F]+$", m - 1);
  d = zeros(n, m);
  i = 0;

  % Read n samples into data
  while (i < n)

    line = fgetl(usart);
    
    if (regexp(line, p))
      d(++i,:) = cellfun(@hex2dec, strsplit(line, ":"));
    elseif (regexp(line, "^Error:"))
      error(line);
    else
      printf("Ignore: %s\n", line);
    endif

  endwhile

  % Close USART file
  fclose(usart);

endfunction
