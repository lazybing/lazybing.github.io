---
layout: post
title: "x264源码解析之x264_encoder_open函数"
date: 2017-06-24 18:24:01 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

本文主要记录`x264_encoder_open`函数。  

<!--more-->

`x264_encoder_open`函数是`encode`函数的几大主要函数之一。从名字可以看出，该函数主要是打开编码器，
它的主要作用是对编码器用到的一些参数进行初始化、并对编码器用到的一些与编码算法相关的函数进行初始化。
可以首先看一下它的声明：  

```
/* x264_encoder_open:
 *      create a new encoder handler, all parameters from x264_param_t are copied */
x264_t *x264_encoder_open( x264_param_t * );
```
`x264_encoder_open`中会调用到一些宏定义的函数，比如`x264_reduce_fraction`，这里先把该函数的定义给出来：  

{% codeblock lang:c %}
/****************************************************************************
 * x264_reduce_fraction:
 ****************************************************************************/
#define REDUCE_FRACTION( name, type )\
void name( type *n, type *d )\
{                   \
    type a = *n;    \
    type b = *d;    \
    type c;         \
    if( !a || !b )  \
        return;     \
    c = a % b;      \
    while( c )      \
    {               \
        a = b;      \
        b = c;      \
        c = a % b;  \
    }               \
    *n /= b;        \
    *d /= b;        \
}

REDUCE_FRACTION( x264_reduce_fraction  , uint32_t )
REDUCE_FRACTION( x264_reduce_fraction64, uint64_t )
{% endcodeblock %}

将上面的`x264_reduce_fraction`展开，代码如下：  

{% codeblock lang:c %}
void x264_reduce_fraction(uint32_t *n, uint32_t *d)
{
	uint32_t a = *n;
	uint32_t b = *d;
	uint32_t c;
	
	if(!a || !b)
	    return;
	c = a % b;
	while(c)
	{
		a = b;
		b = c;
		c = a % b;
	}
	*n /=b;
	*d /=b;
}
{% endcodeblock %}

通过上面的展开可能一眼看不出所以然，其实这是一个非常简单的算法应用，求两个数 n 和 m 约分后再分别
赋值给相应的分子和分母，函数的前半部分就是经典的求最大公约数 b 的过程，可以参考[细说算法--最大公约数](http://blog.csdn.net/so_geili/article/details/50955291)。

暂时先理解这段代码的含义，至于为什么要这么做，后面在分析。

