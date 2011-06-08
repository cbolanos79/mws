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
      self._serial_port.write("sEL%s%s\n" % ("+", power))
    elif direction == self.BACKWARD:
      self._serial_port.write("sEL%s%s\n" % ("-", power))
    self._serial_port.read()

  def setRightEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sER%s%s\n" % ("-", power))
    elif direction == self.BACKWARD:
      self._serial_port.write("sER%s%s\n" % ("+", power))
    self._serial_port.read()

  def engineRotateRight(self, power):
    m.setLeftEnginePower(power)
    m.setRightEnginePower(power, MWS.BACKWARD)

  def engineRotateLeft(self, power):
    m.setLeftEnginePower(power, MWS.BACKWARD)
    m.setRightEnginePower(power)

  def rotateRight(self, rotate):
    self._serial_port.write("rR%03d\n" % (rotate))
    return self._serial_port.readline()

  def rotateLeft(self, rotate):
    self._serial_port.write("rL%03d\n" % (rotate))
    return self._serial_port.readline()

  def setHeading(self, hdg):
    h = int(float(self.getSensorsRead().split(" ")[5][3:]))
    if ((h + hdg)>360) or (hdg>h):
      print "rotateRight"
    elif ((h - hdg)<0) or (hdg<h):
      print "rotateLeft"
    print h, hdg
    return

    self._serial_port.write("sH%03d\n" % (hdg))
    return self._serial_port.readline()

  def setEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sEL%s%s\n" % ("+", power))
      self._serial_port.write("sER%s%s\n" % ("-", power))
    elif direction == self.BACKWARD:
      self._serial_port.write("sEL%s%s\n" % ("-", power))
      self._serial_port.write("sER%s%s\n" % ("+", power))
    return self._serial_port.readline()

if __name__== "__main__":
  m = MWS(sys.argv[1])
  if len(sys.argv)>2:
    cmd = sys.argv[2][1:]
    if cmd == "gs":
      while (1):
        print m.getSensorsRead()
    elif cmd == "sh":
      m.setHeading(int(sys.argv[3]))
    elif cmd == "rr":
      m .rotateRight(int(sys.argv[3]))
    elif cmd == "rl":
      print m .rotateLeft(int(sys.argv[3]))
    sys.exit(0)
