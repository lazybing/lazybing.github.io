---
layout: post
title: "x264源码解析之x264_pixel_init函数"
date: 2017-07-08 22:10:59 -0700
comments: true
categories: x264
---
* list element with functor item
{:toc}

本文主要记录`x264_pixel_init`函数的实现，该函数主要是与像素计算有关的函数，包括SAD、SATD、SSD、SSIM等，它会在打开编码器(x264_encoder_open)时被调用到。  
<!--more-->

## SAD、SATD、SSD等相关知识介绍  

* SAD(Sum of Absolute Difference)= SAE(Sum of Absolute Error)即绝对误差和  
* SATD（Sum of Absolute Transformed Difference）即hadamard变换后再绝对值求和 
* SSD（Sum of Squared Difference）=SSE（Sum of Squared Error)即差值的平方和  
* MAD（Mean Absolute Difference）=MAE（Mean Absolute Error)即平均绝对差值  
* MSD（Mean Squared Difference）=MSE（Mean Squared Error）即平均平方误差  

## X264中的函数实现  

`x264_pixel_init`函数的定义位于 X264 项目中的`common/pixel.c`文件中。定义如下：  

{% codeblock lang:c x264_pixel_init %}
void x264_pixel_init( int cpu, x264_pixel_function_t *pixf )
{
    memset( pixf, 0, sizeof(*pixf) );

#define INIT2_NAME( name1, name2, cpu ) \
    pixf->name1[PIXEL_16x16] = x264_pixel_##name2##_16x16##cpu;\
    pixf->name1[PIXEL_16x8]  = x264_pixel_##name2##_16x8##cpu;
#define INIT4_NAME( name1, name2, cpu ) \
    INIT2_NAME( name1, name2, cpu ) \
    pixf->name1[PIXEL_8x16]  = x264_pixel_##name2##_8x16##cpu;\
    pixf->name1[PIXEL_8x8]   = x264_pixel_##name2##_8x8##cpu;
#define INIT5_NAME( name1, name2, cpu ) \
    INIT4_NAME( name1, name2, cpu ) \
    pixf->name1[PIXEL_8x4]   = x264_pixel_##name2##_8x4##cpu;
#define INIT6_NAME( name1, name2, cpu ) \
    INIT5_NAME( name1, name2, cpu ) \
    pixf->name1[PIXEL_4x8]   = x264_pixel_##name2##_4x8##cpu;
#define INIT7_NAME( name1, name2, cpu ) \
    INIT6_NAME( name1, name2, cpu ) \
    pixf->name1[PIXEL_4x4]   = x264_pixel_##name2##_4x4##cpu;
#define INIT8_NAME( name1, name2, cpu ) \
    INIT7_NAME( name1, name2, cpu ) \
    pixf->name1[PIXEL_4x16]  = x264_pixel_##name2##_4x16##cpu;
#define INIT2( name, cpu ) INIT2_NAME( name, name, cpu )
#define INIT4( name, cpu ) INIT4_NAME( name, name, cpu )
#define INIT5( name, cpu ) INIT5_NAME( name, name, cpu )
#define INIT6( name, cpu ) INIT6_NAME( name, name, cpu )
#define INIT7( name, cpu ) INIT7_NAME( name, name, cpu )
#define INIT8( name, cpu ) INIT8_NAME( name, name, cpu )

#define INIT_ADS( cpu ) \
    pixf->ads[PIXEL_16x16] = x264_pixel_ads4##cpu;\
    pixf->ads[PIXEL_16x8] = x264_pixel_ads2##cpu;\
    pixf->ads[PIXEL_8x8] = x264_pixel_ads1##cpu;

    INIT8( sad, );
    INIT8_NAME( sad_aligned, sad, );
    INIT7( sad_x3, );
    INIT7( sad_x4, );
    INIT8( ssd, );
    INIT8( satd, );
    INIT7( satd_x3, );
    INIT7( satd_x4, );
    INIT4( hadamard_ac, );
    INIT_ADS( );

    pixf->sa8d[PIXEL_16x16] = x264_pixel_sa8d_16x16;
    pixf->sa8d[PIXEL_8x8]   = x264_pixel_sa8d_8x8;
    pixf->var[PIXEL_16x16] = x264_pixel_var_16x16;
    pixf->var[PIXEL_8x16]  = x264_pixel_var_8x16;
    pixf->var[PIXEL_8x8]   = x264_pixel_var_8x8;
    pixf->var2[PIXEL_8x16]  = x264_pixel_var2_8x16;
    pixf->var2[PIXEL_8x8]   = x264_pixel_var2_8x8;

    pixf->ssd_nv12_core = pixel_ssd_nv12_core;
    pixf->ssim_4x4x2_core = ssim_4x4x2_core;
    pixf->ssim_end4 = ssim_end4;
    pixf->vsad = pixel_vsad;
    pixf->asd8 = pixel_asd8;

    pixf->intra_sad_x3_4x4    = x264_intra_sad_x3_4x4;
    pixf->intra_satd_x3_4x4   = x264_intra_satd_x3_4x4;
    pixf->intra_sad_x3_8x8    = x264_intra_sad_x3_8x8;
    pixf->intra_sa8d_x3_8x8   = x264_intra_sa8d_x3_8x8;
    pixf->intra_sad_x3_8x8c   = x264_intra_sad_x3_8x8c;
    pixf->intra_satd_x3_8x8c  = x264_intra_satd_x3_8x8c;
    pixf->intra_sad_x3_8x16c  = x264_intra_sad_x3_8x16c;
    pixf->intra_satd_x3_8x16c = x264_intra_satd_x3_8x16c;
    pixf->intra_sad_x3_16x16  = x264_intra_sad_x3_16x16;
    pixf->intra_satd_x3_16x16 = x264_intra_satd_x3_16x16;
    ...
    //后面是与 CPU 有关的函数定义，此处略去
}
{% endcodeblock %}

