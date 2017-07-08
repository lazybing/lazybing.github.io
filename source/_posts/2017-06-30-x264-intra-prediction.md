---
layout: post
title: "x264 源码解析之帧内预测"
date: 2017-06-30 08:12:22 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

本文主要记录 x264 中使用到的帧内预测技术。

<!--more-->

## Intra_4x4 预测模式  

x264 中对 4x4 的预测模式如下：  

| Intra4x4PredMode[luma4x4BlkIdx] | Name of Intra4x4PredMode[luma4x4BlkIdx] |  
| :-----------------------------: | :-------------------------------------: |  
| 0                               | Intra_4x4_Vertical(prediction mode)     |  
| 1                               | Intra_4x4_Horizontal(prediction mode)   |  
| 2                               | Intra_4x4_DC(prediction mode)           |  
| 3                               | Intra_4x4_Diagonal_Down_Left(prediction mode)           |  
| 4                               | Intra_4x4_Diagonal_Down_Right(prediction mode)           |  
| 5                               | Intra_4x4_Vertical_Right(prediction mode)           |  
| 6                               | Intra_4x4_Horizontal_Down(prediction mode)           |  
| 7                               | Intra_4x4_Vertical_Left(prediction mode)           |  
| 8                               | Intra_4x4_Horizontal_Up(prediction mode)           |  

下面依次分析这几种预测模式：  

### Intra_4x4_Vertical 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 0.
This mode shall be used only when the samples p[ x, -1 ] with x = 0..3 are marked as "available for Intra_4x4 prediction".
The values of the prediction samples pred4x4L[ x, y ], with x, y = 0..3, are derived by  
$pred4x4_L[x,y]=p[x,-1], with x,y=0..3$
{% endblockquote %}

x264 中关于模式 Intra_4x4_Vertical 的代码如下：  

{% codeblock lang:c %}
void x264_predict_4x4_v_c( pixel *src )
{
    PREDICT_4x4_DC(SRC_X4(0,-1));
}
#define SRC(x,y) src[(x)+(y)*FDEC_STRIDE]
#define SRC_X4(x,y) MPIXEL_X4( &SRC(x,y) )

#define PREDICT_4x4_DC(v)\
    SRC_X4(0,0) = SRC_X4(0,1) = SRC_X4(0,2) = SRC_X4(0,3) = v;
{% endcodeblock %}

### Intra_4x4_Horizontal 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 1.  
This mode shall be used only when the samples p[ −1, y ], with y = 0..3, are marked as "available for Intra_4x4 prediction".
The values of the prediction samples pred4x4L[ x, y ], with x, y = 0..3, are derived by  
$pred4x4_L[x,y]=p[-1, y], with x,y=0..3$
{% endblockquote %}

x264 中关于模式 Intra_4x4_Vertical 的代码如下：  

{% codeblock lang:c %}
void x264_predict_4x4_h_c( pixel *src )
{
    SRC_X4(0,0) = PIXEL_SPLAT_X4( SRC(-1,0) );
    SRC_X4(0,1) = PIXEL_SPLAT_X4( SRC(-1,1) );
    SRC_X4(0,2) = PIXEL_SPLAT_X4( SRC(-1,2) );
    SRC_X4(0,3) = PIXEL_SPLAT_X4( SRC(-1,3) );
}
{% endcodeblock %}

### Intra_4x4_DC 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 2.
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:  

If all samples p[ x, −1 ], with x = 0..3, and p[ −1, y ], with y = 0..3, are marked as "available for Intra_4x4 prediction", the values of the prediction samples $pred4x4_L$[ x, y ], with x, y = 0..3, are derived by  
$pred4x4_L[x,y]$ = (p[0,-1]+p[1,-1]+p[2,-1]+p[3,-1]+p[-1,0]+p[-1,1]+p[-1,2]+p[-1,3]+4)>>3  

Otherwise, if any samples p[ x, .1 ], with x = 0..3, are marked as "not available for Intra_4x4 prediction" and all samples p[ .1, y ], with y = 0..3, are marked as "available for Intra_4x4 prediction", the values of the prediction samples $pred4x4_L$[ x, y ], with x, y = 0..3, are derived by  
$pred4x4_L[x,y] = (p[-1,0]+p[-1,1]+p[-1,2]+p[-1,3]+2)>>2$  

Otherwise, if any samples p[ .1, y ], with y = 0..3, are marked as "not available for Intra_4x4 prediction" and all samples p[ x, .1 ], with x = 0 .. 3, are marked as "available for Intra_4x4 prediction", the values of the prediction samples $pred4x4_L$[ x, y ], with x, y = 0 .. 3, are derived by    
$pred4x4_L[x,y] = (p[0,-1]+p[1,-1]+p[2,-1]+p[3,-1]+2)>>2$    

Otherwise (some samples p[ x, .1 ], with x = 0..3, and some samples p[ .1, y ], with y = 0..3, are marked as "not available for Intra_4x4 prediction"), the values of the prediction samples $pred4x4_L$[ x, y ], with x, y = 0..3, are derived by  
$pred4x4_L[x,y]=(1<<(BitDepth_Y-1))$
{% endblockquote %}

x264 中关于模式 Intra_4x4_DC 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_4x4_dc_128_c( pixel *src )
{
    PREDICT_4x4_DC( PIXEL_SPLAT_X4( 1 << (BIT_DEPTH-1) ) );
}
static void x264_predict_4x4_dc_left_c( pixel *src )
{
    pixel4 dc = PIXEL_SPLAT_X4( (SRC(-1,0) + SRC(-1,1) + SRC(-1,2) + SRC(-1,3) + 2) >> 2 );
    PREDICT_4x4_DC( dc );
}
static void x264_predict_4x4_dc_top_c( pixel *src )
{
    pixel4 dc = PIXEL_SPLAT_X4( (SRC(0,-1) + SRC(1,-1) + SRC(2,-1) + SRC(3,-1) + 2) >> 2 );
    PREDICT_4x4_DC( dc );
}
void x264_predict_4x4_dc_c( pixel *src )
{
    pixel4 dc = PIXEL_SPLAT_X4( (SRC(-1,0) + SRC(-1,1) + SRC(-1,2) + SRC(-1,3) +
                                 SRC(0,-1) + SRC(1,-1) + SRC(2,-1) + SRC(3,-1) + 4) >> 3 );
    PREDICT_4x4_DC( dc );
}
{% endcodeblock %}

