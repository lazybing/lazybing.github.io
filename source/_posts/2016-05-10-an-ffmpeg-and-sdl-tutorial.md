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

------------
####打开文件
想要利用FFmpeg，你必须首先初始化库。
{% codeblock lang:c %}
int main(int argc, char *argv[]){
av_register_all();
{% endcodeblock %}
`av_register_all()`用于注册所有编译过的`muxers` `demuxers`和`protocols`，同时，该函数还会调用`avcodec_register_all()`注册所有的音视频 codec。

现在就可以打开视频文件了。
{% codeblock lang:c %}
AVFormatContext *pFormatCtx = NULL;

//open video file
if(avformat_open_input(&pFormatCtx, argv[1], NULL, 0, NUL) != 0)
	return -1; //Couldn't open file
{% endcodeblock %}
调用函数 `avformat_open_input`,该函数读取文件头部，并将文件的格式信息存储到`AVFormatContext`结构中。最后的三个参数分别用于指定文件格式、内存大小和格式选项，此处设为`NULL`或 0，`libavformat`能够自动侦测到。

该函数只是简单的查看头部信息，接下来我们需要文件中码流的信息：
{% codeblock lang:c %}
//Retrieve stream information
if(avformat_find_stream_info(pFormatCtx, NULL) < 0)
	return -1;	//Couldn't find stream information
{% endcodeblock %}
该函数用适当的信息填充`pFormatCtx->streams`。此处介绍一个便于调试的函数来看一下里面的内容：
{% codeblock lang:c %}
//Dump information about file onto standard error
av_dump_format(pFormatCtx, 0, argv[1], 0);
{% endcodeblock %}
现在`pFormatCtx->streams`仅仅是一个数组指针，数组大小为`pFormatCtx->nb_streams`,遍历该数组直到找到一个视频流。
{% codeblock lang:c %}
int i;
AVCodecContext *pCodecCtxOrig = NULL;
AVCodecContext *pCodecCtx     = NULL;

//Find the first video stream
videoStream = -1;
for(i = 0; i < pFormatCtx->nb_streams; i++)
	if(pFormatCtx->streams[i]->codec->codec_type = AVMEDIA_TYPE_VIDEO){
		videoStream = i;
		break;
	}
if(videoStream == -1)
	return -1; //Didn't find a video stream
	
// Get a pointer to the codec context for the video stream
pCodecCtx = pFormatCtx->streams[videoStream]->codec;
{% endcodeblock %}


