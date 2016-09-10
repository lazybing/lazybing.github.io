---
layout: post
title: "FFmpeg的介绍、安装及使用"
date: 2016-05-09 04:00:29 -0700
comments: true
categories: FFMPEG源码分析
---



[FFmpeg 官网](https://ffmpeg.org/)对 FFmpeg 的描述是这样的：

```
A complete, cross-platform solution to record, convert and stream audio and video.
```
<!--more-->
###介绍
`FFmpeg` 是一个多媒体架构，能够用于解码、编码、转码、复用、解复用、滤波以及播放人类或机器制造出来的各种媒体文件。它能够支持最古老的、最前沿的媒体格式，不管这种格式是由官方标准社区制定还是由各大公司合作制定。

`FFmpeg` 的使用非常广泛，几乎涵盖了所有的媒体相关的视频播放器、转码器等。例如使用 `FFmpeg` 作为内核的视频播放器有（Mplayer，射手影音，暴风影音，KMPlayer，QQ影音等）；使用 `FFmpeg` 作为内核的转码器有(格式工厂，狸窝视频转换器，暴风转码等)。

作为视频解码程序员，我将 `FFmpeg` 大致分为两个方向：

	1. FFmpeg 工具：ffmpeg、 ffplay、 ffserver、 ffprobe

	2. FFmpeg 库：libavutil、 libavcodec、 libavformat、 libavdevice、 libavfilter、 libswscale、 libswresample

首先介绍 FFmpeg 的几个工具：

	ffmpeg 是一个用于装换各种多媒体格式的命令行工具。
	
	ffplay 是一个基于 `SDL` 和 `FFmpeg` 库的简单播放器。
	
	ffprobe 是一个简单的多媒体流分析器。
	
	ffserver 是一个用于现场播放的流媒体服务器。


其次 `FFmpeg` 库的介绍。这部分后续会补上。


###安装

`FFmpeg` 源码根目录下有 `FFmpeg` 的安装介绍文件 `INSTALL.md`。

	1. ./configure #配置，可以指定 FFmpeg 的安装路径。
	
	2. make #版本号至少要GNU Make 3.81
	
	3. make install

上述步骤可能需要一点时间。
安装完成后，就可以使用 `FFmpeg` 工具了。

如果只是想使用 `FFMpeg`,`Max OSX`下可以用`brew`来安装。
{% codeblock %}
brew install ffmpeg
{% endcodeblock %}


###使用

Linux 下如果想深入的学习 `FFmpeg` 工具的使用，可以类似于学习 Linux 自带的命令一样，使用 `man ffmpeg` 或者 `ffmpeg --help` 等获取帮助信息。

以 `ffmpeg`为例，可以使用如下命令进行转换。

```
ffmpeg -i input_file out_file
```
或者可以使用 `ffplay` 命令直接播放视频文件。

```
ffplay play_file 
```

或者可以使用 `ffprobe` 命令分析媒体文件。
```
ffprobe file
```
