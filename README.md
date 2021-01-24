

In the home automation era, I was quite curious to understand how is
working a simple thermal sensor

WHAT WE NEED ? 

-   ESP8266
-   DHT22
-   usb power
-   Influxdb
-   Grafana

I tried this simple experiment following the suggestion of one of my
colleagues, i was thinking to start with Arduino , however he suggested
to try nodemcu

So what is *nodemcu?\
*It’s an open source platform developed for IoT , you can *compile* the
firmware with the most used sensors available , but the main feature is
the Lua support\
When i starts with Arduino i created some C software really horrible 😇\
with Lua instead it was quite simple create this kind of functionality.

The hardware platform is really nice and simple

ESP8266 

![Image for
post](./Ambient%20sensor%20for%20mere%20mortal.%20In%20the%20home%20automation%20era,%20I%20was%20quite…%20_%20by%20Lorenzo%20_%20Jan,%202021%20_%20Medium_files/0_rCmhhym0qF3LkzXC.png)

![Image for
post](./Ambient%20sensor%20for%20mere%20mortal.%20In%20the%20home%20automation%20era,%20I%20was%20quite…%20_%20by%20Lorenzo%20_%20Jan,%202021%20_%20Medium_files/0_rCmhhym0qF3LkzXC(1).png)

![Image for
post](https://miro.medium.com/max/1840/0*rCmhhym0qF3LkzXC.png)

It’s natively support wifi and with the sensor dht22 you are able to
have the temperature, humidity … and well also a dew point since is it a
maths of previous values

DHT22 {#44e1 .jp .ib .fp .av .ic .jq .jr .js .if .jt .ju .jv .ii .jw .jx .jy .im .jz .ka .kb .iq .kc .kd .ke .iu .kf .ee data-selectable-paragraph=""}
-----

![Image for
post](./Ambient%20sensor%20for%20mere%20mortal.%20In%20the%20home%20automation%20era,%20I%20was%20quite…%20_%20by%20Lorenzo%20_%20Jan,%202021%20_%20Medium_files/0_7HKWj95tf8hReMRa.png)

![Image for
post](./Ambient%20sensor%20for%20mere%20mortal.%20In%20the%20home%20automation%20era,%20I%20was%20quite…%20_%20by%20Lorenzo%20_%20Jan,%202021%20_%20Medium_files/0_7HKWj95tf8hReMRa(1).png)

![Image for
post](https://miro.medium.com/max/1556/0*7HKWj95tf8hReMRa.png)

Price for both is really cheaper (aliexpress)

esp8266 → 3\$\
dht22 → 1\$

Once you receive the hardware you can start to work on it

With [https://nodemcu-build.com/](https://nodemcu-build.com/) you can
build the firmware that fit your needs (in the next screen what is
needed to interact with the thermal sensor)


![Image for
post](https://miro.medium.com/max/2800/0*ol2Ep9zKJDfQYjnY.png)

To load the firmware you should need
[https://github.com/espressif/esptool](https://github.com/espressif/esptool)

with a command like this\
`python esptool.py -b 115200 --port=/dev/cu.wchusbserial1410 write_flash -fm=dio -fs=32m 0x0000 nodemcu-master-12-modules-2016-01-09-18-51-26-float.bin`{.kw
.lh .li .lj .lk .b}

Now…. it’s time to create the Lua script

Configuration

This is working since 2016 so i think we can consider stable 😁

``` {.kh .ki .kj .kk .kl .ll .lm .ln}
local SSID = "name wifi"local SSID_PASSWORD = "password wifi"local DEVICE = "name device"local temperature = 20.0wifi.setmode(wifi.STATION)wifi.sta.config(SSID,SSID_PASSWORD)wifi.sta.autoconnect(1)local HOST = "server database"local URI = "/write?db=collectd"function build_post_request(host, uri, data_table)     local data = data_table.Data_type .. ",device=" .. data_table.Device .. " " .. "value=" .. data_table.Value     --for param,value in pairs(data_table) do    --      data = data .. param.."="..value.."&"    -- end    print(data)     request = "POST "..uri.." HTTP/1.1\r\n"..     "Host: "..host.."\r\n"..     "Connection: close\r\n"..     "Content-Type: application/x-www-form-urlencoded\r\n"..     "Content-Length: "..string.len(data).."\r\n"..     "\r\n"..     data     print(request)     return requestendlocal function display(sck,response)     print(response)end-- When using send_sms: the "from" number HAS to be your twilio number.-- If you have a free twilio account the "to" number HAS to be your twilio verified number.-- The numbers MUST include the country code.-- DO NOT add the "+" sign.local function send_data(data_type,device,value)     local data = {      Data_type = data_type,      Device = device,      Value = value     }     socket = net.createConnection(net.TCP,0)     socket:on("receive",display)     socket:connect(8086,HOST)     socket:on("connection",function(sck)          local post_request = build_post_request(HOST,URI,data)          sck:send(post_request)     end)endfunction check_wifi() local ip = wifi.sta.getip() if(ip==nil) then   print("Connecting...") else  tmr.stop(0)  print("Connected to AP!")  print(ip)  --send_data("15551234567","12223456789","Hello from your ESP8266")  local t, h, d = getTempHumi()  print("Temp:"..t .." C\n")  print("Humi:"..h .." RH\n")  print("Dew:"..d .." DP\n")  send_data("temperature", DEVICE, t)  send_data("humidity", DEVICE, h)  send_data("dew_point", DEVICE, d)  tmr.alarm(0,30000,1,check_wifi) endendtmr.alarm(0,5000,1,check_wifi)function getTempHumi()    pin = 4    local status,temp,humi,temp_decimial,humi_decimial = dht.read(pin)    if( status == dht.OK ) then    -- Float firmware using this example      print("DHT Temperature:"..temp..";".."Humidity:"..humi)    elseif( status == dht.ERROR_CHECKSUM ) then      print( "DHT Checksum error." );    elseif( status == dht.ERROR_TIMEOUT ) then      print( "DHT Time out." );    end    local dewpoint= (humi/100)^(1/8) * (112 + (0.9 * temp)) - 112 + (0.1 * temp)    return temp, humi, (string.format("%.1f", dewpoint))end
```

Customizations 

local SSID = “wifi name” \
local SSID\_PASSWORD = “wifi password”\
local DEVICE = “name device” → name of you board/room

local HOST = “server database” → your influxdb installation\
local URI = “/write?db=collectd” → your database name

So we have the hardware , we loaded the firmware, we created the code,
but how to interact with the platform… well there are many way however
[ESPlorer](https://esp8266.ru/esplorer/) has a nice gui even if it’s
java based ☠️

![Image for
post](https://miro.medium.com/max/2636/0*_U8hAQPTGsW7oDoZ.png)

Results 

[https://services.k8s.it/grafana/d/000000079/temperature?viewPanel=5&orgId=2&refresh=1m](https://services.k8s.it/grafana/d/000000079/temperature?viewPanel=5&orgId=2&refresh=1m)

above you can see the live results …. and on grafana we can create a
graph like this


![Image for
post](https://miro.medium.com/max/5200/0*7ev7X-7MsTqz_e6E.png)

The delta delta in the *Humidity is generated by an*humidifier


![Image for
post](https://miro.medium.com/max/2144/0*jEpReEAfXOHzRNJO.png)

I have one sensor for all rooms … and also external

The external one should be replaced more or less every year because is
not properly water proof and … day by day the electrical contacts become
oxidized
