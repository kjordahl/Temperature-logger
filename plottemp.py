#!/usr/bin/env python
# -*- coding: iso-8859-15 -*-
"""
Plot data from temperature logger for Arduino with Adafruit data logging shield
 https://github.com/kjordahl/Temperature-logger

Format is assumed to be CSV, containing:
 millis,stamp,datetime,lm61temp,therm1,therm2,temp1,temp2,temp3,vcc
with 6 header lines.  Columns 4, 5 and 6 will be plotted on a time axis.

Usage: plottemp.py logfile.csv [plot.png]

Requires numpy and matplotlib

Author: Kelsey Jordahl
Copyright: Kelsey Jordahl 2011
License: GPLv3
Time-stamp: <Tue Jul  5 21:13:57 CDT 2011>

    This program is free software: you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.  A copy of the GPL
    version 3 license can be found in the file COPYING or at
    <http://www.gnu.org/licenses/>.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

"""

import sys, os
import numpy as np
from matplotlib import dates, pyplot
from scipy.interpolate import UnivariateSpline
from IPython.Shell import IPShellEmbed

MAXSEC = 1000 # maximum allowable offset in seconds between Arduino time and RTC time over a single file
MAXTEMP = 50  # temperatures greater than this are not valid

def c2f(tempC):
    """Celcius to Fahrenheit degrees conversion"""
    return tempC * 9/5 + 32

def main():
    ipshell = IPShellEmbed()
    if len(sys.argv) < 2:
        logfilename = 'log.csv'         # use default filename
	print 'No input filename specified: using %s' % logfilename
    else:
        logfilename = sys.argv[1]
    if not os.path.exists(logfilename):
        print '%s does not exist!' % logfilename
        sys.exit()
    else:
        print 'Reading file %s' % logfilename
    if len(sys.argv) < 3:
        pngfilename = None
	print 'No output filename specified: will not write output file for plot'
    else:
        pngfilename = sys.argv[2]
        print 'Plot will be saved as %s' % pngfilename
    data = np.genfromtxt(logfilename, delimiter=',', skip_header=6, usecols = (0, 1, 3, 4, 5, 6, 7, 8, 9))
    t = data[:,0]
    stamp = data[:,1]
    lm61temp = data[:,2]
    #therm1 = data[:,3]
    therm1 = np.ma.masked_where(np.isnan(data[:,3]), data[:,3])
    therm2 = data[:,4]
    temp0 = data[:,5]
    #temp1 = data[:,6]
    # use masked array rather than nan for bad values
    data[np.where(data[:,6] > MAXTEMP),6] = np.nan
    data[np.where(data[:,7] > MAXTEMP),7] = np.nan
    data[np.where(data[:,8] > MAXTEMP),8] = np.nan
    temp1 = np.ma.masked_where(np.isnan(data[:,6]), data[:,6])
    temp2 = np.ma.masked_where(np.isnan(data[:,7]), data[:,7])
    temp3 = np.ma.masked_where(np.isnan(data[:,8]), data[:,8])

    offset = stamp[1] - t[1] / 1000
    print offset
    maxstamp = t[len(t)-1] / 1000 + offset + MAXSEC
    print maxstamp
    stamp[stamp<offset] = np.nan
    stamp[stamp>maxstamp] = np.nan
    stamp[abs(stamp-t/1000-offset) > MAXSEC] = np.nan
    nancount = np.sum(np.isnan(stamp))
    print '%d bad time stamps to interpolate' % nancount
    # extrapolate - see
    # http://stackoverflow.com/questions/1599754/is-there-easy-way-in-python-to-extrapolate-data-points-to-the-future
    extrapolator = UnivariateSpline(t[np.isfinite(stamp)],stamp[np.isfinite(stamp)], k=1 )
    utime = extrapolator(t)

    # plot 6 columns
    pyplot.plot(dates.epoch2num(utime),lm61temp,'.',dates.epoch2num(utime),therm1,'.',dates.epoch2num(utime),therm2,'.',dates.epoch2num(utime),temp1,'.',dates.epoch2num(utime),temp2,'.',dates.epoch2num(utime),temp3,'.')
    ax = pyplot.gca()
    ax.legend(('LM61','Thermistor 1','Thermistor 2','digital 1','digital 2','digital 3'),loc=0)
    ax.set_xlabel('Time')
    ax.set_ylabel(u'Temp (°C)')
    ax2 = ax.twinx()
    clim = pyplot.get(ax,'ylim')
    ax2.set_ylim(c2f(clim[0]),c2f(clim[1]))
    ax2.set_ylabel(u'Temp (°F)')
    xlocator = dates.AutoDateLocator()
    xformatter = dates.AutoDateFormatter(xlocator)
    pyplot.gca().xaxis.set_major_locator(xlocator)
    pyplot.gca().xaxis.set_major_formatter(dates.DateFormatter('%H:%M'))
    # generate a PNG file
    if pngfilename:
        pyplot.savefig(pngfilename)
    # show the plot
    pyplot.show()
    # open interactive shell
    ipshell()

if __name__ == '__main__':
    main()
