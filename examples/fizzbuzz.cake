set 1 >> i
loop 15
  set 0 >> rem3
  set 0 >> rem5
  mod i 3 >> rem3
  mod i 5 >> rem5
  if rem3 == 0
    log "Fizz"
  elif rem5 == 0
    log "Buzz"
  else
    log "{i}"
  end
  add i 1 >> i
end
