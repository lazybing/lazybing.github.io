---
layout: post
title: "编程小技巧"
date: 2017-09-29 13:35:57 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

本篇博客主要记录在写代码过程中遇到的一些小技巧，它并不是特别难以实现的复杂算法，也不是对某种特定语言的记录，而是在
工作中遇到某个问题时，自然而然能想到的解决方法，通常是一些比较通用的小技巧。  

<!--more-->

## 获取文件路径后缀名

工作中经常遇到对一批视频文件进行统一处理的情况，有时会根据文件名的不同后缀名进行不同的处理操作。此时就需要首先获取文件的后缀名，
之后再根据后缀名的不同进行相应的操作。  

### C 语言实现

实现思路：获取文件字符串的最后一个字符，依次向前寻找`.`，`.`后面即为后缀名。

{% codeblock lang:c get_filename_extension %}
static inline char *get_filename_extension( char *filename )
{
    char *ext = filename + strlen( filename );
    while( *ext != '.' && ext > filename )
        ext--;
    ext += *ext == '.';
    return ext;
}
{% endcodeblock %}

### C++ 语言实现

实现思路：首先将文件或路径名转换为一个`string`类，使用它的成员函数`rfind`找到最后一个`.`的位置，最后使用`substr`成员函数返回`.`后的所有内容，即得后缀名。

{% codeblock lang:c++ get_filename_extension %}
using std::string;
string getFileExt(const string& s)
{
    size_t i = s.rfind('.', s.length());
    if(i != string::npos)
    {
        return(s.substr(i+1, s.length() - i));
    }
    return ("");
}
{% endcodeblock %}

### Shell 脚本实现

{% codeblock lang:sh get_filename_extension %}
#!/bin/sh
fullfilename=$1
filename=$(basename "$fullfilename")
fname="${filename%.*}"
ext="${filename##*.}"

echo "Input File:$fullfilename"
echo "Filename without Path:$filename"
echo "Filename without Extension:$fname"
echo "File Extension without Name:$ext"
{% endcodeblock %}

## 调试信息分级打印

在工作中，经常遇到需要将调试信息分级打印的情况。比如在码流播放中可能默认要打印出码流的宽高、码流的 CODEC 类型等基本信息，可以定义此类信息级别为`LOG_INFO`级别；
码流播放时，可能会出现错误，此类信息级别为`LOG_ERROR`等。  

实现思路：将需要打印的信息级别与默认打印信息级别进行比较，级别高时，将信息打印出来；级别低时，不打印信息。

{% codeblock lang:c log_level %}

#define LOG_DEFAULT 2
#define LOG_NONE    (-1)
#define LOG_ERROR   0
#define LOG_WARNING 1
#define LOG_INFO    2
#define LOG_DEBUG   3

void Printf(int i_level, const char *psz_fmt, va_list arg)
{
   char *psz_prefix;
   switch(i_level) 
   {
        case LOG_ERROR:
            psz_prefix = "error";
            break;
        case LOG_WARNING:
            psz_prefix = "warning";
            break;
        case LOG_INFO:
            psz_prefix = "info";
            break;
        case LOG_DEBUG:
            psz_prefix = "debug";
            brengak;
        default:
            psz_prefix = "unknown";
            break;
   }
   vfprintf(stderr, psz_fmt, arg);
}

void LOG_PRINT(int i_level, const char *psz_fmt, ...); 
void LOG_PRINT(int i_level, const char *psz_fmt, ...)
{
    if(i_level <= LOG_DEFAULT)
    {
        va_list arg;
        va_start(arg, psz_fmt);
        Printf(i_level, psz_fmt, arg);
        va_end(arg);
    }
}

{% endcodeblock %}

## 分析特定格式的文件

工作中在验证芯片的`vdec`模块是否正常工作时，需要大量的跑一些码流，这些码流通常会放到一个`filelist`中，因为需要测试的项不同，此时就可以
通过按照一定的格式并列存放这些码流，例如根据不同的`codec`、测试比较`YUV`或`CRC`，是要连续测试，还是要中途停止方便`Debug`问题，我们可以按照如下格式对`filelist`进行定义：  

```
Codec_Type  Compare_Type Test_Type Bitstream_Full_Path
```

对于上面这种`filelist`，可以通过`fscanf`来逐个的获取特定的字符串，并通过`feof`来判断文件文件是否读取完毕， 之后使用`strcmp`来与特定的字符串进行匹配。例如，有如下的一个`filelist.txt`：  

