/*
 * =====================================================================================
 *
 *       Filename:  i2s-dev.c
 *    
 *    Description: I2S Microphone driver for SPH0645 mic on Debian11 (Bullseye OS)
 *
 *        Version:  1.0
 *        Created:  04/20/2024
 *       Revision:  none
 *       Compiler:  gcc version 10.2.1
 *
 *         Author: Jordin Eicher (Origin: Paul Creaser)
 *   Organization: University of Iowa
 *
 * =====================================================================================
 */

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kmod.h>
#include <linux/platform_device.h>
#include <sound/simple_card.h>
#include <linux/delay.h>



void device_release_callback(struct device *dev) { /*  do nothing */ };

/*  ASoC - ALSA System on Chip: Kernel subsys for portable audio codecs
 *  
 *  ASoc Platform Drivers: Audio DMA, SoC DAI, DSP.  
 *
 *  DAI - Digital Audio Interface: We are using the I2S interface
 */

static struct asoc_simple_card_info snd_rpi_simple_card_info = {
    .card = "i2s-microphone", // -> snd_rpi_simple_card -> snd_soc_card.name
    .name = "simple-card_codec_link", // -> snd_soc_dai_link.name
    .codec = "snd-soc-dummy", // "dmic-codec", // -> snd_soc_dai_link.codec_name
    .platform = "3f203000.i2s",
    
    .daifmt = SND_SOC_DAIFMT_I2S | SND_SOC_DAIFMT_NB_NF | SND_SOC_DAIFMT_CBS_CFS,
    
    .cpu_dai = {
        .name = "3f203000.i2s", // -> snd_soc_dai_link.cpu_dai_name
        .sysclk = 0 },
    
    .codec_dai = {
        .name = "snd-soc-dummy-dai", //"dmic-codec", // -> snd_soc_dai_link.codec_dai_name
        .sysclk = 0 },
};

static struct platform_device snd_rpi_simple_card_device = {
    .name = "asoc-simple-card", //module alias
    .id = 0,
    .num_resources = 0,
    
    .dev = { 
        .release = &device_release_callback,
        .platform_data = &snd_rpi_simple_card_info,
        },
};


static int __init i2s_dev_init(void)
{
    const char *dmaengine = "bcm2708-dmaengine"; // for rpi Z2W, 32-bit -> bcm2708-dma engine bcm2709
    int ret;

    printk("i2s: starting i2s-dev module\n");

    ret = request_module(dmaengine); // ret val for bcm2709 was "256"
    printk("request module load '%s': %d\n",dmaengine, ret);
    ret = platform_device_register(&snd_rpi_simple_card_device);
    printk("register platform device '%s': %d\n",snd_rpi_simple_card_device.name, ret);

    printk("i2s-dev loaded\n");
    return 0;
}

static void __exit i2s_dev_exit(void)
{
    printk("i2s: closing i2s-dev module\n");
    platform_device_unregister(&snd_rpi_simple_card_device);
    pr_alert("Unregistering simple sound card!\n");
    return;
}

module_init(i2s_dev_init);
module_exit(i2s_dev_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Jordin Eicher");
MODULE_DESCRIPTION("I2S capture sound card driver");
MODULE_VERSION("1.0")


