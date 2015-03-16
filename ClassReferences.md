# Class Overview #

FLXMP consist of five classes, from which one contains all functionality for playback, one contains the loading of the XM binary content and the other three are used as data structures. The reason for this class structure (which might appear very ugly at the first sight) is simply performance. The player class processes 44100 samples per second multiplied by the number of channels used in the XM! Which may be quite a lot for an Actionscript application (depending on the number of channels). Since the greatest overhead is caused by function call overhead, the classes ended up in a very centralized and flat structure.

  * **Module:** This class parses the binary information from the XM file and stores it in the three predefined datastructures _Channel_, _Instrument_ and _Wave_. It is also partially used as data structure for song specific information e.g. patterns, tempo, speed etc.

  * **Player:** This is where the magic happens. The player processes the song patterns channel-wise, applies the effects and takes instrument settings in account. If something is wrong with the XM playback it's most likely to be found in this (honestly speaking) somewhat abstruse part of code.

  * **Channel:** contains the current state of a channel during playback

  * **Instument:** contains all instrument information including wave samples, envelopes etc.

  * **Wave:** contains all samples of a sound wave and additional inforamtion e.g. loop markers, wave volume, loop type etc.

# Class Details #
## Module ##
tbd
## Player ##
tbd
## Channel ##
tbd
## Instrument ##
tbd
## Wave ##
tbd