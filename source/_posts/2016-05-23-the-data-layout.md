---
layout: post
title: "YUV 数据分析"
date: 2016-05-23 09:23:07 -0700
comments: true
categories: 总结积累 
---

图像的摆放布局各式各样，不同的布局用于不同的场景。简单记录一下常用的几种数据摆放格式。
<!--more-->
---
##YUV 数据
对于 YUV 图像来说，会有如下几个特性：`FOURCC` `Format` `Component Order` `Image Resolution` `Interlace/Progressive` `Packed/Planar` 。

`FOURCC`包括：`UYVY` `UYNV` `Y422` `IUYV` 等等；

`Format`包括：`YUV420` `YUV422` `YUV444` `RGB444` `MONO`等等：
 
`Component Order`包括：`YUV` `YVU`。


###YUV420摆放格式

<img src="/images/datalayout/Yuv420.png">

通过 YUV image 的摆放格式可以提取出 Y/U/V 三个分量。以 Planar、progressive、YUV420、176*144为例，示例代码如下：

{% codeblock lang:c  splityuvfile %}

int split_yuv(char *str, uint height, uint width)                                                                                                                                
{

    FILE *fp;  
    FILE *fpy;
    FILE *fpu;
    FILE *fpv;
 
    unsigned char  *buf = (unsigned char *)malloc(height * width * 3 / 2);
 
    fp = fopen(str, "r");
    fpy = fopen("y.bin", "wa");
    fpu = fopen("u.bin", "wa");
    fpv = fopen("v.bin", "wa");
    if(!fpv || !fpu || !fpy || !fp){
         fprintf(stderr, "line %d open file error.\n", __LINE__);
        return FALSE;
    }
 
    fread(buf, 1, height * width * 3 / 2, fp);
    fwrite(buf, 1, height * width , fpy);
    fwrite(buf + height * width, 1, height * width >> 2, fpu);
    fwrite(buf + (uint)(height * width * 5 / 4), 1, height * width >> 2, fpv);
 
    fclose(fpv);
    fclose(fpu);
    fclose(fpy);
    fclose(fp);
    free(buf);
   
    return TRUE;
}
{% endcodeblock %}