### Intra_4x4_Diagonal_Down_Left 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 3.
This mode shall be used only when the samples p[ x, −1 ] with x = 0..7 are marked as "available for Intra_4x4 prediction".
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:  

If x is equal to 3 and y is equal to 3,
$pred4x4_L[ x, y ] = ( p[ 6, .1 ] + 3 * p[ 7, .1 ] + 2 ) >> 2$

Otherwise (x is not equal to 3 or y is not equal to 3),
$pred4x4_L[ x, y ] = ( p[ x + y, −1 ] + 2 * p[ x + y + 1, −1 ] + p[ x + y + 2, −1 ] + 2 ) >> 2$
{% endblockquote %}

x264 中关于模式 Intra_4x4_DC 的代码如下：  

{% codeblock lang:c %}
#define PREDICT_4x4_LOAD_LEFT\
    int l0 = SRC(-1,0);\
    int l1 = SRC(-1,1);\
    int l2 = SRC(-1,2);\
    UNUSED int l3 = SRC(-1,3);

#define PREDICT_4x4_LOAD_TOP\
    int t0 = SRC(0,-1);\
    int t1 = SRC(1,-1);\
    int t2 = SRC(2,-1);\
    UNUSED int t3 = SRC(3,-1);

#define PREDICT_4x4_LOAD_TOP_RIGHT\
    int t4 = SRC(4,-1);\
    int t5 = SRC(5,-1);\
    int t6 = SRC(6,-1);\
    UNUSED int t7 = SRC(7,-1);

#define F1(a,b)   (((a)+(b)+1)>>1)
#define F2(a,b,c) (((a)+2*(b)+(c)+2)>>2)

static void x264_predict_4x4_ddl_c( pixel *src )
{
    PREDICT_4x4_LOAD_TOP
    PREDICT_4x4_LOAD_TOP_RIGHT
    SRC(0,0)= F2(t0,t1,t2);
    SRC(1,0)=SRC(0,1)= F2(t1,t2,t3);
    SRC(2,0)=SRC(1,1)=SRC(0,2)= F2(t2,t3,t4);
    SRC(3,0)=SRC(2,1)=SRC(1,2)=SRC(0,3)= F2(t3,t4,t5);
    SRC(3,1)=SRC(2,2)=SRC(1,3)= F2(t4,t5,t6);
    SRC(3,2)=SRC(2,3)= F2(t5,t6,t7);
    SRC(3,3)= F2(t6,t7,t7);
}
{% endcodeblock %}

### Intra_4x4_Diagonal_Down_Right 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 4.
This mode shall be used only when the samples p[ x, .1 ] with x = 0..3 and p[ .1, y ] with y = .1..3 are marked as "available for Intra_4x4 prediction".
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:  
If x is greater than y,  
$pred4x4_L[ x, y ] = ( p[ x − y − 2, −1] + 2 * p[ x − y − 1, −1 ] + p[ x − y, −1 ] + 2 ) >> 2$
Otherwise if x is less than y,  
$pred4x4_L[ x, y ] = ( p[ −1, y − x − 2 ] + 2 * p[ −1, y − x − 1 ] + p[ −1, y − x ] + 2 ) >> 2$
Otherwise (x is equal to y),  
$pred4x4_L[ x, y ] = ( p[ 0, .1 ] + 2 * p[ .1, .1 ] + p[ .1, 0 ] + 2 ) >> 2$
{% endblockquote %}

x264 中关于模式 Intra_4x4_Diagonal_Down_Right 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_4x4_ddr_c( pixel *src )
{
    int lt = SRC(-1,-1);
    PREDICT_4x4_LOAD_LEFT
    PREDICT_4x4_LOAD_TOP
    SRC(3,0)= F2(t3,t2,t1);
    SRC(2,0)=SRC(3,1)= F2(t2,t1,t0);
    SRC(1,0)=SRC(2,1)=SRC(3,2)= F2(t1,t0,lt);
    SRC(0,0)=SRC(1,1)=SRC(2,2)=SRC(3,3)= F2(t0,lt,l0);
    SRC(0,1)=SRC(1,2)=SRC(2,3)= F2(lt,l0,l1);
    SRC(0,2)=SRC(1,3)= F2(l0,l1,l2);
    SRC(0,3)= F2(l1,l2,l3);
}
{% endcodeblock %}

### Intra_4x4_Vertical_Right 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 5.
This mode shall be used only when the samples p[ x, −1 ] with x = 0..3 and p[ −1, y ] with y = −1..3 are marked as "available for Intra_4x4 prediction".
Let the variable zVR be set equal to 2 * x − y.
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:  

If zVR is equal to 0,2,4 or 6,  
$pred_L[x,y]=(p[x-(y>>1)-1,-1]+p[x-(y>>1),-1]+1)>>1$  
Otherwise, if zVR is equal to 1, 3, or 5,  
$pred4x4_L[x,y]=(p[x-(y>>1)-2,-1]+2*p[x-(y>>1)-1,-1]+p[x-(y>>1),-1]+2)>>2$
Otherwise, if zVR is equal to −1,  
$pred4x4_L[ x, y ] = (p[-1, 0 ] + 2 * p[ -1, -1 ] + p[ 0, -1 ] + 2 ) >> 2$
Otherwise (zVR is equal to -2 or -3),
$pred4x4_L[ x, y ] = ( p[ −1, y − 1 ] + 2 * p[ −1, y − 2 ] + p[ −1, y − 3 ] + 2 ) >> 2$
{% endblockquote %}

