#! /usr/bin/env python

import sys
from datetime import datetime

d = sys.argv[1]
t = sys.argv[2]
dt = datetime.strptime(d+t, '%d%b%y%H:%M:%S:%f')
print(dt.strftime('%Y%m%d_%H%M'))
