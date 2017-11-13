---
layout: post
title: "FFmpeg 和 SDL 使用教程（四）"
date: 2016-05-10 18:22:59 -0700
comments: true
categories: 项目实践
---

* list element with functor item
{:toc}

本节主要对前面几节的代码进行一下重构。  

<!--more-->

## 概述

上一小结，通过`SDL`的音频函数添加了支持音频的线程。`SDL`启动一个线程。现在我们用相同的方法完成视频的显示。该方法会使得代码更加模块化、易于维护，尤其是当需要添加同步的时候。  

我们注意到之前的`main`函数中做了非常多的操作：loop 循环、读取数据包、解码视频。因此，我们接下来要将这些东西都分开：启动一个线程处理解码数据包，该数据包之后会添加到队列，而音频和视频的线程会从该队列中读取相应的数据；音频线程我们已经启动；视频线程由于包含了视频的显示部分，会略显复杂。
我们即将添加真实的显示代码到`main loop`中，除了每次循环是只是显示视频，我们会将视频显示部分整合进事件循环中。整合的大体思路为：解码视频，保存解码的视频帧到另一个队列中，创建一个消耗视频帧的事件 (FF_REFRESH_EVENT) 添加到事件系统中，当事件循环发现该`event`时，他会显示队列中的下一帧。图示如下：  

{% img /images/ffmpeg_tutorial/encode_thread.png %}  

通过`event loop`来移动控制视频显示的主要目的是：使用`SDL_Delay`线程，可以准确的控制何时显示视频的下一帧到屏幕上。下一节中当我们最后完成了同步视频时，它会在正确的时间显示正确的图片。  

## 简化代码

我们同样会简化一下代码。我们已经获取了所有音频和视频的信息，并且我们会添加队列和缓存。所有的这一些的最终目的是可以看到电影。所以接下来我们会完成一个比较大的结构体，命名为`VideoState`,它会保存所有的信息。  

{% codeblock lang:c %}
typedef struct VideoState{
    AVFormatContext *pFormatCtx;
    int             videoStream, audioStream;
    AVStream        *audio_st;
    AVCodecContext  *audio_ctx;
    PacketQueue     qudioq;
    uint8_t         audio_buf[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3)/2];
    unisgned int    audio_buf_size;
    unisgned int    audio_buf_index;
    AVPacket        audio_pkt;
    uint8_t         *audio_pkt_data;
    int             audio_pkt_size;
    AVStream        *video_st;
    AVCodecContext  *video_ctx;
    PacketQueue     videoq;

    VideoPicture    pictq[VIDEO_PICTURE_QUEUE_SIZE];
    int             pictq_size, pictq_rindex, pictq_windex;
    SDL_mutex       *pictq_mutex;
    SDL_cond        *pictq_cond;

    SDL_Thread      *parse_tid;
    SDL_Thread      *video_tid;

    char            filename[1024];
    int             quit;
}VideoState;
{% endcodeblock %}

通过上面的结构体，简单看一下我们可能会获得的信息。首先我们可以看到基本的信息——格式内容以及视频流和音频流的索引，对应的`AVStream`对象。还有，我们可以看到我们已经将一些音频的缓存移到了该结构体内。
这些信息（audio_buf,audio_buf_size）包含了音频的所有信息。同样的，我们为视频添加了另外一个队列，为解码的帧添加了新的缓存。`VideoPicture`结构体是我们自己定义的，后面会提到里面包含的内容。我们还看到为另外创建的两个线程
分别分配指针，已经`quit`标志和电影名。  

现在让我们重新回到`main`函数的起点看看如何改动我们的程序，首先设置`VideoState`结构体：  

{% codeblock lang:c %}
int main(int argc, char **argv){
    SDL_Event event;

    VideoState *is;

    is = av_mallocz(sizeof(VideoState));
}
{% endcodeblock %}

`av_mallocz()`函数可以分配内存，并对分配的内存清零。  

之后初始化显示缓存的锁`pictq`，因为事件循环里会调用显示函数，显示函数会从`pictq`中拉取已解码好的解码帧；同时视频解码器也会将信息放到`pictq`中，但此时并不知道什么时候谁去获取这些信息。
此处就是竞争条件。因此在启动任何线程之前分配出来。同时要拷贝文件名到`VideoState`中。  

{% codeblock lang:c %}
av_strlcpy(is->filename, argv[1], sizeof(is->filename));

is->pictq_mutex = SDL_CreateMutex();
is->pictq_cond  = SDL_CreateCond();
{% endcodeblock %}

`av_strlcpy`是`FFMpeg`库中的一个函数。  

## Our First Thread

现在让我们完成线程、完成真正的工作： 

{% codeblock lang:c %}
schedule_refresh(is, 40);

is->parse_tid = SDL_CreateThread(decode_thread, is);
if(!is->parse_tid){
    av_free(is);
    return -1;
}
{% endcodeblock %}

`schedule_refresh`函数稍后会详细介绍，上面的代码主要完成的是告知系统特定长度时间后产生一个`FF_REFRESH_EVENT`时间。这会反过来调用刷新函数。
`SDL_CreateThread()`

## Getting the Frame:video_thread 

## Queueing the Frame

## Displaying the Video

