# I2S Microphone Module Install
Compiling: 

```bash
cd audio

sudo make
sudo make install

sudo ln -s $(pwd)/i2s-driver.ko /lib/modules/`uname -r`

sudo depmod -a
sudo ldconfig

sudo modprobe i2s-driver
```

# Terminology
capture:
Receiving data from the outside world (different from "recording" which implies storing that data somewhere, and is not part of ALSA's API)

playback:
Delivering data to the outside world, presumably, though not necessarily, so that it can be heard.

xrun:
Once the audio interface starts running, it continues to do until told to stop. It will be generating data for computer to use and/or sending data from the computer to the outside world. For various reasons, your program may not keep up with it. For playback, this can lead to a situation where the interface needs new data from the computer, but it isn't there, forcing it use old data left in the hardware buffer. This is called an "underrun". For capture, the interface may have data to deliver to the computer, but nowhere to store it, so it has to overwrite part of the hardware buffer that contains data the computer has not received. This is called an "overrun". For simplicity, we use the generic term "xrun" to refer to either of these conditions

PCM:
Pulse Code Modulation. This phrase (and acronym) describes one method of representing an analog signal in digital form. Its the method used by almost computer audio interfaces, and it is used in the ALSA API as a shorthand for "audio".

Sample:
A sample is a single value that describes the amplitude of the audio signal at a single point in time, on a single channel.

channel:

frame:
When we talk about working with digital audio, we often want to talk about the data that represents all channels at a single point in time. This is a collection of samples, one per channel, and is generally called a "frame". When we talk about the passage of time in terms of frames, its roughly equivalent to what people when they measure in terms of samples, but is more accurate; more importantly, when we're talking about the amount of data needed to represent all the channels at a point in time, its the only unit that makes sense. Almost every ALSA Audio API function uses frames as its unit of measurement for data quantities.

interleaved:
a data layout arrangement where the samples of each channel that will be played at the same time follow each other sequentially. See "non-interleaved"

non-interleaved:
a data layout where the samples for a single channel follow each other sequentially; samples for another channel are either in another buffer or another part of this buffer. Contrast with "interleaved"
