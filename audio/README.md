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
