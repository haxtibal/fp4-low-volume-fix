# Fairphone 4 handset-mic low volume fix

This is a Magisk module to fix
[Microphone quality of the FP4 when using Signal (low volume)](https://forum.fairphone.com/t/microphone-quality-of-the-fp4-when-using-signal-low-volume/79021).
It simply overlays `mixer_paths_lagoon_fp4.xml` with a modified version.

The effective patch is
```
--- mixer_paths_lagoon_fp4.xml  2022-01-05 09:31:56.000000000 +0100
+++ mixer_paths_lagoon_fp4.xml.dec0_100 2022-01-08 09:10:08.000000000 +0100
@@ -3431,6 +3431,7 @@
 
     <path name="handset-mic">
         <ctl name="TX_CDC_DMA_TX_3 Channels" value="One" />
+        <ctl name="TX_DEC0 Volume" value="100" />
         <path name="amic1" />
     </path>
```

This modification will let the HAL raise ALSA control `"TX_DEC0 Volume"` from `81`to `100`
whenever a recording with input device set to `"handset-mic"` happens and take it back afterwards.

Original file was sampled from A.094.20211213. Be careful when applying to newer FP4 versions.
If they changed `mixer_paths_lagoon_fp4.xml`, you would still see the old sampled version.

Eventually the issue should be fixed by Fairphone in their stock ROM,
rather than in a community reverse engineering attempt. Please consider opening a
[request at support.fairphone.com](https://support.fairphone.com/hc/en-us/requests/new)
to raise importance.


## Background

The low volume bug happens because FP4's audio HAL sets up the bottom microphone for audio recordings
just like it would during a regular phone call. That doesn't make sense:
- during a regular phone call, we're typically 10 cm or closer to the bottom mic
- during a audio recording we're likely more distant, say 0.5 m to 5 m

Because `p ~ 1/r`, a much lower signal is to be expected in the audio recording case.
To get a reasonable recording level anyway one can e.g. increase gain, or route the audio input to
signal processing stages like [AGC](https://en.wikipedia.org/wiki/Automatic_gain_control) or
[compressor](https://en.wikipedia.org/wiki/Dynamic_range_compression).


## Fairphone 4 audio stack

To reason about bug and fix, we need some understanding of the FP4's audio stack.
It's roughly like below. No warranty, I've no access to restriced Qualcomm material
and just combined public sources and findings from debugging sessions.

```
+---------------+
| recording app |
+---------------+
    | import android.media.MediaRecorder
+-------------------------+
| Android Media Framework |
+-------------------------+
     | Binder IPC
+-------------------------+     
| AudioFlinger            |
| inside mediaserver      |
+-------------------------+
     | load library
+-----------------------------+  
| Qualcomm specific audio HAL | --- /vendor/etc/audio_platform_info_lagoon_fp4.xml,
|    audio.primary.lito.so    |                 mixer_paths_lagoon_fp4.xml, ...
+-----------------------------+  
     | load library      | load library
+----------------+  +------------------+
| tinyalsa       |  | ACDB Loader      | --- /vendor/etc/acdbdata/*/*.acdb
| libtinyalsa.so |  | proprietary      |
+----------------+  | libacdbloader.so |
     |              +------------------+
     | ioctl, mmap       | ioctl
     | 34 PCM devices    |
     | 3189 controls     |
 ___________________________________
| Linux kernel 4.19                 | --- Device Tree Blob and Overlay,
|                                   |     including qcom,msm-audio-apr subtree
| Out-of-tree ALSA SoC layer driver |     handed over by bootloader
| kona.c, module_platform_driver(   |
|   kona_asoc_machine_driver);      | 
|___________________________________|  _____________
     | runs on                        | QuRT OS     | 
     |                                | proprietary |
     |                                |_____________|
     |                                    | runs on
 ____|____________________________________|____
|    |    Qualcomm Snapdragon 750G SoC    |    |
|    |    aka SM7225 Mobile Platform      |    |
|    |                                    |    |
| +----------------+                      |    |
| | CPU Kryo 570   |                      |    |
| | Cortex-A77/A55 |                      |    |
| +----------------+                      |    |
| +--------------------+  +-----------------+  |
| | Audio Codec WX938x |  | DSP Hexagon 694 |  |
| +--------------------+  +-----------------+  |
|__|_____|_____|_______________________________|
   |     |     |
 MEMS  MEMS  MEMS
 Mic1  Mic2  Mic3
```

References:
- [FP4 boot.img](https://storage.googleapis.com/fairphone-source/FP4/A.094-boot.img)
- [FP4 device tree overlay](https://storage.googleapis.com/fairphone-source/FP4/A.094-dtbo.img)
- [QCom audio HAL in AOSP 11](https://android.googlesource.com/platform/hardware/qcom/audio/+/refs/heads/android11-mainline-release/hal)
- [FP4 Kernel sources](https://gerrit-public.fairphone.software/plugins/gitiles/kernel/msm-4.19/+/refs/heads/kernel/11/fp4)
- [Out-of-tree audio driver](https://gerrit-public.fairphone.software/plugins/gitiles/platform/vendor/opensource/audio-kernel/+/refs/heads/kernel/11/fp4)
- [Android MediaRecorder](https://developer.android.com/reference/android/media/MediaRecorder)
- [AudioFlinger in AOSP 11](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/android11-mainline-release/services/audioflinger/AudioFlinger.cpp)
- [tinyalsa](https://github.com/tinyalsa/tinyalsa)
- [Lantronix Blog about the Hexagon DSP](https://www.lantronix.com/blog/using-the-hexagon-dsp/)