x264 中关于模式 Intra_4x4_Vertical_Right 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_4x4_vr_c( pixel *src )
{
    int lt = SRC(-1,-1);
    PREDICT_4x4_LOAD_LEFT
    PREDICT_4x4_LOAD_TOP
    SRC(0,3)= F2(l2,l1,l0);
    SRC(0,2)= F2(l1,l0,lt);
    SRC(0,1)=SRC(1,3)= F2(l0,lt,t0);
    SRC(0,0)=SRC(1,2)= F1(lt,t0);
    SRC(1,1)=SRC(2,3)= F2(lt,t0,t1);
    SRC(1,0)=SRC(2,2)= F1(t0,t1);
    SRC(2,1)=SRC(3,3)= F2(t0,t1,t2);
    SRC(2,0)=SRC(3,2)= F1(t1,t2);
    SRC(3,1)= F2(t1,t2,t3);
    SRC(3,0)= F1(t2,t3);
}
{% endcodeblock %}

### Intra_4x4_Horizontal_Down 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 6.
This mode shall be used only when the samples p[ x, -1 ] with x = 0..3 and p[ -1, y ] with y = .1..3 are marked as "available for Intra_4x4 prediction".
Let the variable zHD be set equal to 2 * y - x.
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:

{% endblockquote %}

x264 中关于模式 Intra_4x4_Horizontal_Down 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_4x4_hd_c( pixel *src )
{
    int lt= SRC(-1,-1);
    PREDICT_4x4_LOAD_LEFT
    PREDICT_4x4_LOAD_TOP
    SRC(0,3)= F1(l2,l3);
    SRC(1,3)= F2(l1,l2,l3);
    SRC(0,2)=SRC(2,3)= F1(l1,l2);
    SRC(1,2)=SRC(3,3)= F2(l0,l1,l2);
    SRC(0,1)=SRC(2,2)= F1(l0,l1);
    SRC(1,1)=SRC(3,2)= F2(lt,l0,l1);
    SRC(0,0)=SRC(2,1)= F1(lt,l0);
    SRC(1,0)=SRC(3,1)= F2(t0,lt,l0);
    SRC(2,0)= F2(t1,t0,lt);
    SRC(3,0)= F2(t2,t1,t0);
}
{% endcodeblock %}

### Intra_4x4_Vertical_Left 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 7.
This mode shall be used only when the samples p[ x, −1 ] with x = 0..7 are marked as "available for Intra_4x4 prediction".
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:
{% endblockquote %}

x264 中关于模式 Intra_4x4_Vertical_Left 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_4x4_vl_c( pixel *src )
{
    PREDICT_4x4_LOAD_TOP
    PREDICT_4x4_LOAD_TOP_RIGHT
    SRC(0,0)= F1(t0,t1);
    SRC(0,1)= F2(t0,t1,t2);
    SRC(1,0)=SRC(0,2)= F1(t1,t2);
    SRC(1,1)=SRC(0,3)= F2(t1,t2,t3);
    SRC(2,0)=SRC(1,2)= F1(t2,t3);
    SRC(2,1)=SRC(1,3)= F2(t2,t3,t4);
    SRC(3,0)=SRC(2,2)= F1(t3,t4);
    SRC(3,1)=SRC(2,3)= F2(t3,t4,t5);
    SRC(3,2)= F1(t4,t5);
    SRC(3,3)= F2(t4,t5,t6);
}
{% endcodeblock %}

### Intra_4x4_Horizontal_Up 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_4x4 prediction mode is invoked when Intra4x4PredMode[ luma4x4BlkIdx ] is equal to 8.
This mode shall be used only when the samples p[ −1, y ] with y = 0..3 are marked as "available for Intra_4x4 prediction".
Let the variable zHU be set equal to x + 2 * y.
The values of the prediction samples $pred4x4_L[ x, y ]$, with x, y = 0..3, are derived as follows:

{% endblockquote %}

x264 中关于模式 Intra_4x4_Horizontal_Up 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_4x4_hu_c( pixel *src )
{
    PREDICT_4x4_LOAD_LEFT
    SRC(0,0)= F1(l0,l1);
    SRC(1,0)= F2(l0,l1,l2);
    SRC(2,0)=SRC(0,1)= F1(l1,l2);
    SRC(3,0)=SRC(1,1)= F2(l1,l2,l3);
    SRC(2,1)=SRC(0,2)= F1(l2,l3);
    SRC(3,1)=SRC(1,2)= F2(l2,l3,l3);
    SRC(3,2)=SRC(1,3)=SRC(0,3)=
    SRC(2,2)=SRC(2,3)=SRC(3,3)= l3;
}
{% endcodeblock %}

## Intra_8x8 预测模式  

x264 中对 8x8 的预测模式如下：  

| intra8x8Predmodei[luma8x8BlkIdx] | Name of Intra8x8PredMode[luma8x8BlkIdx] |
| :------------------------------: | :-------------------------------------: |
| 0  | Intra_8x8_Vertical(prediction mode) |
| 1  | Intra_8x8_Horizontal(prediction mode) |
| 2  | Intra_8x8_DC(prediction mode) |
| 3  | Intra_8x8_Diagonal_Down_Left(prediction mode) |
| 4  | Intra_8x8_Diagonal_Down_Right(prediction mode) |
| 5  | Intra_8x8_Vertical_Right(prediction mode) |
| 6  | Intra_8x8_Horizontal_Down(prediction mode) |
| 7  | Intra_8x8_Vertical_Left(prediction mode) |
| 8  | Intra_8x8_Horizontal_Up(prediction mode) |  

下面依次分析这几种预测模式：  

