import serial
import time
import sys

class MWS:
  FORWARD = '+'
  BACKWARD = '-'

  def __init__(self, serial_port):
    self._serial_port = serial.Serial(serial_port, 9600, timeout=10)

  def getSensorsRead(self):
    self._serial_port.write("g\n")
    return self._serial_port.readline().strip()

  def setLeftEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sEL%s%s\n" % ("+", chr(power)))
    elif direction == self.BACKWARD:
      self._serial_port.write("sEL%s%s\n" % ("-", chr(power)))

  def setRightEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sER%s%s\n" % ("-", chr(power)))
    elif direction == self.BACKWARD:
      self._serial_port.write("sER%s%s\n" % ("+", chr(power)))

  def engineRotateRight(self, power):
    m.setLeftEnginePower(power)
    m.setRightEnginePower(power, MWS.BACKWARD)

  def engineRotateLeft(self, power):
    m.setLeftEnginePower(power, MWS.BACKWARD)
    m.setRightEnginePower(power)

  def rotateRight(self, rotate):
    self._serial_port.write("rR%03d\n" % (rotate))
    return self._serial_port.readline()

  def setHeading(self, hdg):
    self._serial_port.write("sH%03d\n" % (hdg))
    return self._serial_port.readline()

  def setEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sEL%s%s\n" % ("+", chr(power)))
      self._serial_port.write("sER%s%s\n" % ("-", chr(power)))
    elif direction == self.BACKWARD:
      self._serial_port.write("sEL%s%s\n" % ("-", chr(power)))
      self._serial_port.write("sER%s%s\n" % ("+", chr(power)))
    return self._serial_port.readline()

if __name__== "__main__":
  m = MWS(sys.argv[1])
  if len(sys.argv)>2:
    cmd = sys.argv[2][1:]
    if cmd == "sr":
      while (1):
        print m.getSensorsRead()
    sys.exit(0)
