#!/usr/bin/env ruby
#

require 'date'
require 'json'

logfile = '/var/log/messages'

macnames = Hash.new

macnames['00:11:24:c5:b9:8a'] = 'Emmanuel Macbook'
macnames['00:22:4c:03:a1:9e'] = 'Emmanuel Wii'
macnames['58:b0:35:77:08:4b'] = 'Manuel Macbook'
macnames['98:0c:82:34:11:eb'] = 'Manuel Inspire'
macnames['40:fc:89:3c:51:35'] = 'Manuel Atrix'
macnames['90:84:0d:82:25:3f'] = 'Tracy iPhone'
macnames['00:23:6c:88:f5:9f'] = 'Tracy Macbook'


totals = Hash.new


# read each line of input file
# only interested in lines containing 'Associated' or 'Disassociated'
relevant_lines = open(logfile).grep(/sociated/)

relevant_lines.each do |line|
  puts line
  # capture the timestamp and mac address
  date_str = line.split(' ')[0..2].join(' ')
  timestamp = DateTime.parse(date_str)
  date = timestamp.strftime(fmt='%D')
  mac = line.split(' ')[9]
  totals[mac] = Hash.new if not totals.has_key?(mac)
  if not totals[mac].has_key?(date)
    totals[mac][date] = Hash.new 
    totals[mac][date]['total_min'] = 0
  end
  
  # if 'Associated', set starttime to timestamp
  if line =~ /Associated/
    if totals[mac][date].has_key?('starttime')
      puts "WARNING: I already have a start time for #{mac} on #{date}"
    else
      totals[mac][date]["starttime"] = timestamp
    end
  # if 'Disassociated, set endtime to timestamp
  elsif line =~ /Disassociated/
    if not totals[mac][date].has_key?('starttime')
      puts "WARNING: I have an endtime but no starttime"
    elsif
      # calculate difference between start and endtime
      # catch errors if no starttime or two endtimes
      delta_days = timestamp - totals[mac][date]['starttime']
      delta_min = (delta_days*24*60).to_i
      # add that to total of that mac on that date
      totals[mac][date]['total_min'] += delta_min
      totals[mac][date].delete('starttime')
    end
  end
end
# print totals
puts totals.to_json
totals.each do |mac, dates|
  puts "#{macnames[mac]}:"
  dates.each_key do |date|
    hours,min = dates[date]['total_min'].divmod(60)
    puts "#{date} #{hours}:#{min}"
  end
  puts ""
end