### Intra_8x8_Vertical 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 0.
This mode shall be used only when the samples p[ x, -1 ] with x = 0..7 are marked as "available for Intra_8x8 prediction".
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived by   
$pred8x8_L[x,y]=p'[x,-1],with x,y=0..7$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Vertical 的代码如下：  

{% codeblock lang:c %}
void x264_predict_8x8_v_c( pixel *src, pixel edge[36] )
{
    pixel4 top[2] = { MPIXEL_X4( edge+16 ),
                      MPIXEL_X4( edge+20 ) };
    for( int y = 0; y < 8; y++ )
    {
        MPIXEL_X4( src+y*FDEC_STRIDE+0 ) = top[0];
        MPIXEL_X4( src+y*FDEC_STRIDE+4 ) = top[1];
    }
}
{% endcodeblock %}

### Intra_8x8_Horizontal 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 1.
This mode shall be used only when the samples p[ −1, y ], with y = 0..7, are marked as "available for Intra_8x8 prediction".
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived by  
$pred8x8_L[x,y]=p'[-1,y], with x,y=0..7$
{% endblockquote %}

x264 中对 Intra_8x8_Horizontal 的代码如下：  

{% codeblock lang:c %}
#define PL(y) \
    UNUSED int l##y = edge[14-y];
#define PT(x) \
    UNUSED int t##x = edge[16+x];
#define PREDICT_8x8_LOAD_TOPLEFT \
    int lt = edge[15];
#define PREDICT_8x8_LOAD_LEFT \
    PL(0) PL(1) PL(2) PL(3) PL(4) PL(5) PL(6) PL(7)
#define PREDICT_8x8_LOAD_TOP \
    PT(0) PT(1) PT(2) PT(3) PT(4) PT(5) PT(6) PT(7)
#define PREDICT_8x8_LOAD_TOPRIGHT \
    PT(8) PT(9) PT(10) PT(11) PT(12) PT(13) PT(14) PT(15)

#define PREDICT_8x8_DC(v) \
    for( int y = 0; y < 8; y++ ) { \
        MPIXEL_X4( src+0 ) = v; \
        MPIXEL_X4( src+4 ) = v; \
        src += FDEC_STRIDE; \
    }

void x264_predict_8x8_h_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_LEFT
#define ROW(y) MPIXEL_X4( src+y*FDEC_STRIDE+0 ) =\
               MPIXEL_X4( src+y*FDEC_STRIDE+4 ) = PIXEL_SPLAT_X4( l##y );
    ROW(0); ROW(1); ROW(2); ROW(3); ROW(4); ROW(5); ROW(6); ROW(7);
#undef ROW
}
{% endcodeblock %}

### Intra_8x8_DC 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 2.
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:
{% endblockquote %}

x264 中对 Intra_8x8_DC 模式的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_dc_128_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_DC( PIXEL_SPLAT_X4( 1 << (BIT_DEPTH-1) ) );
}
static void x264_predict_8x8_dc_left_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_LEFT
    pixel4 dc = PIXEL_SPLAT_X4( (l0+l1+l2+l3+l4+l5+l6+l7+4) >> 3 );
    PREDICT_8x8_DC( dc );
}
static void x264_predict_8x8_dc_top_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_TOP
    pixel4 dc = PIXEL_SPLAT_X4( (t0+t1+t2+t3+t4+t5+t6+t7+4) >> 3 );
    PREDICT_8x8_DC( dc );
}
void x264_predict_8x8_dc_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_LEFT
    PREDICT_8x8_LOAD_TOP
    pixel4 dc = PIXEL_SPLAT_X4( (l0+l1+l2+l3+l4+l5+l6+l7+t0+t1+t2+t3+t4+t5+t6+t7+8) >> 4 );
    PREDICT_8x8_DC( dc );
}
{% endcodeblock %}

### Intra_8x8_Diagonal_Down_Left 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 3.
This mode shall be used only when the samples p[ x, −1 ] with x = 0..15 are marked as "available for Intra_8x8 prediction".
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:  
If x is equal to 7 and y is equal to 7,  
$pred8xx_L[x,y]=( p′[ 14, −1 ] + 3 * p′[ 15, −1 ] + 2 ) >> 2$
Otherwise (x is not equal to 7 or y is not equal to 7)  
$pred8x8_L[ x, y ] = ( p′[ x + y, −1 ] + 2 * p′[ x + y + 1, −1 ] + p′[ x + y + 2, −1 ] + 2 ) >> 2$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Diagonal_Down_Left 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_ddl_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_TOP
    PREDICT_8x8_LOAD_TOPRIGHT
    SRC(0,0)= F2(t0,t1,t2);
    SRC(0,1)=SRC(1,0)= F2(t1,t2,t3);
    SRC(0,2)=SRC(1,1)=SRC(2,0)= F2(t2,t3,t4);
    SRC(0,3)=SRC(1,2)=SRC(2,1)=SRC(3,0)= F2(t3,t4,t5);
    SRC(0,4)=SRC(1,3)=SRC(2,2)=SRC(3,1)=SRC(4,0)= F2(t4,t5,t6);
    SRC(0,5)=SRC(1,4)=SRC(2,3)=SRC(3,2)=SRC(4,1)=SRC(5,0)= F2(t5,t6,t7);
    SRC(0,6)=SRC(1,5)=SRC(2,4)=SRC(3,3)=SRC(4,2)=SRC(5,1)=SRC(6,0)= F2(t6,t7,t8);
    SRC(0,7)=SRC(1,6)=SRC(2,5)=SRC(3,4)=SRC(4,3)=SRC(5,2)=SRC(6,1)=SRC(7,0)= F2(t7,t8,t9);
    SRC(1,7)=SRC(2,6)=SRC(3,5)=SRC(4,4)=SRC(5,3)=SRC(6,2)=SRC(7,1)= F2(t8,t9,t10);
    SRC(2,7)=SRC(3,6)=SRC(4,5)=SRC(5,4)=SRC(6,3)=SRC(7,2)= F2(t9,t10,t11);
    SRC(3,7)=SRC(4,6)=SRC(5,5)=SRC(6,4)=SRC(7,3)= F2(t10,t11,t12);
    SRC(4,7)=SRC(5,6)=SRC(6,5)=SRC(7,4)= F2(t11,t12,t13);
    SRC(5,7)=SRC(6,6)=SRC(7,5)= F2(t12,t13,t14);
    SRC(6,7)=SRC(7,6)= F2(t13,t14,t15);
    SRC(7,7)= F2(t14,t15,t15);
}
{% endcodeblock %}

