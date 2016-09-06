from ouimeaux.environment import Environment
from ouimeaux.signals import statechange, receiver
from ouimeaux.device.switch import Switch
from ouimeaux.device.lightswitch import LightSwitch

env = Environment()
env.start()

#chiron isn't detecting the switches, so do it manually
env._process_device(LightSwitch('http://192.168.0.110:49153/setup.xml'))
env._process_device(Switch('http://192.168.0.111:49153/setup.xml'))
#print 'discovering'
#env.discover(5)

switchLight = env.get_switch("Living Room Light")
switchWall = env.get_switch("Living Room Wall")

@receiver(statechange, sender=switchLight)
def switch_toggle(sender, **kwargs):
    print 'triggered!'
    switchWall.basicevent.SetBinaryState(BinaryState=kwargs['state'])

print 'waiting'
env.wait()
