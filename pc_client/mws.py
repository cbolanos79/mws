import serial
import time
import sys

class MWS:
  FORWARD = '+'
  BACKWARD = '-'

  def __init__(self, serial_port):
    self._serial_port = serial.Serial(serial_port)

  def getSensorsRead(self):
    self._serial_port.write("g\n")
    return self._serial_port.readline().strip()

  def setEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sEL%s%s\n" % ("+", chr(power)))
      self._serial_port.write("sER%s%s\n" % ("-", chr(power)))
    elif direction == self.BACKWARD:
      self._serial_port.write("sEL%s%s\n" % ("-", chr(power)))
      self._serial_port.write("sER%s%s\n" % ("+", chr(power)))

if __name__== "__main__":
  m = MWS(sys.argv[1])
  print m.getSensorsRead()
