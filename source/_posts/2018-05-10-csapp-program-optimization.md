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

以如下程序为示例，记录几种通用的优化方法：

{% codeblock lang:c vec.h %}
#ifndef VEC_H
#define VEC_H

#define IDENT 0
#define OP +

// Create abstract data type for vector

typedef int data_t;

typedef struct{
    long int len;
    data_t *data;
}vec_rec, *vec_ptr;
#endif
{% endcodeblock %}

{% codeblock lang:c vec.c %}
// Create vector of specified length
vec_ptr new_vec(long int len)
{
    //Allocate header structure
    vec_ptr result = (vec_ptr)malloc(vec_rec);
    if(!result)
        return NULL;    //Could not allocate storage
    result->len = len;

    //Allocate array
    if(len > 0){
        data_t *data = (data_t *)calloc(len, sizeof(data_t));
        if(!data){
            free((void *)result);
            return NULL;    //could not allocate storage
        }
        result->data = data;
    }else{
        result->data = NULL;
    }

    return result;
}

//Retrieve vector element and store at dest.
//Return 0 (out of bounds) or 1 (successful)
int get_vec_element(vec_ptr v, long int index, data_t *dest)
{
    if(index < 0 || index >= v->len)
        return 0;
    *dest = v->data[index];
    return 1;
}

//Return length of vector
long int vec_length(vec_ptr v)
{
    return v->len;
}

//Implementation with maximum use of data abstraction
void combine1(vec_ptr v, data_t *dest)
{
    long int i;

    *dest = IDENT;
    for(i = 0; i < vec_length(v); i++){
        data_t val;
        get_vec_element(v, i, &val);
        *dest = *dest OP val;
    }
}
{% endcodeblock %}

### 消除循环的低效率

观察上面的 **combine1** 函数，可以看出在 for 循环的测试条件中，每次都要执行 **vec_length**，但这个函数每次执行结果都一样，可以提到测试条件外面，修改代码如下： 
{% codeblock lang:c %}
//move call to vec_length out of loop
void combine2(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);

    *dest = IDENT;
    for(i = 0; i < length; i++){
        data_t val;
        get_vec_element(v, i, &val);
        *dest = *dest OP val;
    }
}
{% endcodeblock %}

### 减少调用过程

函数调用会带来巨大的时间开销，再来看上面的**combine2**函数中，每次循环都会调用**get_vec_element**函数，而且这个函数的返回值 val 都是随着 i 的递增而在内存中连续存放，因此可以将该函数从循环中拿出。

{% codeblock lang:c %}
data_t *get_vec_start(vec_ptr v)
{
    return v->data;
}
//direct access to vector data
void combine3(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);
    data_t *data = get_vec_start(v);

    *dest = IDENT;
    for(i = 0; i < length; i++){
        *dest = *dest OP data[i];
    }
}
{% endcodeblock %}

### 消除不必要的存储器引用

观察上面的函数，在每次 for 循环中，都会有两次的读取内存(*dest 和 data[i])的操作，一次写内存(*dest)的操作。每次读写内存都会耗时，因此可以使用临时变量，从而使每次循环只有一次读即可。


{% codeblock lang:c %}
//Accumulate result in local variable
void combine4(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);
    data_t *data = get_vec_start(v);
    data_t acc = IDENT;

    for(i = 0; i < length; i++){
        acc = acc OP data[i];
    }
    *dest = acc;
}
{% endcodeblock %}

### 循环展开

循环展开是一种程序变换，通过增加每次迭代计算的元素的数量，减少循环的迭代次数。它能够从两方面改善程序的性能：首先，它减少了不直接有助于程序结果的操作的数量。其次，它提供一些方法，可以进一步变换代码，减少整个计算中关键路径上的操作数量。


{% codeblock lang:c %}
//Unroll loop by 2
void combine4(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);
    long int limit = length - 1;
    data_t *data = get_vec_start(v);
    data_t acc = IDENT;

    //Combine 2 elements at a time
    for(i = 0; i < length; i+=2){
        acc = acc OP data[i] OP data[i+1];
    }

    // Finish any remaining elements
    for(; i < length ; i++){
        acc = acc OP data[i];
    }

    *dest = acc;
}
{% endcodeblock %}

### 提高并行性

两次循环展开，并且使用两路并行，该方法利用了功能单元的流水线能力

{% codeblock lang:c %}
//Unroll loop by 2, 2-way parallelism
void combine6(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);
    long int limit = length - 1;
    data_t *data = get_vec_start(v);
    data_t acc0 = IDENT;
    data_t acc1 = IDENT;

    //combine 2 elements at a time
    for(i = 0; i < limit; i+=2){
        acc0 = acc0 OP data[i];
        acc1 = acc1 OP data[i + 1];
    }
    
    //Finish any remaining elements
    for(; i < length; i++){
        acc0 = acc0 OP data[i];
    }
    *dest = acc0 OP acc1;
}
{% endcodeblock %}

还有其他的方法，比如重新组合结合上面**combine5**中的运算，即将
```
acc = (acc OP data[i]) OP data[i + 1]
```
合并成如下实现
```
acc = acc OP (data[i] OP data[i + 1])
```

或者使用 SIMD 指令提高更高的并行性。



