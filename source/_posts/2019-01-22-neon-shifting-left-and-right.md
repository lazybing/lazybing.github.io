---
layout: post
title: "NEON 编程4——左右移位"
date: 2019-01-22 06:44:07 -0800
comments: true
categories: 汇编学习
---

* list element with functor item
{:toc}

本文将介绍 NEON 提供的移位运算，并介绍如何利用移位运算在常用颜色深度之间转换影像数据。本系列前期已发布的文章包括：第一部分：加载与存储，第二部分：余数的处理，第三部分：矩阵乘法。  

<!--more-->

## 向量移位

NEON 上的移位与标量 ARM 编码中可能用到的移位非常相似，即每个向量元素的位数均向左或向右移位，出现在每个元素左侧与右侧的位将被删除；它们不能移位至相连的元素。  

{% img /images/neon_shift_left_right/shift_vector.png %}

带符号元素的向量上发生的右移位由指令附加的类型指定，并会将符号扩展至每一个元素。这与 ARM 编码中可能用到的算术移位相同。应用到无符号向量的移位不会发生符号扩展。

## 移位与插入

NEON 也支持通过插入产生移位，使两个不同向量的位相结合。例如，左移位与插入（VSLI）可使源向量的每一个元素均向左移位。每个元素右侧新插入的位就是目标向量中的对应为。

{% img /images/neon_shift_left_right/shift_insert.png %}

## 移位与计算

最后，NEON 还支持向量元素向右移位，并将结果计入到另一个向量中。这种方法对于先在高精度条件下进行临时计算，然后再将结果与低精度计算器相结合的情况非常有用。

## 指令修改器

每个移位指令都能拥有一个或多个修改器。这些修改器并不改变移位运算本身，而是通过调整输入值与输出值，消除偏差或饱和状态，保持一定的范围。共有五种移位修改器：

* 舍位修改器(Rounding)，以 R 前缀表示，可以纠正右移时舍位导致的偏差。  
* 窄修改器(Narrow)，以 N 后缀表示，可以让结果中每个元素的位数减半。它代表Q(128位)源和D(64位)目标寄存器。  
* 长修改器(Long),以 L 后缀表示，可以让结果中每个元素的位数加倍。它代表D源和Q目标寄存器。饱和修改器(Saturating)，以Q前缀表示，可以在最大和最小可表示范围内设置每个结果元素，前提是结果未超出该范围。向量的位数和符号类型可用于确定饱和范围。  
* 无符号饱和修改器(Unsigned Saturationg)，以Q前缀和U后缀表示，与饱和修改器类似，但在进行带符号与无符号输入时，结果将在无符号范围内表示为饱和。  

这些修改器的部分组合并未表现出有用的运算，因此 NEON 也没有提供相应指令。例如，饱和右移位（应称为 VQSHR）其实就毫无必要，因为右移位只会让结果变得更小，因而值根本无法超出有效范围。 

## 可用移位表

NEON 提供的所有移位指令均在下表中列出。它们根据先前提到的修改器进行排列。如果你还是不太确定修改器各个字母代表的含义，请利用下表选择需要的指令。  

{% img /images/neon_shift_left_right/shift_table_avaliable.png %}

## 示例：转换颜色深度

颜色深度之间的转换是图形处理中经常需要的运算。通常，输入或输出数据都是 RGB565 16 位颜色格式，但 RGB888 格式的数据处理起来更为方便。对于 NEON 而言尤其如此，因为它无法为 RGB565 这样的数据类型提供本机支持。  

{% img /images/neon_shift_left_right/color_format.png %}

但是，NEON 仍然可以有效地处理 RGB565 数据，上文中介绍的向量移位便提供了处理方法。

### 从 565 到 888

首先，我们来看如何将 RGB565 转换为 RGB888。假设寄存器 q0 中有 8 个 16 位像素，我们想要在 d2、d3和d4这三个寄存器中将红色、绿色和蓝色分离成 8 位的元素。

{% codeblock lang:asm %}
vshr.u8     q1, q0, #3  @shift red elements right by three bits,
                        @discarding the green bits at the bottom of the red 8-bit elements.
vshrn.i16   d2, q1, #5  @shift red element right and narrow,
                        @discarding the blue and green bits.
vshrn.i16   d3, q0, #5  @shift green elements right and narrow,
                        @discarding the blue bits and some red bits due to narrowing.
vshl.i8     d3, d3, #2  @shift green elements left, discarding the remaining red bits,
                        @and placing green bits in the correct place.
vshl.i16    q0, q0, #3  @shift blue elements left to most-significant 
                        @bits of 8-bit color channel.
vmovn.i16   d4, q0      @remove remaining red and green bits by narrowing to 8 bits
{% endcodeblock %}

每个指令的效果都在上面备注中做了描述，但总而言之，每个通道上执行的运算为：

1. 利用移位推掉元素任意一端的位数，清除相邻通道的颜色数据。
2. 使用第二次移位将颜色数据放置到每个元素最重要的位上，并缩短位数将元素大小从 16 位减至 8 位。

请注意在这个顺序中使用元素大小来确定 8 位和 16 位元素的位置，以进行部分掩码运算。

### 从888到565

现在，我们来看反向运算，即从 RGB888 转换为 RGB565。这里，我们假设 RGB888 数据为上述代码产生的格式；在d0、d1和d2这三个寄存器上，每个寄存器均包含每种颜色的 8 个元素。结果将存储为 q2 格式的 8 个 16 位 RGB565 元素。  

{% codeblock lang:asm %}
vshll.u8    q2, d0, #8  @shift red element left to most-significant
                        @bits of wider 16-bit elements.
ushll.u8    q3, d1, #8  @shift green elements left to most-significant
                        @bits fo wider 16-bit elements
vsri.16    q2, q3, #5  @shift green elemnts right and insert into red
                        @ red elements.
vshll.u8    q3, d2, #8  @shift blue elements left to most-significant
                        @bits of wider 16-bit elements.
vsri.16     q2, q3, #11 @shift blue elements right and insert into
                        @ red and green elements.
{% endcodeblock %}

同样，每个指令的详细说明在备注中列出，但总而言之，对于每个通道而言：

1. 将每个元素的长度扩展到 16 位，并将颜色数据移至最重要的位上。
2. 使用插入右移位，将每个颜色通道放置到结果寄存器中。

## 结论

NEON 提供的强大的移位指令范围让你能够：

* 利用舍入和饱和，通过二次幂快速进行向量的除法和乘法运算。
* 通过移位将一个向量位复制到另一个向量位。
* 在高精度条件下进行临时计算，并在低精度条件下计算结果。


