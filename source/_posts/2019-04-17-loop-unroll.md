---
layout: post
title: "性能优化之循环展开"
date: 2019-04-17 07:36:49 -0700
comments: true
categories: 性能优化
---

* list element with functor item
{:toc}

循环展开是通过增加每次迭代计算的元素的数量，减少循环的迭代次数。循环展开只能针对整形加法和乘法的性能改进。

<!--more-->

循环展开从两个方面改变程序的性能：

* 分支预测失败减少。
* 减少不直接有助于程序结果的操作的数量，如循环索引计算和条件分支。
* 提供了一种方法，可以进一步变换代码，减少整个计算中关键路径上的操作数量。

## 示例分析

{% codeblock lang:c loop_unrolling.c %}
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

void loop_unroll1(void)
{
    float a[1000000];
    for(int i = 0; i < 1000000; i++)
        a[i] = a[i] + 3;
}

void loop_unroll2(void)
{
    float a[1000000];
    for(int i = 0; i < 1000000; i+=2)
    {
        a[i] = a[i] + 3;
        a[i + 1] = a[i + 1] + 3;
    }
}

void loop_unroll3(void)
{
    float a[1000000];
    for(int i = 0; i < 1000000; i+=4)
    {
        a[i] = a[i] + 3;
        a[i + 1] = a[i + 1] + 3;
        a[i + 2] = a[i + 2] + 3;
        a[i + 3] = a[i + 3] + 3;
    }
}

int main(int argc, char **argv)
{
    struct timeval time_start, time_end;
    gettimeofday(&time_start, NULL);
    loop_unroll1();
    gettimeofday(&time_end, NULL);
    printf("used time us_sec %ld\n", time_end.tv_usec - time_start.tv_usec);
    gettimeofday(&time_start, NULL);
    loop_unroll2();
    gettimeofday(&time_end, NULL);
    printf("used time us_sec %ld\n", time_end.tv_usec - time_start.tv_usec);
    gettimeofday(&time_start, NULL);
    loop_unroll3();
    gettimeofday(&time_end, NULL);
    printf("used time us_sec %ld\n", time_end.tv_usec - time_start.tv_usec);

    return 0;
}
{% endcodeblock %}

运行上面的程序：

```
gcc -funroll-loops -pg loop_unrolling.c -o loop_unrolling
```

执行三次后，结果如下:

| Executions | loop_unroll1 | loop_unroll2 | loop_unroll3 |
| :--------: | :------------: | :-----: | :------: |
| 1 | 12618 | 1890 | 3162 |
| 2 | 7456 | 1987 | 1629 |
| 3 | 9868 | 2446 | 2388 |

上面的结果可以看出，产开次数为2相对于未展开时，性能有明显提升，但展开次数为4时，性能相对于展开次数为2并没有多少提升。另外，编译器选项`-funroll-loops`好像并没有起到什么作用。但是如果添加编译选项`-O1`或`-O2/-O3`时，编译器会自动优化该函数。  

关于展开次数和性能之间的关系，CSAPP 这本书里有介绍一个实验结果，如图所示：  

{% img /images/loop_unroll/loop_unrolling.png %}

从图中可以看出，当循环展开到6次时的CPE(Cycles Per Element,每元素的周期数)测量值，对于展开2次或3次时观察到的趋势还在继续——循环展开对浮点数运算没有帮助，但对整数加法和乘法，CPE降至1.00.

实验过程中发现，CSAPP中描述的结论与我自己测试的结果有几点需要注意：

1. 测试中，循环展开对于浮点数的加法和乘法是有效的。
2. 编译器选项`-funroll-loops`并没有起到循环展开的作用。
3. 循环展开对于性能的提升确实是都有帮助的。

## 循环展开扩展

循环展开的本质是降低循环开销、增加并行运行的可能性。网上找到的大部分讲解循环展开的都是针对**for**循环的，既然是循环展开，那么对于**while**循环，理论上也是适用的，最后找到了[Generalized Loop-Unrolling](http://www2.cs.uh.edu/~jhuang/JCH/JC/loop.pdf)。关于**while**循环展开的方法，可以用下面的描述语言表示：  

```
while B do S; <==> while B ^ wp(S, B) do begin S;S end; while B do S;
```
按照论文的讲解，手动写了两个替换的等价循环

{% codeblock lang:c %}
q = 0;
while (a > b)
{
    a = a - b;
    q++;
}

q = 0;
while (a >=b && a >= 2*b)
{
    a = a - b;
    q++;
    a = a - b;
    q++;
}
{% endcodeblock %}

遗憾的是，运行后，两者的时间并没有太大的差别，有时第二段代码方法甚至更慢。猜测可能原因有两点：现代编译器对此类优化方法已经完成的很好；不同运行环境运行效果不同；所以，循环展开这类方法，最好是实际操作运行看结果，理论与实际可能有出入。 

## 结论总结

循环展开对于性能的提升是由帮助的，但这种帮助并不是无限的，随着展开次数的增多，性能并不会继续增加，相反，循环展开次数过多，会使得程序代码膨胀、代码可读性降低。另外，编译器优化选项`-O1`或`-O2`等，会使得编译器自身会对代码进行优化，此时手动循环展开并不是一个好的方法。再者，受运行环境的影响（我的测试用例都是在Ubuntu虚拟机下完成），其测试结果可能有不同。

## 参考资料
1. [循环展开](https://zh.wikipedia.org/wiki/%E5%BE%AA%E7%8E%AF%E5%B1%95%E5%BC%80)
2. [Loop Unrolling](https://en.wikipedia.org/wiki/Loop_unrolling)
3. [Generalized Loop-Unrolling: a Method for Program Speed-Up](http://www2.cs.uh.edu/~jhuang/JCH/JC/loop.pdf)
1. [C++性能榨汁机之循环展开](https://zhuanlan.zhihu.com/p/37582101)
2. [Computer Systems - A Programmer's Perspective](https://github.com/shihyu/CSAPP2e/blob/master/Computer%20Systems%20-%20A%20Programmer's%20Perspective%20(2nd).pdf)
