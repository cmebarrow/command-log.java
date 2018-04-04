# Usage:
#   (adjust capacities to match the running system)
#   java -Dreaktor.streams.buffer.capacity=0x2000000 -Dreaktor.throttle.buffer.capacity=0x400000 -jar command-log.jar -d shm > frames.txt
#   sort -k 1 frames.txt > sorted_frames.txt
#   cat sorted_frames.txt | sed "s/\[//g ; s/]//g" | awk -f ~/git/reaktivity/command-log.java/tools/totals.awk >totals.txt
#
# Example output:
# Source Target Streamid	bytes transferred	observed duration of data	bytes/sec	status
# tcp kafka 0x0000000000000460: bytes 12309840	duration/ms 13991.6	bytes/sec 879804	status active
# tcp kafka 0x0000000000000461: bytes 2128770	duration/ms 2842	bytes/sec 749041	status active
# tcp kafka 0x0000000000000462: bytes 94050	duration/ms 716730	bytes/sec 131.221	status active
# tcp kafka 0x0000000000000463: bytes 94116	duration/ms 716429	bytes/sec 131.368	status active
# tcp kafka 0x0000000000000464: bytes 148096	duration/ms 716597	bytes/sec 206.666	status active
# tcp kafka 0x000000000000045f: bytes 10210754	duration/ms 13755.8	bytes/sec 742289	status active

BEGIN {
  SUBSEP=" "
}

/BEGIN/ {
  source = $3
  target = $5
  stream = $6
  status[source,target,stream] = "begun"
}

/END/ {
  source = $3
  target = $5
  stream = $6
  status[source,target,stream] = "ended"
}

/RESET/ {
  source = $3
  target = $5
  stream = $6
  status[source,target,stream] = "reset"
}

/DATA/ {
  source = $3
  target = $5
  stream = $6
  status[source,target,stream] = "active"
  if( first_ts[source,target,stream] == null ) 
  { 
    first_ts[source,target,stream] = $1
  } 
  last_ts[source,target,stream] = $1 
  sums[source,target,stream] += $8
}; 

END {
  print "Source Target Streamid\tbytes transferred\tobserved duration of data\tbytes/sec\tstatus"
  for( sum in sums)
  {
    duration = ( last_ts[sum] - first_ts[sum]) / 1000000 
    if (duration > 0)
    {
      rate = 1000 * (sums[sum] / duration)
    }
    else
    {
      rate = "unknown"
    }
    print sum ": bytes " sums[sum] "\tduration/ms " duration "\tbytes/sec " rate "\tstatus " status[source,target,stream]
  }
} 
