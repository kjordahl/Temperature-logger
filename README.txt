                                README
                                ======

Author: Kelsey Jordahl
Date: 2011-06-01 19:13:44 EDT


A temperature logger for an [Arduino] with [data logging shield] from
[Adafruit].  Writes temperature data from several different sensors to an SD
card with time stamp.  I am using a National Semiconductor [LM61] analog
sensor (part no. LM61BIZ), Vishay [10 kΩ thermistors] (part
no. NTCLE100E3103GB0), and up to 5 digital [1-wire sensors] (either
[DS18B20] or [DS18S20]).

By default, the LM61 uses analog pin 1, two 10 kΩ thermistors use
analog pins 2 and 3, and the 1-wire bus uses digital pin 7, but these
are all changeable.  The sketch will detect the number and type of
DS18x20 sensors on the 1-wire bus, and whether each is using parasitic
power.  It gracefully handles plugging/unplugging of sensors, but will
not detect new sensors after initialization.

Also includes a Python plotting script which plots both sensors and
fills in bad timestamps with linearly interpolated (or extrapolated) times.

Based on code from [https://github.com/adafruit/Light-and-Temp-logger].

[Arduino]: http://www.arduino.cc/
[data logging shield]: http://www.adafruit.com/index.php?main_page=product_info&products_id=243
[Adafruit]: http://www.adafruit.com
[LM61]: http://www.national.com/mpf/LM/LM61.html
[10 kΩ thermistors]: http://www.vishay.com/thermistors/list/product-29049
[1-wire sensors]: http://www.arduino.cc/playground/Learning/OneWire
[DS18B20]: http://www.maxim-ic.com/datasheet/index.mvp/id/2812
[DS18S20]: http://www.maxim-ic.com/datasheet/index.mvp/id/2815