### Intra_8x8_Diagonal_Down_Right 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 4.
This mode shall be used only when the samples p[ x, .1 ] with x = 0..7 and p[ .1, y ] with y = .1..7 are marked as
"available for Intra_8x8 prediction".
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:  
If x is greater than y,
$pred8x8_L[ x, y ] = ( p′[ x − y − 2, −1] + 2 * p′[ x − y − 1, −1 ] + p′[ x − y, −1 ] + 2 ) >> 2$
Otherwise if x is less than y,
$pred8x8_L[ x, y ] = ( p′[ .1, y . x . 2 ] + 2 * p′[ .1, y . x . 1 ] + p′[ .1, y . x ] + 2 ) >> 2$
Otherwise (x is equal to y),
$pred8x8_L[ x, y ] = ( p′[ 0, −1 ] + 2 * p′[ −1, −1 ] + p′[ −1, 0 ] + 2 ) >> 2$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Diagonal_Down_Right 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_ddr_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_TOP
    PREDICT_8x8_LOAD_LEFT
    PREDICT_8x8_LOAD_TOPLEFT
    SRC(0,7)= F2(l7,l6,l5);
    SRC(0,6)=SRC(1,7)= F2(l6,l5,l4);
    SRC(0,5)=SRC(1,6)=SRC(2,7)= F2(l5,l4,l3);
    SRC(0,4)=SRC(1,5)=SRC(2,6)=SRC(3,7)= F2(l4,l3,l2);
    SRC(0,3)=SRC(1,4)=SRC(2,5)=SRC(3,6)=SRC(4,7)= F2(l3,l2,l1);
    SRC(0,2)=SRC(1,3)=SRC(2,4)=SRC(3,5)=SRC(4,6)=SRC(5,7)= F2(l2,l1,l0);
    SRC(0,1)=SRC(1,2)=SRC(2,3)=SRC(3,4)=SRC(4,5)=SRC(5,6)=SRC(6,7)= F2(l1,l0,lt);
    SRC(0,0)=SRC(1,1)=SRC(2,2)=SRC(3,3)=SRC(4,4)=SRC(5,5)=SRC(6,6)=SRC(7,7)= F2(l0,lt,t0);
    SRC(1,0)=SRC(2,1)=SRC(3,2)=SRC(4,3)=SRC(5,4)=SRC(6,5)=SRC(7,6)= F2(lt,t0,t1);
    SRC(2,0)=SRC(3,1)=SRC(4,2)=SRC(5,3)=SRC(6,4)=SRC(7,5)= F2(t0,t1,t2);
    SRC(3,0)=SRC(4,1)=SRC(5,2)=SRC(6,3)=SRC(7,4)= F2(t1,t2,t3);
    SRC(4,0)=SRC(5,1)=SRC(6,2)=SRC(7,3)= F2(t2,t3,t4);
    SRC(5,0)=SRC(6,1)=SRC(7,2)= F2(t3,t4,t5);
    SRC(6,0)=SRC(7,1)= F2(t4,t5,t6);
    SRC(7,0)= F2(t5,t6,t7);

}
{% endcodeblock %}

### Intra_8x8_Vertical_Right 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 5.
This mode shall be used only when the samples p[ x, -1 ] with x = 0..7 and p[ -1, y ] with y = -1..7 are marked as "available for Intra_8x8 prediction".
Let the variable zVR be set equal to 2 * x . y.
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:  
If zVR is equal to 0, 2, 4, 6, 8, 10, 12, or 14  
$pred8x8_L[x,y] = (p'[x-y(y>>1)-1,-1] + p'[x-(y>>1),-1]+1)>>1$  
Otherwise, if zVR is equal to 1, 3, 5, 7, 9, 11, or 13  
$pred8x8_L[x,y]=(p'[x-(y>>1)-2,-1]+2*p'[x-(y>>1)-1,-1]+p'[x-(y>>1),-1]+2)>>2$  
Otherwise, if zVR is equal to −1,  
$pred8x8_L[ x, y ] = ( p′[ −1, 0 ] + 2 * p′[ −1, −1 ] + p′[ 0, −1 ] + 2 ) >> 2$  
Otherwise (zVR is equal to .2, .3, .4, .5, .6, or .7),  
$pred8x8_L[ x, y ] = ( p′[ -1, y . 2*x - 1 ] + 2 * p′[ -1, y - 2*x - 2 ] + p′[ -1, y - 2*x - 3 ] + 2 ) >> 2$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Vertical_Right 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_vr_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_TOP
    PREDICT_8x8_LOAD_LEFT
    PREDICT_8x8_LOAD_TOPLEFT
    SRC(0,6)= F2(l5,l4,l3);
    SRC(0,7)= F2(l6,l5,l4);
    SRC(0,4)=SRC(1,6)= F2(l3,l2,l1);
    SRC(0,5)=SRC(1,7)= F2(l4,l3,l2);
    SRC(0,2)=SRC(1,4)=SRC(2,6)= F2(l1,l0,lt);
    SRC(0,3)=SRC(1,5)=SRC(2,7)= F2(l2,l1,l0);
    SRC(0,1)=SRC(1,3)=SRC(2,5)=SRC(3,7)= F2(l0,lt,t0);
    SRC(0,0)=SRC(1,2)=SRC(2,4)=SRC(3,6)= F1(lt,t0);
    SRC(1,1)=SRC(2,3)=SRC(3,5)=SRC(4,7)= F2(lt,t0,t1);
    SRC(1,0)=SRC(2,2)=SRC(3,4)=SRC(4,6)= F1(t0,t1);
    SRC(2,1)=SRC(3,3)=SRC(4,5)=SRC(5,7)= F2(t0,t1,t2);
    SRC(2,0)=SRC(3,2)=SRC(4,4)=SRC(5,6)= F1(t1,t2);
    SRC(3,1)=SRC(4,3)=SRC(5,5)=SRC(6,7)= F2(t1,t2,t3);
    SRC(3,0)=SRC(4,2)=SRC(5,4)=SRC(6,6)= F1(t2,t3);
    SRC(4,1)=SRC(5,3)=SRC(6,5)=SRC(7,7)= F2(t2,t3,t4);
    SRC(4,0)=SRC(5,2)=SRC(6,4)=SRC(7,6)= F1(t3,t4);
    SRC(5,1)=SRC(6,3)=SRC(7,5)= F2(t3,t4,t5);
    SRC(5,0)=SRC(6,2)=SRC(7,4)= F1(t4,t5);
    SRC(6,1)=SRC(7,3)= F2(t4,t5,t6);
    SRC(6,0)=SRC(7,2)= F1(t5,t6);
    SRC(7,1)= F2(t5,t6,t7);
    SRC(7,0)= F1(t6,t7);
}
{% endcodeblock %}

