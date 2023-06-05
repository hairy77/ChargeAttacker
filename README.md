# ChargeAttacker
ChargeAttacker - Script for DCS World using MOOSE.  Sets units to charge attacking helicoptert (and ground vehicles) as well as option to call in reinforcements.

I know MOOSE has a suppress fire option. This class is more of the opposite. Groups get aggrivated and will attack the attacker (ground units and/or helicopters) depending on the parameters set. Random option for them to flank (left and right) or go direct. There's also an option for them to call in reinforcements to also attack, which livens up the gameplay and ensures that groups like tanks don't just sit out of range of the helo's, disperse a few meters, and take what's coming and other groups can 'sneak up' on attackers if they're tunnel focused.

I originally wrote this as a straight function but have re-written it today as a class to fall more inline with how MOOSE works. I'm not saavy with lua - so I'm sure that this falls way short of the level of MOOSE CORE function standards, but I submit it here incase anyone else finds it handy or if the MOOSE team decide it's a worthy feature to consider for future development.

The only thing that is broken is the returnhome function. I can't use it at the moment - it's as though the units cheat and go "We're already at our destination - we'll just stop before we start", so that's currently disabled. If anyone has any idea what might be the issue - please sing out.

I'm also very happy for any critisism (it's the best way to learn :) ) if anyone has any too.
