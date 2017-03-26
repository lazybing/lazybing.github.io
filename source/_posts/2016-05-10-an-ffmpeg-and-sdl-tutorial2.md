---
layout: post
title: "FFmpeg 和 SDL 使用教程（二）"
date: 2016-05-10 16:45:03 -0700
comments: true
categories: 项目实践
---

* list element with functor item
{:toc}

本文主要记录如何利用`SDL`，将上一节中解处数据显示到屏幕上。  

<!--more-->

## SDL 和 Video

为将图像显示到屏幕上，我们将使用`SDL`,`SDL`是`Simple DIrect Layer`的简称，
它是一个非常优秀的跨平台多媒体库。我们可以在[官网](https://www.libsdl.org/)上得到该库，
或者可以直接下载开发包，想要使用该库，必须在对应的平台上编译它。   

`SDL`有许多方法将图像描绘到屏幕上，其中一个称之为`YUV Overlay`。`YUV`即类似于`RGB`的
图像数据。简单说，`Y`用于存储亮度分量，`U`和`V`是色度分量。（`YUV`比`RGB`要复杂，因为
有的色度信息是丢失的，比如有的数据每 2 个`Y`，会有 1 个`U` 1 个`V`）`YUV Overlay`可以接受
 4 种不同的`YUV`格式，但`YV12`是最高效的。另外一种`YUV`格式称之为`YUV420P`，它与`YV12`类似，
只是`U`和`V`交换了位置。  

因此当前的任务就是将上一节中`tutorial 1`里的`SaveFrame()`去掉，替换成输出帧到屏幕即可。
但首先看下如何使用`SDL`库。首先必须包含库并初始化`SDL`:  

{% codeblock lang:c %}
#include <SDL.h>
#include <SDL_thread.h>

if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO |SDL_INIT_TIMER)){
    fprintf(stderr, "Could not initialize SDL - %s \n", SDL_GetError());
    exit(1);
}
{% endcodeblock %}

其中`SDL_Init`用于初始化`SDL`库，`SDL_GetError`是一个 debug 处理函数。  

## 创建显示区域

现在需要屏幕上的一个区域来显示图像。`SDL`中用于显示图像的区域称之为`surface`。  

{% codeblock lang:c %}
SDL_Surface *screen;
screen = SDL_SetVideoMode(pCodecCtx->width, pCodecCtx->height, 0, 0);
if(!screen){
    fprintf(stderr, "SDL:could not set video mode -exiting \n"); 
    exit(1);
}
{% endcodeblock %}

上面的过程使用给定的宽高创建一个屏幕区域。下一个参数是屏幕的`bit depth`，0是一个特殊的值，
代表`与当前显示相同`。  

现在我们需要在该屏幕区域创建一个`YUV overlay`，以便于可以将视频输入进去。并且要创建`SWSContext`来
转换图像数据到`YUV420`。   

{% codeblock lang:c %}
SDL_Overlay *bmp = NULL;
struct SWSContext *sws_ctx = NULL;

bmp = SDL_CreateYUVOverlay(pCodecCtx->width, pCodecCtx->height, SDL_YV12_OVERLAY, screen);

//initialize SWS context for software scaling
sws_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, PIX_FMT_YUV420P, SWS_BILINEAR, NULL, NULL, NULL);
{% endcodeblock %}

正如上面提到的，我们使用`YV12`来显示图像，从ffmpeg里得到`YUV420`数据。  

## 显示图像

现在已经非常明显了，我们只需要显示图像。确定帧结束的位置后，只需要将`SaveFrame`替换
成显示的代码即可。为例显示图像，我们将使用`AVPicture`结构并将它的数据指针和`linesize`指向
`YUV Overlay`。  

{% codeblock lang:c %}
if(frameFinished) {
    SDL_LockYUVOverlay(bmp);

    AVPicture pict;
    pict.data[0] = bmp->pixels[0];
    pict.data[1] = bmp->pixels[2];
    pict.data[2] = bmp->pixels[1];

    pict.linesize[0] = bmp->pitches[0];
    pict.linesize[1] = bmp->pitches[2];
    pict.linesize[2] = bmp->pitches[1];

    // Convert the image into YUV format that SDL uses
    sws_scale(sws_ctx, (uint8_t const * const *)pFrame->data,
	      pFrame->linesize, 0, pCodecCtx->height,
	      pict.data, pict.linesize);
    
    SDL_UnlockYUVOverlay(bmp);
  } 
{% endcodeblock %}

首先，先给`overlay`上锁，因为接下来要对它进行写操作。给代码加锁是一个非常好的习惯，
它能够避免很多问题。如前面提到的，`AVPicture`有一个指针数组，它有 4 个指向数据的指针组成。
因为我们要处理的是`YUV420P`的数据，只需要用到其中的3个指针即可。其他格式的数据可能会用到第 4 个
指针。`linesize`就如同它的名字一样。

## 描绘图像

但我们要明确的告诉`SDL`时间显示的数据，即在何处显示、显示的宽高信息。之后，SDL 会帮助我们实现显示功能。  

{% codeblock lang:c %}
SDL_Rect rect;

  if(frameFinished) {
    /* ... code ... */
    // Convert the image into YUV format that SDL uses
    sws_scale(sws_ctx, (uint8_t const * const *)pFrame->data,
              pFrame->linesize, 0, pCodecCtx->height,
	      pict.data, pict.linesize);
    
    SDL_UnlockYUVOverlay(bmp);
	rect.x = 0;
	rect.y = 0;
	rect.w = pCodecCtx->width;
	rect.h = pCodecCtx->height;
	SDL_DisplayYUVOverlay(bmp, &rect);
  }
{% endcodeblock %}

至此，视频已经显示到桌面上了。

`SDL`还有另外一个功能：事件处理功能。`SDL`一旦建立，当接受到点击、移动鼠标、发送信号时，`SDL`就会产生一个事件。
如果想要处理用户输入的事件，程序就可以检测这些时间。程序同样的可以制造一些事件，然后发给`SDL`的事件处理系统。
这对于使用`SDL`的多线程程序尤为有用，后面会提到。此时，我们只要处理`SDL_QUIT`事件来退出：  

{% codeblock lang:c %}
SDL_Event       event;

    av_free_packet(&packet);
    SDL_PollEvent(&event);
    switch(event.type) {
    case SDL_QUIT:
      SDL_Quit();
      exit(0);
      break;
    default:
      break;
    }
{% endcodeblock %}

## 程序编译

```
gcc -o tutorial02 tutorial02.c -lavformat -lavcodec -lswscale -lz -lm `sdl-config --cflags --libs`
```

