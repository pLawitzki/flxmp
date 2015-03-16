# Introduction #
This Article covers a short introduction of how to use FLXMP to playback an XM file.


# Embed XM File as a Binary Object #
Currently FLXMP only support the XM file type. There is no external file loader, yet (still to come). You need to embed the XM file into your swf file. Let's suppose your song is called _mySong.xm_ and it's located in the same directory as your _Main_ class. This would be the statement to embed the XM file:

```
[Embed(source = "mySong.xm", mimeType = "application/octet-stream")] private var mySong:Class
```

The binary date of _mySong.xm_ will be stored inside the _Class_ object named _mySong_. This object can be passed as a parameter to the constructor of the _Module_ class.

# Instancing Song and Player #
Now, you can simply create a new _flxmp.Module_ and pass _mySong_ as a parameter in the constructor calll. This way you create a module object that can be played by the _flxmp.Player_.

Then create a _flxmp.Player_ whith the _Module_ instance as parameter in the cunstructor call. This loads the module object into the player. It's ready to be played now. The _play()_ method of _flxmp.Player_ starts the playback.

```
import flxmp.*

public class Main extends Sprite 
{
   // embed song
   [Embed(source = "mySong.xm", mimeType = "application/octet-stream")] private var mySong:Class

   private var MyModule:flxmp.Module;
   private var MyPlayer:flxmp.Player;

   // constructor
   Main():void
   {
      MyModule = new flxmp.Module(mySong);
      MyPlayer = new flxmp.Player(MyModule);
      MyPlayer.play();
   }

   // ...

}
```

# Player Function Reference #
_flxmp.Player_ can be controlled by the following public methods:

  * _play():_ starts the module playback.
  * _stop():_ stopps the module playback and resets the playback position.
  * _pause():_ pauses the module playback keeping the playback position.

(further _flxmp.Player_ API methods to come...)