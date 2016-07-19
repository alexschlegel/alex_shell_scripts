from ouimeaux.environment import Environment
from ouimeaux.signals import statechange, receiver

env = Environment()
env.start()

print 'discovering'
env.discover(5)

switchLight = env.get_switch("Living Room Light")
switchWall = env.get_switch("Living Room Wall")

@receiver(statechange, sender=switchLight)
def switch_toggle(sender, **kwargs):
    print 'triggered!'
    switchWall.basicevent.SetBinaryState(BinaryState=kwargs['state'])

print 'waiting'
env.wait()
