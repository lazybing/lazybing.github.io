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
            break;
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
