---
layout: post
title: "FFmpeg 使用"
date: 2016-06-19 09:59:26 -0700
comments: true
categories: 读书笔记
---

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

### Cropping Video
