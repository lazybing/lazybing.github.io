---
layout: post
title: "x264 实现yuv转264文件"
date: 2017-06-16 07:47:47 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

本文根据 x264 中提供的`example.c`文件，实现了将 YUV 文件编码为 264 文件，从整体上了解 x264 编码的大体过程。  

<!--more-->

x264 实现编码器功能与 FFmpeg 实现编码器大致是类似的，因为 FFmpeg 本身实现 264 格式的编码，就是 x264 的库实现的。

首先分析 x264 给定的编码样例，之后根据样例实现自己的编码器功能。

## X264编码样例解析

在 X264 中有`example.c`文件，它是 X264 库给定的一个将 YUV 编码为 h264 格式的视频文件的样例。分析其中的源码大致如下：  

1. 检测输入的参数格式是否正确。
2. 获取编码过程中需要用到的参数，并对特定的参数进行赋值。
3. 根据给定的视频的宽高等信息为图像结构体 `x264_picture_t` 分配内存。
4. 打开编码器
5. 从给定的的待编码的 YUV 文件中读取数据，放到上面分配的 `x264_picture_t` 结构体的特定字段内。
6. 编码一帧图像。
7. 将编码生成的 h264 格式的视频数据写到输出文件中。
8. 循环5、6、7，实现多帧数据的编码。
9. 将编码器内缓存的数据编码完成，并写到输出文件中。
10. 清理工作，包括关掉编码器、释放的分配的 `x264_picture_t` 结构体。

第一步中，检测输入参数格式是否正确，X264 中给出的具体实现如下：  

{% codeblock lang:c %}
FAIL_IF_ERROR( !(argc > 1), "Example usage: example 352x288 <input.yuv >output.h264\n" );  
FAIL_IF_ERROR( 2 != sscanf( argv[1], "%dx%d", &width, &height ), "resolution not specified or incorrect\n" );
{% endcodeblock %}
其中`FAIL_IF_ERROR`定义如下：  
```
#define FAIL_IF_ERROR( cond, ... )\
do\
{\
    if( cond )\
    {\
        fprintf( stderr, __VA_ARGS__ );\
        goto fail;\
    }\
} while( 0 )
```

第二步中，获取编码过程中需要用到的参数，并对特定的参数进行赋值。样例的实现中主要包括了三部分,代码如下：

{% codeblock lang:c %}
//Get default params for preset/tuning
if( x264_param_default_preset( &param, "medium", NULL ) < 0 )
    goto fail;

/* Configure non-default params */
param.i_csp = X264_CSP_I420;
param.i_width  = width;
param.i_height = height;
param.b_vfr_input = 0;
param.b_repeat_headers = 1;
param.b_annexb = 1;

/* Apply profile restrictions. */
if( x264_param_apply_profile( &param, "high" ) < 0 )
    goto fail;
{% endcodeblock %}

