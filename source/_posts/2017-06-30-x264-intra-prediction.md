---
layout: post
title: "x264 源码分析之帧内预测"
date: 2017-06-30 08:12:22 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

本文主要记录 x264 中使用到的帧内预测技术。

<!--more-->

x264 中对于预测  

| intra16x16Predmode     | Name of Intra16x16PredMode   | Note  |
| :--------------------: | :--------------------------: | :---: |
| 0                      | Intra_16x16_Vertical(prediction mode) | 由上边像素推出相应像素值 |
| 1                      | Intra_16x16_Horicontal(prdiction mode)| 由左边像素推出相应像素值 |
| 2                      | Intra_16x16_DC(prediction mode)       | 由上边和左边像素平均值推出相应像素值 |
| 3                      | Intra_16x16_Plane(prediction mode)    | 利用线性 plan 函数及左、上像素推出相应像素值，适用于亮度变化平缓区域 |

下面依次分析这几种预测模式：  


### Intra_16x16_Vertical 预测模式 

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_16x16 prediction mode shall be used only when the samples p[x, -1] with x=0...15 are marked as "available for Intra_16x16 prediction".The values of the prediction samples pred[x, y] with x,y=0...15, are derived by pred[x,y]=p[x,-1],with x,y=0...15  
{% endblockquote %}

x264 中关于模式 Vertical 的代码如下：  

{% codeblock lang:c %}
void x264_predict_16x16_v_c(pixel *src)
{
    pixel4 v0 = MPIXEL_X4( &src[ 0-FDEC_STRIDE] );
    pixel4 v1 = MPIXEL_X4( &src[ 4-FDEC_STRIDE] );
    pixel4 v2 = MPIXEL_X4( &src[ 8-FDEC_STRIDE] );
    pixel4 v3 = MPIXEL_X4( &src[12-FDEC_STRIDE] );

    for( int i = 0; i < 16; i++ )
    {
        MPIXEL_X4( src+ 0 ) = v0;
        MPIXEL_X4( src+ 4 ) = v1;
        MPIXEL_X4( src+ 8 ) = v2;
        MPIXEL_X4( src+12 ) = v3;
        src += FDEC_STRIDE;
    }
}
{% endcodeblock %}

注意，上面代码中的 pixel 为 uint8_t，而 pixel4 为 uint32_t，而 MPIXEL_X4 定义如下：  

```
#define MPIXEL_X4(src) M32(src)  
#deinfe M32(src) (((x264_union32_t *)(src))->i)  
typedef union { uint32_t i; uint16_t b[2]; uint8_t  c[4]; } MAY_ALIAS x264_union32_t;
```

### Intra_16x16_Horizontal 预测模式   

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_16x16 prediction mode shall be used only when the samples p[−1, y] with y = 0..15 are marked as "available
for Intra_16x16 prediction".
The values of the prediction samples predL[ x, y ], with x, y = 0..15, are derived by
predL[ x, y ] = p[ −1, y ], with x, y = 0..15
{% endblockquote %}


