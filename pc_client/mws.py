import serial
import time
import sys

class MWS:
  FORWARD = '+'
  BACKWARD = '-'

  def __init__(self, serial_port):
    self._serial_port = serial.Serial(serial_port, 9600, timeout=1)

  def getSensorsRead(self):
    self._serial_port.write("g\n")
    return self._serial_port.readline().strip()

  def getHdg(self):
    sensors = self.getSensorsRead().split(" ")
    hdg = int(float(sensors[5][3:]))
    return hdg

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
    hdg = m.getHdg()
    startHdg = self.getHdg()
    destHdg = hdg + rotate
    m.engineRotateRight(100)

    if (hdg + rotate) >= 359:
      while (1):
        hdg = m.getHdg()
        if (hdg>=359) or (hdg <= 10):
          destHdg = destHdg - 360
          break
    while (hdg <= destHdg):
      hdg = m.getHdg()
    m.setEnginePower(0)

  def setEnginePower(self, power, direction = FORWARD):
    if direction == self.FORWARD:
      self._serial_port.write("sEL%s%s\n" % ("+", chr(power)))
      self._serial_port.write("sER%s%s\n" % ("-", chr(power)))
    elif direction == self.BACKWARD:
      self._serial_port.write("sEL%s%s\n" % ("-", chr(power)))
      self._serial_port.write("sER%s%s\n" % ("+", chr(power)))

if __name__== "__main__":
  m = MWS(sys.argv[1])

  ## Rotar derecha
  # m.rotateRight(45)

  ## Avanzar
  # m.setEnginePower(100)

  ## Retroceder
  # m.setEnginePower(100, MWS.BACKWARD)
