                                README
                                ======

Author: Kelsey Jordahl
Date: 2011-04-28 12:42:23 EDT


A temperature logger for an [Arduino] with [data logging shield] from
[Adafruit].  Writes temperature data from two different sensors to an SD
card with time stamp.  I am using a National Semiconductor [LM61] analog
sensor (part no. LM61BIZ) and a Vishay [10 kΩ thermistor] (part
no. NTCLE100E3103GB0).

Also includes a Python plotting script which plots both sensors and
fills in bad timestamps with linearly interpolated (or extrapolated) times.

Based on code from [https://github.com/adafruit/Light-and-Temp-logger].

[Arduino]: http://www.arduino.cc/
[data logging shield]: http://www.adafruit.com/index.php?main_page=product_info&products_id=243
[Adafruit]: http://www.adafruit.com
[LM61]: http://www.national.com/mpf/LM/LM61.html
[10 kΩ thermistor]: http://www.vishay.com/thermistors/list/product-29049

