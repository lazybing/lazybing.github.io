---
layout: post
title: "深入理解计算机系统之优化程序性能"
date: 2018-05-10 07:57:12 -0700
comments: true
categories: 读书笔记
---

* list element with functor item
{:toc}

本文主要记录学习完 CSAPP 的优化程序性能章节。程序的优化主要有三种方法：选择合适的算法和数据结构;编写出编译器能够有效优化以转换成高效可执行代码的源代码;将一个任务分成多个部分,使其可以在多核和多处理器的某种组合上并行计算。了解了程序优化的三种方法后，我们必须思考一个问题，既然程序的优化是无止境的，那么优化在什么点算是最好的平衡的，这里的平衡包括程序开发的时间与效率、代码的可读性与性能。想明白了这两点，就不难理解为什么人们不是把所有的语言都用汇编来编写，以及对于性能好但可读性代码差的代码在公司企业中，有的时候并不推崇了。 

<!--more-->

## 优化编译器的能力和局限性

以 GCC 编译器为例，可以使用多个优化级别`-O1/-O2/-O3`等，但编译器的优化也是有限的，它只对确定性的可以优化的代码才会优化，对于不确定性的部分，编译器不会对其优化。看如下两段代码：  

{% codeblock lang:c %}
void twiddle1(int *xp, int *yp)
{
    *xp += *yp;
    *xp += *yp;
}

void twiddle2(int *xp, int *yp)
{
    *xp +=2 * *yp;
}
{% endcodeblock %}

上面的代码中`twiddle1`的功能是，将 yp 指针指向地址的值加到 xp 指针指向地址的值，执行两次。`twiddle2`的功能是将 yp 指针指向地址的值得两倍加到 xp 指针指向地址的值。看起来两个的功能是一样的。但当 xp 和 yp 指向同一个存储器位置时，两个程序结果不在相同，因此编译器不会优化它。这就是一个典型的“妨碍优化因素”，称为**存储器别名使用**。

再来看另外一段程序:  

{% codeblock lang:c %}
int f();

int fun1(){
    return f() + f() + f() + f();
}

int fun2(){
    return 4 * f();
}
{% endcodeblock %}

上面的两个函数在编译器看来也不相同，这就是妨碍优化的第二个因素：函数调用。思考，当函数 f() 存在对全局变量的修改时，因此编译器不能优化。  

## 表示程序性能

为表示程序性能，我们引入**每元素的周期数(Cycles Per Element, CPE)**的概念，使用时钟周期来表示度量标准比用事件表示有用的多，因为时钟周期表示的是执行了多少条指令，而程序运行了多少时间，可能与机器的频率有关。

## 程序示例

{% codeblock lang:c vec.h %}
// Create abstract data type for vector

typedef int data_t;

typedef struct{
    long int len;
    data_t *data;
}vec_rec, *vec_ptr;
{% endcodeblock %}

