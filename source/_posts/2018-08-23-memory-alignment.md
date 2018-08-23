---
layout: post
title: "memory_alignment"
date: 2018-08-23 08:23:49 -0700
comments: true
categories: 总结积累
---

数据对齐会影响到计算机访问内存以及占用内存的空间大小。

<!--more-->

* list element with funtor item
{:toc}

### 对齐要求

在`X86`或`ARM`处理器中，基本 C 数据类型通常并不存储于内存中的随机字节地址。实际情况是，除`char`外，
所有其他类型都有对齐要求：`char`可起始于任意字节地址，2 字节的 short 必须从偶数字节地址开始，4 字节`int`或`float`必须
从能被 4 整除的地址开始，8 比特的`long`和`double`必须从能被 4 整除的地址开始，8 比特的`long`和`double`必须从
能被 8 整除的地址开始。无论`signed(有符号)`还是`unsigned(无符号)`都不受影响。  

简言之，`X86`和`ARM`的基本 C 类型是`自对齐(self-aligned)`的。关于指针，无论 32 位还是 64 位也都是自对齐的。

自对齐可令访问速度更快，因为它有利于生成单指令(single-instruction)存取这些类型的数据。另一方面，如若没有对齐约束，可能
最终不得不通过两个或更多指令访问跨越机器字边界的数据。字符数据是种特殊情况，因其始终处在单一机器字中，所以无论存取何处的字符数据，
开销都是一致的。这也就是它不需要对齐的原因。  

### 填充

假设我们有如下一段 C 代码：

```
int function(void)
{
    char *pchar;
    char ch;
    int idx;
    ...
}
```

这里的占用字节空间如下：

```
char *pchar;    //4 or 8 bytes
char ch;        //1 byte
char pad[3];    //3 bytes, 3 个字节的空间被浪费掉了
int idx;        //4 bytes
...
```

如果 `x `为 2 字节 short：

```
char *p;
char c;
short x;
```

时间分布为:

```
char *p;    //4 or 8 bytes
char c;     //1 byte
char pad[1];    //1 byte, 1 字节的空间被浪费掉了
short x;        //2 bytes
```

更多示例，请参照最后给出的程序示例。

### 结构体的对齐和填充

通常情况下，结构体实例以其最宽的标量成员为基准进行对齐。编译器之所以如此，是因为此乃确保所有成员自对齐，实现快速访问最简便的方法。

思考如下的结构体：

```
struct foo1{
    char *p;
    char c;
    long x;
};
```

64 位系统中，任何`struct foo1`的实例都采用 8 字节对齐，其内存分布如下：

```
struct foo1{
    char *p;    //8 bytes
    char c;     //1 byte
    char pad[7];    // 7 bytes
    long x;         // 8 bytes
};
```
更多示例，请参照最后给出的程序示例。

### 结构体成员重排

理解了结构体成员的对齐后，可以看到，最简单的节省内存的方式，是按对齐递减重新对结构体成员排序。即让所有指针对齐成员排在最前面，因为
在 64 为系统中它们占用 8 字节；然后是 4 字节的 int；再然后是 2 字节的 short，最后是字符。  

以简单的链表结构为例：

```
struct foo7{
    char c;
    struct foo7 *p;
    short x;
};
```
`sizeof(foo7)`占用 24 字节。如果按照长度重排，可以得到:

```
struct foo8{
    struct foo8 *p;
    short x;
    char c;
};
```

重新打包后，空间降低为 16 字节。

### 可读性与缓存局部性

笨拙地、机械地重排结构体可能有损可读性。最好重排成员：将语义相关的数据放在一起，形成连贯的组。最理想的情况是，结构体的设计应与程序的设计相通。

### 代码测试示例

{% codeblock lang:c %}
#include <stdio.h>
#include <stdbool.h>

struct foo1 {
    char *p;
    char c;
    long x;
};

struct foo2 {
    char c;      /* 1 byte */
    char pad[7]; /* 7 bytes */
    char *p;     /* 8 bytes */
    long x;      /* 8 bytes */
};

struct foo3 {
    char *p;     /* 8 bytes */
    char c;      /* 1 byte */
};

struct foo4 {
    short s;     /* 2 bytes */
    char c;      /* 1 byte */
};

struct foo5 {
    char c;
    struct foo5_inner {
        char *p;
        short x;
    } inner;
};

struct foo6 {
    short s;
    char c;
    int flip:1;
    int nybble:4;
    int septet:7;
};

struct foo7 {
    int bigfield:31;
    int littlefield:1;
};

struct foo8 {
    int bigfield1:31;
    int littlefield1:1;
    int bigfield2:31;
    int littlefield2:1;
};

struct foo9 {
    int bigfield1:31;
    int bigfield2:31;
    int littlefield1:1;
    int littlefield2:1;
};

struct foo10 {
    char c;
    struct foo10 *p;
    short x;
};

struct foo11 {
    struct foo11 *p;
    short x;
    char c;
};

struct foo12 {
    struct foo12_inner {
        char *p;
        short x;
    } inner;
    char c;
};

main(int argc, char *argv)
{
    printf("sizeof(char *)        = %zu\n", sizeof(char *));
    printf("sizeof(long)          = %zu\n", sizeof(long));
    printf("sizeof(int)           = %zu\n", sizeof(int));
    printf("sizeof(short)         = %zu\n", sizeof(short));
    printf("sizeof(char)          = %zu\n", sizeof(char));
    printf("sizeof(float)         = %zu\n", sizeof(float));
    printf("sizeof(double)        = %zu\n", sizeof(double));
    printf("sizeof(struct foo1)   = %zu\n", sizeof(struct foo1));
    printf("sizeof(struct foo2)   = %zu\n", sizeof(struct foo2));
    printf("sizeof(struct foo3)   = %zu\n", sizeof(struct foo3));
    printf("sizeof(struct foo4)   = %zu\n", sizeof(struct foo4));
    printf("sizeof(struct foo5)   = %zu\n", sizeof(struct foo5));
    printf("sizeof(struct foo6)   = %zu\n", sizeof(struct foo6));
    printf("sizeof(struct foo7)   = %zu\n", sizeof(struct foo7));
    printf("sizeof(struct foo8)   = %zu\n", sizeof(struct foo8));
    printf("sizeof(struct foo9)   = %zu\n", sizeof(struct foo9));
    printf("sizeof(struct foo10)   = %zu\n", sizeof(struct foo10));
    printf("sizeof(struct foo11)   = %zu\n", sizeof(struct foo11));
    printf("sizeof(struct foo12)   = %zu\n", sizeof(struct foo12));
}
{% endcodeblock %}

### 参考文档

1. [The Lost Art Of C Structure Packing](https://github.com/ludx/The-Lost-Art-of-C-Structure-Packing)
2. [Memory Alignment](https://wr.informatik.uni-hamburg.de/_media/teaching/wintersemester_2013_2014/epc-14-haase-svenhendrik-alignmentinc-paper.pdf)
3. [Data Structure Alignment](https://en.wikipedia.org/wiki/Data_structure_alignment)
