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

## 显示图像

## 描绘图像
