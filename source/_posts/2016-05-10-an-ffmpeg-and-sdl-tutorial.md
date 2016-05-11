---
layout: post
title: "FFmpeg 和 SDL 使用教程"
date: 2016-05-10 16:45:03 -0700
comments: true
categories: 项目实践
---

[FFmpeg](https://ffmpeg.org/) 是制作视频应用或一般工具的非常棒的库。[SDL](https://www.libsdl.org/) 通过封装复杂的视音频底层交互工作，降低了视音频的处理难度。

本文就记录一下利用 FFmpeg 和 SDL 制作简单播放器的详细步骤。<!--more-->

###介绍

对于一个视音频文件，可以从外到内的依次分为几个层面：container、stream、packets、frames.其中 container 就是平时说的`.avi` `.flv` `.mkv`等等。stream可能是 `video`、可能是 `audio`、也可能是 `subtitle`，一个文件里面可能包含多个 `video` `audio` `subtitle`。packets 是从 stream 里得到的，通常会包含一个 `video frame` 或多个 `audio frame`。

视音频的处理就是按照这几个层级处理的，以 `.avi` 为例大概步骤如下：

	1. OPEN video_stream FROM video.avi

	2. READ packet FROM video_stream INTO frame

	3. IF frame NOT COMPLETE GOTO 2

	4. DO SOMETHING WITH frame

	5. GOTO 2
	
当然，步骤 4 中的"DO SOMETHING"可能非常复杂，我们先简单的把得到的 frames 写到一个 PPM 文件中。