### Intra_8x8_Horizontal_Down 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 6.
This mode shall be used only when the samples p[ x, −1 ] with x = 0..7 and p[ −1, y ] with y = −1..7 are marked as "available for Intra_8x8 prediction".
Let the variable zHD be set equal to 2 * y − x.
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:  
If zHD is equal to 0, 2, 4, 6, 8, 10, 12, or 14  
$pred8x8_L[ x, y ] = ( p′[ −1, y − ( x >> 1 ) − 1 ] + p′[ −1, y − ( x >> 1 ) ] + 1 ) >> 1$  
Otherwise, if zHD is equal to 1, 3, 5, 7, 9, 11, or 13  
$pred8x8_L[x,y]=(p′[-1, y -(x>>1)-2]+2*p′[-1,y-(x>>1)-1]+p′[-1,y-(x>>1)]+2)>>2$
Otherwise, if zHD is equal to −1,
$pred8x8L[ x, y ] = ( p′[ −1, 0 ] + 2 * p′[ −1, −1 ] + p′[ 0, −1 ] + 2 ) >> 2$
Otherwise (zHD is equal to −2, −3, −4, −5, −6, −7),
$pred8x8L[ x, y ] = ( p′[ x − 2*y − 1, −1 ] + 2 * p′[ x − 2*y − 2, −1 ] + p′[ x − 2*y − 3, −1 ] + 2 ) >> 2$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Horizontal_Down 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_hd_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_TOP
    PREDICT_8x8_LOAD_LEFT
    PREDICT_8x8_LOAD_TOPLEFT
    int p1 = pack_pixel_1to2(F1(l6,l7), F2(l5,l6,l7));
    int p2 = pack_pixel_1to2(F1(l5,l6), F2(l4,l5,l6));
    int p3 = pack_pixel_1to2(F1(l4,l5), F2(l3,l4,l5));
    int p4 = pack_pixel_1to2(F1(l3,l4), F2(l2,l3,l4));
    int p5 = pack_pixel_1to2(F1(l2,l3), F2(l1,l2,l3));
    int p6 = pack_pixel_1to2(F1(l1,l2), F2(l0,l1,l2));
    int p7 = pack_pixel_1to2(F1(l0,l1), F2(lt,l0,l1));
    int p8 = pack_pixel_1to2(F1(lt,l0), F2(l0,lt,t0));
    int p9 = pack_pixel_1to2(F2(t1,t0,lt), F2(t2,t1,t0));
    int p10 = pack_pixel_1to2(F2(t3,t2,t1), F2(t4,t3,t2));
    int p11 = pack_pixel_1to2(F2(t5,t4,t3), F2(t6,t5,t4));
    SRC_X4(0,7)= pack_pixel_2to4(p1,p2);
    SRC_X4(0,6)= pack_pixel_2to4(p2,p3);
    SRC_X4(4,7)=SRC_X4(0,5)= pack_pixel_2to4(p3,p4);
    SRC_X4(4,6)=SRC_X4(0,4)= pack_pixel_2to4(p4,p5);
    SRC_X4(4,5)=SRC_X4(0,3)= pack_pixel_2to4(p5,p6);
    SRC_X4(4,4)=SRC_X4(0,2)= pack_pixel_2to4(p6,p7);
    SRC_X4(4,3)=SRC_X4(0,1)= pack_pixel_2to4(p7,p8);
    SRC_X4(4,2)=SRC_X4(0,0)= pack_pixel_2to4(p8,p9);
    SRC_X4(4,1)= pack_pixel_2to4(p9,p10);
    SRC_X4(4,0)= pack_pixel_2to4(p10,p11);
}
{% endcodeblock %}

