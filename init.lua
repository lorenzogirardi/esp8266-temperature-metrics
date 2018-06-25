local SSID = "$your_wifi"
local SSID_PASSWORD = "$wifi_password"
local DEVICE = "$name_used_on_grafana"
local temperature = 20.0

wifi.setmode(wifi.STATION)
wifi.sta.config(SSID,SSID_PASSWORD)
wifi.sta.autoconnect(1)

local HOST = "$influxdb_ip"
local URI = "/write?db=collectd"

function build_post_request(host, uri, data_table)

     local data = data_table.Data_type .. ",device=" .. data_table.Device .. " " .. "value=" .. data_table.Value

     --for param,value in pairs(data_table) do
    --      data = data .. param.."="..value.."&"
    -- end
    print(data)

     request = "POST "..uri.." HTTP/1.1\r\n"..
     "Host: "..host.."\r\n"..
     "Connection: close\r\n"..
     "Content-Type: application/x-www-form-urlencoded\r\n"..
     "Content-Length: "..string.len(data).."\r\n"..
     "\r\n"..
     data

     print(request)

     return request
end

local function display(sck,response)
     print(response)
end

-- When using send_sms: the "from" number HAS to be your twilio number.
-- If you have a free twilio account the "to" number HAS to be your twilio verified number.
-- The numbers MUST include the country code.
-- DO NOT add the "+" sign.
local function send_data(data_type,device,value)

     local data = {
      Data_type = data_type,
      Device = device,
      Value = value
     }

     socket = net.createConnection(net.TCP,0)
     socket:on("receive",display)
     socket:connect(8086,HOST)

     socket:on("connection",function(sck)

          local post_request = build_post_request(HOST,URI,data)
          sck:send(post_request)
     end)
end

wifiTrys     = 1     -- Counter of trys to connect to wifi
NUMWIFITRYS  = 15    -- Maximum number of WIFI Testings while waiting for connection
 

function check_wifi()
 if ( wifiTrys > NUMWIFITRYS ) then
    node.restart()
 else
 local ip = wifi.sta.getip()
   if(ip==nil) then
     print("Connecting...")
     wifiTrys = wifiTrys + 1
   else
     tmr.stop(0)
     print("Connected to AP!")
     print(ip)
  --send_data("15551234567","12223456789","Hello from your ESP8266")

  local t, h, d = getTempHumi()

  print("Temp:"..t .." C\n")
  print("Humi:"..h .." RH\n")
  print("Dew:"..d .." DP\n")

  send_data("temperature", DEVICE, t)
  send_data("humidity", DEVICE, h)
  send_data("dew_point", DEVICE, d)

  tmr.alarm(0,30000,1,check_wifi)

 end
end
end

tmr.alarm(0,5000,1,check_wifi)

function getTempHumi()
    pin = 4
    local status,temp,humi,temp_decimial,humi_decimial = dht.read(pin)
    if( status == dht.OK ) then
    -- Float firmware using this example
      print("DHT Temperature:"..temp..";".."Humidity:"..humi)
    elseif( status == dht.ERROR_CHECKSUM ) then
      print( "DHT Checksum error." );
    elseif( status == dht.ERROR_TIMEOUT ) then
      print( "DHT Time out." );
    end
    local dewpoint= (humi/100)^(1/8) * (112 + (0.9 * temp)) - 112 + (0.1 * temp)

    return temp, humi, (string.format("%.1f", dewpoint))
end

