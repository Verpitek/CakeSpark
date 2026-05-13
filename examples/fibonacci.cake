set 0 >> a
set 1 >> b
set 0 >> i
log "{a}"
while i < 8
  set a >> tmp
  set b >> a
  add tmp b >> b
  add i 1 >> i
  log "{b}"
end