```
HEVC Compare_CRC Debug F:\FFmpeg\hevc_bitstream1.bin
H264 Compare_YUV Release F:\FFmpeg\h264_bitstream2.bin
```

分析`filelist.txt`示例代码：

{% codeblock lang:c parse_filelist %}
char Codec_Type[10];
char Compare_Type[10];
char Release_Type[10];
char Bitstream_Path[200];

FILE *pFile = fopen("./filelist.txt", "rb");
if(pFile == NULL)
{
    fprintf(stderr, "open file fail %s", strerror(errno));
}

while(!feof(pFile))
{
    fscanf(pFile, "%s %s %s %s", Codec_Type, Compare_Type, Release_Type, Bitstream_Path);
}

if(!strcmp("HEVC", Codec_Type)) printf("Codec Type is HEVC\n");
if(!strcmp("H264", Codec_Type)) printf("Codec Type is H264\n");
...

if(!strcasecmp("hevc", Codec_Type)) printf("Codec Type is HEVC\n");
...
{% endcodeblock %}

注意上面表示出来了通过`strcmp`来判断`Codec_Type`的类型，后面的`Compare_Type`可以用同样的方法来给出。

在使用过程中，人们并不会特别在意字母的大小写，但要表达的意思通常是一样的，比如`HEVC``hevc``Hevc`通过都是一样的，如果此时还用`strcmp`来判断，会出错，为此，我们提出了`strcasecmp`的使用方法，来避免大小写带来的问题，这也算是编写类似代码的一个小技巧。  

## fopen 函数个数限制

严格来讲，这个并不是编程的一些小的技巧，而是自己在工作中遇到的一个小问题，最近在每晚上跑测试时，经常遇到一晚上跑完 503 个测试后，程序就会崩溃掉，给出的提示信息是"Open File Fail",起初是通过观察`errno`的类型来`Debug`出错的原因，最后定位到问题是，
对每个文件都打开了两次，而关闭只有一次，导致文件描述符的个数爆掉了。这个问题的原因是在不同的系统中，都会有对文件描述符的最大个数有一定的限制。

在<UNIX环境高级编程:文件I/O>中有这样的解释：  

> 当读或写一个文件时，使用`open`返回的文件描述符标识该文件，将其作为参数传送给`read`或`write`。文件描述符的变化范围是`0~OPEN_MAX`。

关于文件描述符的最大个数问题，从`stackoverflow`上找到了以下几个问题的回复，可参考：

[1.Is there a limit on number of open files in Windows](https://stackoverflow.com/questions/870173/is-there-a-limit-on-number-of-open-files-in-windows)  
[2.maximum-number-of-files-that-can-be-opened-by-c-fopen-in-linux](https://stackoverflow.com/questions/17931583/maximum-number-of-files-that-can-be-opened-by-c-fopen-in-linux)  
[3.fopen-problem-too-many-open-files](https://stackoverflow.com/questions/3184345/fopen-problem-too-many-open-files)  

关于`fopen`的使用，通常会判断返回值是否`NULL`来判断是否打开成功，其实除此之外，还可以继续监测出错的类型`errno`，并用`strerror()`函数直接显示出错的具体原因。技巧如下：  

{% codeblock lang:c fopen_tips %}
#include <error.h>

FILE *pFile = fopen("file_full_path", "rb");
if(pFile == NULL)
{
    fprintf(stderr, "Open File Fail:%s\n", strerror(errno));
}
{% endcodeblock %}

## 函数声明

函数定义是指对函数功能的确立，包括指定函数名、函数值类型、形参类型、函数体等，它是一个完整的、独立的函数单位。  

函数声明的作用则是把函数的名字、函数类型以及形参类型、个数和顺序通知编译系统，以便在调用函数时系统按此进行对照检查。

注意，C 语言环境下，如果函数不进行声明就使用，可能会产生错误，因为默认将返回值作为 int 类型来处理，所以，最好是在使用之前对函数进行声明。  

这个错误之前搞了我好久……囧，例子如下。

{% codeblock lang:c float_int.c %}
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

float mid(float a, float b)
{
    return (a + b) * 0.5;
}
{% endcodeblock %}

{% codeblock lang:c main.c %}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    printf("%f\n", mid(2, 5));
    return 0;
}
{% endcodeblock %}

编译上面的两个函数`gcc main.c float_int.c`, 之后运行它，输出时 0.00000.

错误的原因是没有函数声明，默认认为函数返回值类型为 int.

