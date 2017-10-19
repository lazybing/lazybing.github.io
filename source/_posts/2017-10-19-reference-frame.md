---
layout: post
title: "X264 源码解析之参考帧"
date: 2017-10-19 07:53:49 -0700
comments: true
categories: X264
---

* list element with functor item
{:toc}

本篇博客主要记录`X264`中关于参考帧管理。

<!--more-->

`X264`中的帧可以大致分为以下几类：参考帧(ference frame)、当前编码帧(current frame)、未使用帧(unused frame)等。对帧的管理操作
的基本操作由两种：从队列中获取帧(`x264_frame_pop`)、向队列中添加帧(`x264_frame_push_unused`)。

关于帧队列的管理是通过数组来的，下面先介绍最基本的帧队列的一些基本操作。  

首先将`frame`帧插入到`list`队列中，实现代码如下：  

{% codeblock lang:c x264_frame_push %}
void x264_frame_push(x264_frame_t **list, x264_frame_t *frame)
{
    int i = 0;
    while(list[i]) i++;
    list[i] = frame;
}
{% endcodeblock %}

从`list`队列中获取`frame`帧，实现代码如下：  

{% codeblock lang:c x264_frame_pop %}
x264_frame_t *x264_frame_pop( x264_frame_t **list )
{
    x264_frame_t *frame;
    int i = 0;
    assert( list[0] );
    while( list[i+1] ) i++;
    frame = list[i];
    list[i] = NULL;
    return frame;
}
{% endcodeblock %}

当编码帧类型为`IDR`帧时，需要重置整个参考帧队列，`X264`中重置参考队列是通过`x264_reference_reset`函数完成，实现过程即为将`reference`队列
所有的参考帧设置为`unused`队列中的`unused`帧；实现代码如下：  

{% codeblock lang:c x264_reference_reset %}
static inline void x264_reference_reset( x264_t *h )
{
    while( h->frames.reference[0] )
        x264_frame_push_unused( h, x264_frame_pop( h->frames.reference ) );
    h->fdec->i_poc =
    h->fenc->i_poc = 0;
}
{% endcodeblock %}