### Intra_8x8_Vertical_Left 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 7.
This mode shall be used only when the samples p[ x, −1 ] with x = 0..15 are marked as "available for Intra_8x8 prediction".
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:  
If y is equal to 0, 2, 4 or 6  
$pred8x8_L[ x, y ] = ( p′[ x + ( y >> 1 ), .1 ] + p′[ x + ( y >> 1 ) + 1, .1 ] + 1) >> 1$  
Otherwise (y is equal to 1, 3, 5, 7),  
$pred8x8_L[ x, y ] = ( p′[ x + ( y >> 1 ), −1 ] + 2 * p′[ x + ( y >> 1 ) + 1, −1 ] + p′[ x + ( y >> 1 ) + 2, −1 ] + 2 ) >>2$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Horizontal_Down 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_vl_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_TOP
    PREDICT_8x8_LOAD_TOPRIGHT
    SRC(0,0)= F1(t0,t1);
    SRC(0,1)= F2(t0,t1,t2);
    SRC(0,2)=SRC(1,0)= F1(t1,t2);
    SRC(0,3)=SRC(1,1)= F2(t1,t2,t3);
    SRC(0,4)=SRC(1,2)=SRC(2,0)= F1(t2,t3);
    SRC(0,5)=SRC(1,3)=SRC(2,1)= F2(t2,t3,t4);
    SRC(0,6)=SRC(1,4)=SRC(2,2)=SRC(3,0)= F1(t3,t4);
    SRC(0,7)=SRC(1,5)=SRC(2,3)=SRC(3,1)= F2(t3,t4,t5);
    SRC(1,6)=SRC(2,4)=SRC(3,2)=SRC(4,0)= F1(t4,t5);
    SRC(1,7)=SRC(2,5)=SRC(3,3)=SRC(4,1)= F2(t4,t5,t6);
    SRC(2,6)=SRC(3,4)=SRC(4,2)=SRC(5,0)= F1(t5,t6);
    SRC(2,7)=SRC(3,5)=SRC(4,3)=SRC(5,1)= F2(t5,t6,t7);
    SRC(3,6)=SRC(4,4)=SRC(5,2)=SRC(6,0)= F1(t6,t7);
    SRC(3,7)=SRC(4,5)=SRC(5,3)=SRC(6,1)= F2(t6,t7,t8);
    SRC(4,6)=SRC(5,4)=SRC(6,2)=SRC(7,0)= F1(t7,t8);
    SRC(4,7)=SRC(5,5)=SRC(6,3)=SRC(7,1)= F2(t7,t8,t9);
    SRC(5,6)=SRC(6,4)=SRC(7,2)= F1(t8,t9);
    SRC(5,7)=SRC(6,5)=SRC(7,3)= F2(t8,t9,t10);
    SRC(6,6)=SRC(7,4)= F1(t9,t10);
    SRC(6,7)=SRC(7,5)= F2(t9,t10,t11);
    SRC(7,6)= F1(t10,t11);
    SRC(7,7)= F2(t10,t11,t12);
}
{% endcodeblock %}

### Intra_8x8_Horizontal_Up 预测模式  

在SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_8x8 prediction mode is invoked when Intra8x8PredMode[ luma8x8BlkIdx ] is equal to 8.
This mode shall be used only when the samples p[ -1, y ] with y = 0..7 are marked as "available for Intra_8x8 prediction".
Let the variable zHU be set equal to x + 2 * y.
The values of the prediction samples $pred8x8_L[ x, y ]$, with x, y = 0..7, are derived as follows:  
If zHU is equal to 0, 2, 4, 6, 8, 10, or 12  
$pred8x8_L[ x, y ] = ( p′[ −1, y + ( x >> 1 ) ] + p′[ −1, y + ( x >> 1 ) + 1 ] + 1 ) >> 1$
Otherwise, if zHU is equal to 1, 3, 5, 7, 9, or 11  
$pred8x8_L[ x, y ] = ( p′[ −1, y + ( x >> 1 ) ] + 2 * p′[ −1, y + ( x >> 1 ) + 1 ] + p′[ −1, y + ( x >> 1 ) + 2 ] + 2 ) >>2$
Otherwise, if zHU is equal to 13,  
$pred8x8_L[ x, y ] = ( p′[ −1, 6 ] + 3 * p′[ −1, 7 ] + 2 ) >> 2$  
Otherwise (zHU is greater than 13),  
$pred8x8_L[x,y]=p'[-1,7]$
{% endblockquote %}

X264 中关于模式 Intra_8x8_Horizontal_Up 的代码如下：  

{% codeblock lang:c %}
static void x264_predict_8x8_hu_c( pixel *src, pixel edge[36] )
{
    PREDICT_8x8_LOAD_LEFT
    int p1 = pack_pixel_1to2(F1(l0,l1), F2(l0,l1,l2));
    int p2 = pack_pixel_1to2(F1(l1,l2), F2(l1,l2,l3));
    int p3 = pack_pixel_1to2(F1(l2,l3), F2(l2,l3,l4));
    int p4 = pack_pixel_1to2(F1(l3,l4), F2(l3,l4,l5));
    int p5 = pack_pixel_1to2(F1(l4,l5), F2(l4,l5,l6));
    int p6 = pack_pixel_1to2(F1(l5,l6), F2(l5,l6,l7));
    int p7 = pack_pixel_1to2(F1(l6,l7), F2(l6,l7,l7));
    int p8 = pack_pixel_1to2(l7,l7);
    SRC_X4(0,0)= pack_pixel_2to4(p1,p2);
    SRC_X4(0,1)= pack_pixel_2to4(p2,p3);
    SRC_X4(4,0)=SRC_X4(0,2)= pack_pixel_2to4(p3,p4);
    SRC_X4(4,1)=SRC_X4(0,3)= pack_pixel_2to4(p4,p5);
    SRC_X4(4,2)=SRC_X4(0,4)= pack_pixel_2to4(p5,p6);
    SRC_X4(4,3)=SRC_X4(0,5)= pack_pixel_2to4(p6,p7);
    SRC_X4(4,4)=SRC_X4(0,6)= pack_pixel_2to4(p7,p8);
    SRC_X4(4,5)=SRC_X4(4,6)= SRC_X4(0,7) = SRC_X4(4,7) = pack_pixel_2to4(p8,p8);
}
{% endcodeblock %}

## Intra_16x16 预测模式


x264 中对 16x16 的预测模式如下：  

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


x264 中关于模式 Horizontal 的代码如下：  

