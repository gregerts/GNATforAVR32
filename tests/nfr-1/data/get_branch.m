function b = get_branch
  [s, b] = system("git branch | grep '^\\*' | awk '{print $2;}'");
  if s == 0
    b = strtrim(b);
  else
    b = "error";
  endif
endfunction
