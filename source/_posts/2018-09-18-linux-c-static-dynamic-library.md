---
layout: post
title: "Linux下C语言调用静态库和动态库简介"
date: 2018-09-18 21:27:55 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

最近工作中遇到要把第三方静态库整合到自己的动态开里的问题，在此记录并整理一些关于静态库和动态库的知识，并用特定的例子。

<!--more-->

### 动态库和静态库简述

动态库和静态库本质上是一种可执行代码的二进制形式，它们可以被操作系统载入内存执行。两者的主要区别是，静态库是在编译过程中被载入可执行程序的，体积较大；动态库是在可执行程序在运行时被载入内存的，在编译过程中仅仅使用简单的引用，体积较小。  

给出示例代码如下：  

{% codeblock lang:c sayhello.c %}
#include <stdio.h>
#include "sayhello.h"

void helloworld(void)
{
    printf("Hello World\n");
}
{% endcodeblock %}

{% codeblock lang:c sayhello.h %}
#ifndef _SAYHELLO_H_
#define _SAYHELLO_H_

void helloworld(void);

#endif
{% endcodeblock %}


### 静态库使用示例

编译静态库：

```
$ gcc -Wall -O2 -fPIC -I./ -c -o sayhello.o sayhello.c
$ ar crv libsayhello.a sayhello.o
```

`ar`命令会生成`libsayhello.a`的静态库。该命令的参数如下：

| 参数 | 意义 |
|:---:|:----:|
|-r|将objectfile 文件插入静态库尾或替换静态库中同名文件|
|-x|从静态库文件中抽取文件objfile|
|-t|打印静态库的成员文件列表|
|-d|从静态库中删除文件objfile|
|-s|重置静态库文件索引|
|-v|创建文件冗余信息|
|-c|创建静态库文件|

生成了静态库后，可以在可执行文件中调用静态库内的函数,示例代码：

{% codeblock lang: test_hello_stactic.c %}
#include <stdio.h>
extern void helloworld(void);

int main(int argc, char **argv)
{
    helloworld();
}
{% endcodeblock %}

编译命令:

```
$ gcc test_hello_stactic.c -o test_hello_sta ./libsayhello.a
```

### 动态库使用示例

编译动态库：

```
$ gcc -O2 -fPIC -shared sayhello.c -o libsayhello.so
或
$ gcc -O2 -fPIC -c sayhello.c
$ gcc -shared -o libsayhello.so sayhello.o
```

其中

* fPIC:产生与位置无关码，全部使用相对地址
* shared:生成动态库

调用动态库的示例代码：

{% codeblock lang: test_hello_shared.c %}
#include <stdio.h>
#include <dlfcn.h>

#define LIB "./libsayhello.so"
int main(int argc, char **argv)
{
    void *dl = dlopen(LIB, RTLD_LAZY);
    if(dl == NULL)
    {
        fprintf(stderr, "Error:faile to load libary.\n");
    }

    void (*func)() = dlsym(dl, "helloworld");
    func();
    dlclose(dl);

    return 0;
}
{% endcodeblock %}

### 动态库和静态库整合

### 参考文档

1. [Linux下C调用静态库和动态库](http://answerywj.com/2016/10/10/Linux%E4%B8%8BC%E8%B0%83%E7%94%A8%E9%9D%99%E6%80%81%E5%BA%93%E5%92%8C%E5%8A%A8%E6%80%81%E5%BA%93/)
2. [为什么不能再动态库里静态链接](https://liam0205.me/2017/04/03/not-to-link-libstdc-statically-and-why/)  

