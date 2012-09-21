#!/usr/bin/env python

# a tool to analyze airport logs and show who has been online for how long this
# month
import string
import datetime
from collections import defaultdict


#logfile = "/var/log/messages"
#logfile = "emmanuel.messages"
logfile = "messages"


fo = open(logfile)
#results = defaultdict(list)
results = list()

macnames = dict()

macnames['00:11:24:c5:b9:8a'] = 'Emmanuel Macbook'
macnames['00:22:4c:03:a1:9e'] = 'Emmanuel Wii'
macnames['58:b0:35:77:08:4b'] = 'Manuel Macbook'
macnames['98:0c:82:34:11:eb'] = 'Manuel Inspire'
macnames['40:fc:89:3c:51:35'] = 'Manuel Atrix'
macnames['90:84:0d:82:25:3f'] = 'Tracy iPhone'
macnames['00:23:6c:88:f5:9f'] = 'Tracy Macbook'
macnames['00:15:af:50:9d:21'] = 'Emmanuel Geri'
macnames['ec:55:f9:4d:b7:38'] = 'Yvonne'




# takes a list of words of the following format
# ['Jul', '02', '22:29:30']
def str2date(strmonth, day, time):
    year = 2011
    month_dict = {"Jan":1,"Feb":2,"Mar":3,"Apr":4, "May":5, "Jun":6,"Jul":7,"Aug":8,"Sep":9,"Oct":10,"Nov":11,"Dec":12}
    month = month_dict[strmonth]
    timeElements = string.split(time,':')
    hour = timeElements[0]
    minute = timeElements[1]
    second = timeElements[2]
    date = datetime.datetime(int(year), int(month), int(day), int(hour),
            int(minute), int(second))
    return date

if __name__ == "__main__":

    # example logfile line
    # 'Jul 02 21:21:31\tSeverity:5\tAssociated with station 58:b0:35:77:08:4b\n'
    total = datetime.datetime.min
    timeused = datetime.datetime.min
    dailytotals = defaultdict(dict)
    state = {}

    # filter out the lines concerning association and disassociation of Es
    # computer
    for line in fo:
        #if "sociate" in line and "00:11:24:c5:b9:8a" in line:
        if " Associated with station " in line or " Disassociated with station " in line:
            results.append(line)

    starttime = {}

    for line in results:
        words = string.split(line)
        month = words[0]
        day = words[1]
        time = words[2]
        logtime = str2date(month, day, time)
        macAddr = words[9]
        # if this day has not been initialized, do it
        if macAddr not in dailytotals:
            dailytotals[macAddr] = dict()
        if macAddr not in state:
            state[macAddr] = 'disassociated'
        if macAddr not in starttime:
            starttime[macAddr] = datetime.datetime.min
        if month+day not in dailytotals[macAddr]:
            dailytotals[macAddr][month+day] = datetime.datetime.min
        if "Associated" in line and state[macAddr] != "associated":
            state[macAddr] = "associated"
            starttime[macAddr] = logtime
        elif "Disassociated" in line:
            state[macAddr] = "disassociated"
            if starttime[macAddr] != datetime.datetime.min:
                timeused = logtime - starttime[macAddr]
                # re-initialize starttime[macAddr]
                dailytotals[macAddr][month+day] += timeused
                #print macnames[macAddr], month+day, "start: ", starttime[macAddr], "end: ", logtime, "delta: ",unicode(timeused), "total: ", unicode(dailytotals[macAddr][month+day]), state[macAddr]
                starttime[macAddr] = datetime.datetime.min;
    # if there's a line with associated at end of file (means the station hasn't currently disassociated yet)...
    for macAddr in state:
      if state[macAddr] == "associated":
          timeused = datetime.datetime.now() - starttime[macAddr]
          dailytotals[macAddr][month+day] += timeused

    for mac in dailytotals:
      try:
        print macnames[mac]+":"
      except:
        print mac+":"
      for day in sorted(dailytotals[mac]):
        print day, dailytotals[mac][day]
      print ""
