---
layout: post
title: "FFmpeg 学习之 FFplay源码分析"
date: 2016-11-05 21:03:58 -0700
comments: true
categories: ffmpeg源码分析
---

FFplay 是一个简单便携的媒体播放器，它使用了 FFmpeg 和 SDL 库。  
<!--more-->

首先看一下 FFplay 的使用：安装完 FFmpeg 后，直接在命令行中输入   
```
ffplay [options] bitstream_file
```
其中更详细的使用说明，可以使用`man ffplay`来查看。

其次我们可以通过使用`Esc``q`来推出播放，可以使用空格来暂停播放，可以使用`s`来执行逐帧播放视频等等操作。

ffplay 里面最主要的函数时:`av_register_all()``SDL_Init(flags)``av_init_packet``stream_open``event_loop`。下面逐个分析这几个函数主要完成的功能。  


