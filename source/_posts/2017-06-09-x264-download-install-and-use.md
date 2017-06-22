---
layout: post
title: "x264 下载、安装和使用"
date: 2017-06-09 08:51:11 -0700
comments: true
categories: x264 学习
---

* list element with functor item
{:toc}

[x264官网](http://www.videolan.org/developers/x264.html)对 x264 项目进行了简单的描述，包括

##x264 获取代码：

```
git clone http://git.videolan.org/git/x264.git
```

##x264 编译和安装

此处记录的是在Linux下的编译和安装：

```
cd x264
.configure
sudo make
sudo make install
```

注意，如果想要在 Linux 下使用 GDB 进行逐步调试，需要修改`.configure`后生成的`config.mak`文件，将里面的`CC=gcc`改为`CC=gcc -g`。

之后就可以使用 X264 来进行编码 H264 格式的视频了。

##x264 的使用
x264 的使用可以通过命令行`x264 --help`来获取。格式一般为  
```
x264 [options] -o outfile infile
```

其中的输入文件可以是`raw`文件、`.y4m`文件等，输出文件格式可以是`.264`、`.mkv`、`.flv`和`.mp4`；其中输入文件如果是`raw`文件，需要在 infile 后面通过输入参数（--input-res 640x360）来指定分辨率。