下面分别介绍 SAD、SSD、SATD 的实现过程。

### SAD 实现过程  

将上面代码中的`INIT8(sad,)`展开，可以得到如下代码：  

{% codeblock lang:c %}
pixf->sad[PIXEL_16x16] = x264_pixel_sad_16x16;  
pixf->sad[PIXEL_16x8]  = x264_pixel_sad_16x8;  
pixf->sad[PIXEL_8x16]  = x264_pixel_sad_8x16;  
pixf->sad[PIXEL_8x8]   = x264_pixel_sad_8x8;  
pixf->sad[PIXEL_8x4]   = x264_pixel_sad_8x4;  
pixf->sad[PIXEL_4x8]   = x264_pixel_sad_4x8;  
pixf->sad[PIXEL_4x4]   = x264_pixel_sad_4x4;  
pixf->sad[PIXEL_4x16]  = x264_pixel_sad_4x16; 
{% endcodeblock %}

我们选取其中最简单的`x264_pixel_sad_4x4`继续展开，它是通过一个宏来定义的：  

{% codeblock lang:c %}
PIXEL_SAD_C( x264_pixel_sad_4x4,    4,  4 )

#define PIXEL_SAD_C( name, lx, ly ) \
static int name( pixel *pix1, intptr_t i_stride_pix1,  \
                 pixel *pix2, intptr_t i_stride_pix2 ) \
{                                                   \
    int i_sum = 0;                                  \
    for( int y = 0; y < ly; y++ )                   \
    {                                               \
        for( int x = 0; x < lx; x++ )               \
        {                                           \
            i_sum += abs( pix1[x] - pix2[x] );      \
        }                                           \
        pix1 += i_stride_pix1;                      \
        pix2 += i_stride_pix2;                      \
    }                                               \
    return i_sum;                                   \
}
{% endcodeblock %}

展开后，可以得到如下代码：  

{% codeblock lang:c %}
static int x264_pixel_sad_4x4(pixel *pix1, intptr_t i_stride_pix1, pixel *pix2, intptr_t i_stride_pix2)
{
    int i_sum = 0;
    for(int y = 0; y < 4; y++)
    {
        for(int x = 0; x < 4; x++)
        {
            i_sum += abs(pix1[x] - pix2[x]);
        }
        pix1 += i_stride_pix1;
        pix2 += i_stride_pix2;
    }
    return i_sum;
}
{% endcodeblock %}

### SSD 实现过程

将上面代码中的`INIT8(ssd,)`展开，可以得到如下代码：

