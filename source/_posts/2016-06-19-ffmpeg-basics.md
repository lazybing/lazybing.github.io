---
layout: post
title: "FFmpeg 使用"
date: 2016-06-19 09:59:26 -0700
comments: true
categories: 读书笔记
---
* list element with functor item
{:toc}

FFmpeg Basics ---Multimedia handling with a fast audio and video encoder 是 FFmpeg 官网提供的一本对 FFmpeg 使用的介绍手册。本文就是对读此手册时的简单记录。方便了解 FFmpeg 的作用。

<!--more-->

---

### Bit Rate, Frame Rate 和 File Size

Frame Rate 是一秒钟播放的 frame 的个数，又可以分为 interlaced 和 progressive 两种， Interlaced Frame 主要用于 TV，如 NTSC 标准使用 60i fps ，即 60 interlaced fields（30 frames）每秒。

Frame rate 设置使用 -r 选项： `ffmpeg -i input -r fps output`

```
ffmpeg -i input.avi -r 30 output.mp4
```
除此之外，也可用 fps filter 设置 frame rate。

```
ffmpeg -i clip.mpg -vf fps=fps=25 clip.webm
```

Bit Rate 是单位时间内可以处理的 bits 数，可分为 `ABR(Average bit rate)` `CBR(Constant bit rate)` `VBR(Variable bit rate)`。
Bit Rate 设置使用 -b 选项：`ffmpeg -i input -b bitrates output`
针对 video 和 audio 的不同，又可使用 `-b:v` 和 `-b:a`。

```
ffmpeg -i file.avi -b 1.5M film.mp4
ffmpeg -i input.avi -b:v 1500k output.mp4
```
CBR 的设置需要同时设置 bitrate、minimal rate 和 maximal rate 为相同的值，设置 maxrate的同时需要设置 bufsize 选项。

```
ffmpeg -i in.avi -b 0.5M -minrate 0.5M -maxrate 0.5M -bufsize 1M out.mkv
```

File Size 是由 Video Size 和 Audio Size 两者之和组成的。

```
video_size = video_bitrate * time_in_seconds / 8;
audio_size = audio_bitrate * time_in_seconds / 8; 或
audio_size = sampling_rate * bit_depth * channels * time_in_seconds / 8;
```
也可设置输出文件的最大值,设置选项为 -fs(file size) ： 

```
ffmpeg -i input.avi -fs 10MB output.mp4
```
----

### Resizing and Scaling Video

Resizing 是指改变宽高，Scaling 是利用 scale filter 改变 frame size。

Resizing Video ： 利用 `-s`选项指定输出视频的宽高，格式为`wxh`，其中 w 是以 pixel 为单位的宽， h 是以 pixel 为单位的高。例如:

```
ffmpeg -i input_file -s 320x240 output_file
```
此外，FFmpeg 针对不同的宽高信息，提供了预定义的视频大小简写，下面两个命令的作用相同，都是将 input_file 转换为 640*480 的输出文件：

```
ffmpeg -i input_file.avi -s 640x480 output.avi
ffmpeg -i input_file.avi -s vga output.avi
```
通常情况下，做 resize 是从`big frame -> small frame`，反过来的话，可能导致图片不清晰，尤其是当原始视频的 resolution 比较小的时候。针对 `small frame -> big frame`，有专门的特殊 filter（`super2xsai`） 可以使用，它可以使原视频文件变大两倍。2xsai 即指 2 times scale and interpolate, syntax 是 `-vf super2xsai`。
例如把 128x96 的 phone_video.3gp 文件转换为 256x192 的视频文件。

```
ffmpeg -i phone_video.3gp -vf super2xsai output.mp4
```

Scaling Video : 当使用`-s`选项来改变 frame size 时，其实在 filtergraph 的最后有一个 scale filter。scale filter也可以通过设置来固定在某个位置。

scale 可以改变输出视频的 sample aspect ration，同时 display aspect ration 保持不变。

syntax 是 `scale=width:height[:interl={l|-l}]`。其中 width 和 height 可以是 iw/in_w/ih/in_h/ow/out_w/oh/out_h等。

下面两个 command 执行效果相同:

```
ffmpeg -i input.mpg -s 320x240 output.mp4
ffmpeg -i input.mpg -vf scale=320:240 output.mp4
```
如果不知道源视频的 resolution，又需要做 scale，可以用下面的方法:

```
ffmpeg -i input.mpg -vf scale=iw/2:ih/2 output.mp4
ffmpeg -i input.mpg -vf scale=iw*0.9:ih*0.9 output.mp4
ffmpeg -i input.mpg -vf scale=iw/PHI:ih/PHI output.mp4
```

---

### Cropping Video

Cropping Video 是指截取源视频中的某个矩形区域作为输出视频显示。通常它会与 Resizing/Padding 等共同配合使用。

旧版 FFmpeg 中会使用 cropbottom/cropleft/cropright/croptop 等选项，现在的版本中废弃了这种使用方式，改用`crop filter`的方式来实现Cropping Video。

syntax 是`crop=ow[:oh[:x[:y[:keep_aspect]]]]`，其中 `ow=out_w oh=out_h`。示例如下：

```
ffmpeg -i input -vf crop=iw/3:ih:0:0 output
ffmpet -i input -vf crop=iw/3:ih:iw/3*2:0 output
```
如果x和y没有专门给出，会有默认值计算：

```
X(default) = (input width - output widht)/2
Y(default) = (input height - output height)/2
```
```
ffmpeg -i input_file -vf crop=w:h output_file
ffmpeg -i input.avi -vf crop=iw/2:ih/2 output.avi
```

---

### Padding Video
对于 Padding Video ，使用 pad filter 来实现。
syntax 是`pad=width[:height[:x[:y[:color]]]]`，其中的 color 表示 padding 的颜色。

```
ffmpeg -i photo.jpg -vf pad=860:660:30:30:pink framed_photo.jpg
```

Padding videos from 4:3 to 16:9

```
ffmpeg -i input -vf pad=ih*16/9:ih:(ow-iw)/2:0:color output
ffmepg -i film.mpg -vf pad=ih*16/9:ih:(ow-iw)/2:0 filem_wide.avi
```

Padding videos from 16:9 to 4:3

```
ffmpeg -i input -vf pad=iw:iw*3/4:0:(oh-ih)/2:color output
ffmpeg -i hd_video.avi -vf pad=iw:iw*3/4:0:(oh-ih)/2 video.avi
```

Padding from and to various aspect ratios

```
ffmpeg -i input -vf pad=ih*ar:ih:(ow-iw)/2:0:color output //pillarboxing -adding boxes horizontally(To adjust a smaller width-to-height aspect ration to the bigger)
ffmpeg -i input -vf pad=iw:iw*ar:0:(oh-ih)/2:color output //letterboxing -adding boxes vertically(To adjust a bigger width-to-height aspect ration to the smaller)
```
---

###Filpping and Rotating Video

###Blur Sharpen adn Other Denoising

###Overlay - Picture in Picture

###Adding Text on Video

###Conversion Between Formats

