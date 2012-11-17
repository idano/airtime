require 'sinatra/base'
require 'pry'
require 'date'

class Airtime < Sinatra::Base

  get "/airtime" do
      stat
  end

  def stat
    logfile = '/var/log/messages'
    result = ""

    macnames = Hash.new

    macnames['00:11:24:c5:b9:8a'] = 'Emmanuel Macbook'
    macnames['00:22:4c:03:a1:9e'] = 'Emmanuel Wii'
    macnames['58:b0:35:77:08:4b'] = 'Manuel Macbook'
    macnames['98:0c:82:34:11:eb'] = 'Manuel Inspire'
    macnames['40:fc:89:3c:51:35'] = 'Manuel Atrix'
    macnames['00:1d:fe:ea:26:58'] = 'Manuel Touchpad'
    macnames['90:84:0d:82:25:3f'] = 'Tracy iPhone'
    macnames['00:23:6c:88:f5:9f'] = 'Tracy Macbook'
    macnames['00:15:af:50:9d:21'] = 'Emmanuel Geri'
    macnames['ec:55:f9:4d:b7:38'] = 'Yvonne'

    totals = Hash.new


    # read each line of input file
    # only interested in lines containing 'Associated' or 'Disassociated'
    relevant_lines = open(logfile).grep(/sociated/)

    relevant_lines.each do |line|
      # capture the timestamp and mac address
      date_str = line.split(' ')[0..2].join(' ')
      timestamp = DateTime.parse(date_str + " PDT")
      date = timestamp.strftime(fmt='%D')
      mac = line.split(' ')[9]
      totals[mac] = Hash.new if not totals.has_key?(mac)
      if not totals[mac].has_key?(date)
        totals[mac][date] = Hash.new
        totals[mac][date]['total_min'] = 0
      end

      # if 'Associated', set starttime to timestamp
      if line =~ /Associated/
        if totals[mac].has_key?('starttime')
          #result << "WARNING: I already have a start time for #{macnames[mac]} on #{date}<br>"
        else
          totals[mac]["starttime"] = timestamp
        end
      # if 'Disassociated, set endtime to timestamp
      elsif line =~ /Disassociated/
        if not totals[mac].has_key?('starttime')
          #result << "WARNING: I have an endtime but no starttime<br>"
        else
          # calculate difference between start and endtime
          # catch errors if no starttime or two endtimes
          delta_days = timestamp - totals[mac]['starttime']
          delta_min = (delta_days*24*60).to_i
          # add that to total of that mac on that date
          totals[mac][date]['total_min'] += delta_min
          totals[mac].delete('starttime')
        end
      end
    end

    # handle cases where the user has not disconnected yet (currently on)
    totals.each do |mac,data|
      if data.has_key? 'starttime'
        today = Date.today.strftime(fmt='%D')
        delta_secs = Time.now - Time.parse(data['starttime'].to_s + " PDT")
        delta_min = (delta_secs/60).to_i
        totals[mac][today]['total_min'] += delta_min
      end
    end

    # print totals
    totals.each do |mac, data|
      # filter out the starttime flags, we only want the actual date totals
      online = "(currently on)" if data.has_key? 'starttime'
      dates = data.reject { |k,v| k == "starttime" }
      who = macnames[mac] || mac
      result << "#{who} #{online}:<br>"
      dates.each_key do |date|
        hours,min = dates[date]['total_min'].divmod(60)
        online = ""
        result << "#{date} #{hours}:#{min} hours<br>"
      end
      result << "<br>"
    end
    return result
  end
end
