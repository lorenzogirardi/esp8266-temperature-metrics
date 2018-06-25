# esp8266-temperature-metrics

tools:
 - ESPlorer
 - esptool

bootstrap:
 - python esptool.py -b 115200 --port=/dev/cu.wchusbserial1410 write_flash  -fm=dio -fs=32m 0x0000 nodemcu-master-8-modules-2017-11-04-12-37-02-float.bin