{% codeblock lang:c %}
pixf->ssd[PIXEL_16x16] = x264_pixel_ssd_16x16;
pixf->ssd[PIXEL_16x8]  = x264_pixel_ssd_16x8;
pixf->ssd[PIXEL_8x16]  = x264_pixel_ssd_8x16;
pixf->ssd[PIXEL_8x8]   = x264_pixel_ssd_8x8;
pixf->ssd[PIXEL_8x4]   = x264_pixel_ssd_8x4;
pixf->ssd[PIXEL_4x8]   = x264_pixel_ssd_4x8;
pixf->ssd[PIXEL_4x4]   = x264_pixel_ssd_4x4;
pixf->ssd[PIXEL_4x16]  = x264_pixel_ssd_4x16;
{% endcodeblock %}

{% codeblock lang:c %}
PIXEL_SSD_C( x264_pixel_ssd_4x4,    4,  4 )

#define PIXEL_SSD_C( name, lx, ly ) \
static int name( pixel *pix1, intptr_t i_stride_pix1,  \
                 pixel *pix2, intptr_t i_stride_pix2 ) \
{                                                   \
    int i_sum = 0;                                  \
    for( int y = 0; y < ly; y++ )                   \
    {                                               \
        for( int x = 0; x < lx; x++ )               \
        {                                           \
            int d = pix1[x] - pix2[x];              \
            i_sum += d*d;                           \
        }                                           \
        pix1 += i_stride_pix1;                      \
        pix2 += i_stride_pix2;                      \
    }                                               \
    return i_sum;                                   \
}
{% endcodeblock %}

此时，可以得到`x264_pixel_ssd_4x4`的定义如下：  

{% codeblock lang:c %}
static int x264_pixel_ssd_4x4(pixel *pix1, intptr_t i_stride_pix1, pixel *pix2, intptr_t i_stride_pix2)
{
    int i_sum = 0;
    for(int y = j; y < 4; y++)
    {
        for(int x = 0; x < 4; x++)
        {
            int d = pix1[x] - pix2[x];
            i_sum += d*d
        } 
        pix1 += i_stride_pix1;
        pix2 += i_stride_pix2;
    }
    return i_sum;
}
{% endcodeblock %}

### SATD 实现过程  

将代码中的`INIT8(satd,)`展开，可以得到如下代码：  

{% codeblock lang:c %}
pixf->satd[PIXEL_16x16] = x264_pixel_satd_16x16;  
pixf->satd[PIXEL_16x8]  = x264_pixel_satd_16x8;   
pixf->satd[PIXEL_8x16]  = x264_pixel_satd_8x16;  
pixf->satd[PIXEL_8x8]   = x264_pixel_satd_8x8;   
pixf->satd[PIXEL_8x4]   = x264_pixel_satd_8x4;   
pixf->satd[PIXEL_4x8]   = x264_pixel_satd_4x8;   
pixf->satd[PIXEL_4x4]   = x264_pixel_satd_4x4;   
pixf->satd[PIXEL_4x16]  = x264_pixel_satd_4x16;
{% endcodeblock %}

同样，选取最简单的`x264_pixel_satd_4x4`继续展开，它的定义如下：  

{% codeblock lang:c %}
static NOINLINE int x264_pixel_satd_4x4( pixel *pix1, intptr_t i_pix1, pixel *pix2, intptr_t i_pix2 )
{
    sum2_t tmp[4][2];
    sum2_t a0, a1, a2, a3, b0, b1;
    sum2_t sum = 0;
    for( int i = 0; i < 4; i++, pix1 += i_pix1, pix2 += i_pix2 )
    {
        a0 = pix1[0] - pix2[0];
        a1 = pix1[1] - pix2[1];
        b0 = (a0+a1) + ((a0-a1)<<BITS_PER_SUM);
        a2 = pix1[2] - pix2[2];
        a3 = pix1[3] - pix2[3];
        b1 = (a2+a3) + ((a2-a3)<<BITS_PER_SUM);
        tmp[i][0] = b0 + b1;
        tmp[i][1] = b0 - b1;
    }
    for( int i = 0; i < 2; i++ )
    {
        HADAMARD4( a0, a1, a2, a3, tmp[0][i], tmp[1][i], tmp[2][i], tmp[3][i] );
        a0 = abs2(a0) + abs2(a1) + abs2(a2) + abs2(a3);
        sum += ((sum_t)a0) + (a0>>BITS_PER_SUM);
    }
    return sum >> 1;
}
{% endcodeblock %}