{% codeblock lang:c %}
void x264_predict_16x16_h_c( pixel *src )
{
    for( int i = 0; i < 16; i++ )
    {
        const pixel4 v = PIXEL_SPLAT_X4( src[-1] );
        MPIXEL_X4( src+ 0 ) = v;
        MPIXEL_X4( src+ 4 ) = v;
        MPIXEL_X4( src+ 8 ) = v;
        MPIXEL_X4( src+12 ) = v;
        src += FDEC_STRIDE;
    }
}
{% endcodeblock %}

其中`PIXEL_SPLAT_X4`定义如下：  

```
#   define PIXEL_SPLAT_X4(x) ((x)*0x01010101U)
```

### Intra_16x16_DC 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_16x16 prediction mode operates, depending on whether the neighbouring samples are marked as "available for
Intra_16x16 prediction", as follows:  

If all neighbouring samples p[x,-1] ], with x = 0..15, and p[ −1, y ], with y = 0..15, are marked as "available for
Intra_16x16 prediction", the prediction for all luma samples in the macroblock is given by:  
$pred_L[x,y]=(\sum_{x'=0}^{15}p[x',-1]+\sum_{y'=0}^{15}p[-1,y']+16)>>5, with x,y=0..15$  

Otherwise, if any of the neighbouring samples p[ x, .1 ], with x = 0..15, are marked as "not available for Intra_16x16
prediction" and all of the neighbouring samples p[ .1, y ], with y = 0..15, are marked as "available for Intra_16x16
prediction", the prediction for all luma samples in the macroblock is given by:  
$pred_L[x,y]=(\sum_{y'=0}^{15}p[-1,y']+8)>>4, with x,y=0..15$   

Otherwise, if any of the neighbouring samples p[ −1, y ], with y = 0..15, are marked as "not available for Intra_16x16
prediction" and all of the neighbouring samples p[ x, −1 ], with x = 0..15, are marked as "available for Intra_16x16
prediction", the prediction for all luma samples in the macroblock is given by:  
$pred_L[x,y]=(\sum_{x'=0}^{15}p[x',-1]+8)>>4, with x,y=0..15$   

Otherwise (some of the neighbouring samples p[ x, .1 ], with x = 0..15, and some of the neighbouring samples
p[ .1, y ], with y = 0..15, are marked as "not available for Intra_16x16 prediction"), the prediction for all luma samples
in the macroblock is given by:  
$pred_L[x,y]=(1<<(BitDepth_Y - 1)), with x,y=0..15$
{% endblockquote %}

x264 中关于模式 DC 的代码如下：  

{% codeblock lang:c %}
#define PREDICT_16x16_DC(v)\
    for( int i = 0; i < 16; i++ )\
    {\
        MPIXEL_X4( src+ 0 ) = v;\
        MPIXEL_X4( src+ 4 ) = v;\
        MPIXEL_X4( src+ 8 ) = v;\
        MPIXEL_X4( src+12 ) = v;\
        src += FDEC_STRIDE;\
    }

void x264_predict_16x16_dc_c( pixel *src )
{
    int dc = 0;

    for( int i = 0; i < 16; i++ )
    {
        dc += src[-1 + i * FDEC_STRIDE];
        dc += src[i - FDEC_STRIDE];
    }
    pixel4 dcsplat = PIXEL_SPLAT_X4( ( dc + 16 ) >> 5 );

    PREDICT_16x16_DC( dcsplat );
}
{% endcodeblock %}


### Intra_16x16_Plane 预测模式  

在 SPEC 中，关于该预测模式的定义如下：  

{% blockquote %}
This Intra_16x16 prediction mode shall be used only when the samples p[ x, .1 ] with x = .1..15 and p[ .1, y ] with y = 0..15 are marked as "available for Intra_16x16 prediction".  
The values of the prediction samples $pred_L[x,y]$,with x,y=0...15, are derived by  
$pred_L[x,y]=Clip1_Y((a+b*(x-7)+c*(y-7)+16)>>5)$,with x,y=0...15, where   
$a = 16 * ( p[ .1, 15 ] + p[ 15, .1 ] )$   
$b = ( 5 * H + 32 ) >> 6$   
$c = ( 5 * V + 32 ) >> 6$     
and H and V are specified as   
$H=\sum_{x'=0}^{7}(x'+1)*(p[8+x',-1]-p[6-x',-1])$    
$V=\sum_{y'=0}^{7}(y'+1)*(p[-1,8+y']-p[-1,6-y'])$    
{% endblockquote %}

x264 中关于模式 Plane 的代码如下：  

{% codeblock lang:c %}
void x264_predict_16x16_p_c( pixel *src )
{
    int H = 0, V = 0;

    /* calculate H and V */
    for( int i = 0; i <= 7; i++ )
    {
        H += ( i + 1 ) * ( src[ 8 + i - FDEC_STRIDE ] - src[6 -i -FDEC_STRIDE] );
        V += ( i + 1 ) * ( src[-1 + (8+i)*FDEC_STRIDE] - src[-1 + (6-i)*FDEC_STRIDE] );
    }

    int a = 16 * ( src[-1 + 15*FDEC_STRIDE] + src[15 - FDEC_STRIDE] );
    int b = ( 5 * H + 32 ) >> 6;
    int c = ( 5 * V + 32 ) >> 6;

    int i00 = a - b * 7 - c * 7 + 16;

    for( int y = 0; y < 16; y++ )
    {
        int pix = i00;
        for( int x = 0; x < 16; x++ )
        {
            src[x] = x264_clip_pixel( pix>>5 );
            pix += b;
        }
        src += FDEC_STRIDE;
        i00 += c;
    }
}

static ALWAYS_INLINE pixel x264_clip_pixel( int x )
{
    return ( (x & ~PIXEL_MAX) ? (-x)>>31 & PIXEL_MAX : x );
}
{% endcodeblock %}
