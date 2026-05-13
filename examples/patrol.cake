set 0 >> counter

block patrol
  log "patrol step {counter}"
  add counter 1 >> counter
end

loop 3
  run patrol
end