其中对于`preset``tune``profile`参数的选择部分，请参考上一篇中的[X264参数详解](http://lazybing.github.io/blog/2017/06/23/x264-paraments-illustra/#section-1)。  
非默认参数`i_csp`指定颜色空间、`i_width`和`i_height`指定宽高信息、`b_vfr_input`指定是否使用时间戳用于帧率控制、
`b_repeat_headers`指定是否在每个关键帧前添加 SPS/PPS 信息、`b_annexb`指定在每个 NAL 前添加起止码或者 NAL 大小。  

第三步，根据视频宽高以及颜色空间为图像结构体`x264_picture_t`分配内存。代码如下：  
{% codeblock lang:c %}
if( x264_picture_alloc( &pic, param.i_csp, param.i_width, param.i_height ) < 0 )
    goto fail;
{% endcodeblock %}

第四步，打开编码器。  
{% codeblock lang:c %}
h = x264_encoder_open( &param );
{% endcodeblock %}

第五步，读取 YUV 文件数据到`x264_picture_t`结构体中。代码实现如下：  
{% codeblock lang:c %}
/* Read input frame */
if( fread( pic.img.plane[0], 1, luma_size, stdin ) != luma_size )
    break;
if( fread( pic.img.plane[1], 1, chroma_size, stdin ) != chroma_size )
    break;
if( fread( pic.img.plane[2], 1, chroma_size, stdin ) != chroma_size )
    break;
{% endcodeblock %}

第六/七步，编码一帧图像,并将其输入到输出文件。代码实现如下：  
{% codeblock lang:c %}
        pic.i_pts = i_frame;
        i_frame_size = x264_encoder_encode( h, &nal, &i_nal, &pic, &pic_out );
        if( i_frame_size < 0 )
            goto fail;
        else if( i_frame_size )
        {
            if( !fwrite( nal->p_payload, i_frame_size, 1, stdout ) )
                goto fail;
        }
{% endcodeblock %}

第九步，将编码器内缓存的数据编码完成，并写到输出文件中。代码如下： 
{% codeblock lang:c %}
    /* Flush delayed frames */
    while( x264_encoder_delayed_frames( h ) )
    {
        i_frame_size = x264_encoder_encode( h, &nal, &i_nal, NULL, &pic_out );
        if( i_frame_size < 0 )
            goto fail;
        else if( i_frame_size )
        {
            if( !fwrite( nal->p_payload, i_frame_size, 1, stdout ) )
                goto fail;
        }
    }
{% endcodeblock %}

第十步，最后是清理工作，代码如下： 
{% codeblock lang:c %}
x264_encoder_close( h );
x264_picture_clean( &pic );
{% endcodeblock %}

## x264编码YUV文件示例

{% codeblock lang:c x264_encoder.c %}
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <x264.h>

#define FAIL_IF_ERROR(cond, ...) \
do\
{\
    if(cond)\
    {\
        fprintf(stderr, __VA_ARGS__);\
        goto fail;\
    }\
}while(0)

int main(int argc, char **argv)
{
    int width, height;
    x264_param_t param;
    x264_picture_t pic;
    x264_picture_t pic_out;
    x264_t *h;
    int i_frame = 0;
    int i_frame_size;
    x264_nal_t *nal;
    int i_nal;

    FILE *fp_src;
    FILE *fp_dst;

    FAIL_IF_ERROR(!(argc > 1), "x264_encoder usage:x264_encoder widthxheight <input.yuv> output.264\n");
    FAIL_IF_ERROR(2 != sscanf(argv[1], "%dx%d", &width, &height), "resolution not sepcified or incorrect\n");

    fp_src = fopen(argv[2], "rb");
    if(!fp_src){
        fprintf(stderr, "open input yuv file faile\n");
    }

    fp_dst = fopen(argv[3], "wb");
    if(!fp_src){
        fprintf(stderr, "open output h264 file faile\n");
    }

    //Get default params for preset/tunnig
    if(x264_param_default_preset(&param, "medium", NULL) < 0)
        goto fail;

    //Configure non-default params
    param.i_csp = X264_CSP_I420;
    param.i_width = width;
    param.i_height = height;
    param.b_vfr_input = 0;
    param.b_repeat_headers = 1;
    param.b_annexb = 1;

    //Apply profile restrictions.
    if(x264_param_apply_profile(&param, "high") < 0)
        goto fail;

    if(x264_picture_alloc(&pic, param.i_csp, param.i_width, param.i_height) < 0)
        goto fail;
#undef fail
#define fail fail2

    h = x264_encoder_open(&param);
    if(!h)
        goto fail;
#undef fail
#define fail fail3

    int luma_size = width*height;
    int chroma_size = luma_size >> 2;
    //Encode frames
    for(;;i_frame++)
    {
        //Read input frame
        if(fread(pic.img.plane[0], 1, luma_size, fp_src)!=luma_size) 
            break;
        if(fread(pic.img.plane[1], 1, chroma_size, fp_src)!=chroma_size) 
            break;
        if(fread(pic.img.plane[2], 1, chroma_size, fp_src)!=chroma_size) 
            break;

        pic.i_pts = i_frame;
        i_frame_size = x264_encoder_encode(h, &nal, &i_nal, &pic, &pic_out);
        if(i_frame_size < 0)
            goto fail;
        else if(i_frame_size)
        {
            if(!fwrite(nal->p_payload, i_frame_size, 1, fp_dst)) 
                goto fail;
        }
    }

    //Flush delayed frames
    while(x264_encoder_delayed_frames(h))
    {
        i_frame_size = x264_encoder_encode(h, &nal,&i_nal, NULL, &pic_out);
        if(i_frame_size < 0)
            goto fail;
        else if(i_frame_size)
        {
            if(!fwrite(nal->p_payload, i_frame_size, 1, fp_dst))
                goto fail;
        }
    }
    x264_encoder_close(h);
    x264_picture_clean(&pic);
    fclose(fp_dst);
    fclose(fp_src);
    return 0;
#undef fail

fail3:
    x264_encoder_close(h);
fail2:
    x264_picture_clean(&pic);
fail:
    return -1;
}
{% endcodeblock %}

注意，在 Ubuntu 下编译时编译命令为  

```
gcc x264_encoder.c -o x264_encoder -phread -lm -lx264
```

执行时命令如下  

```
x264_encoder widthxheight input.yuv output.264
```

