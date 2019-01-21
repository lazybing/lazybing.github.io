---
layout: post
title: "NEON 编程2——处理多余的数据"
date: 2019-01-20 00:56:44 -0800
comments: true
categories: 汇编学习
---

上一篇关于NEON 加载和存储的文章中，在NEON 处理单元（寄存器）和内存之间进行数据传输。这篇文章中，我们会处理经常遇到的问题：输入数据并不对齐，也就是输入数据的长度并不是向量长度的整数倍。我们需要在数组开始或结束的位置处理剩余的元素。使用 NEON 哪种方式最有效呢？

<!--more-->

使用 NEON 处理数据时，通常处理的数据向量的长度从 4 个元素到 16 个元素。通常情况下，你会发现数据的实际长度并不是切好等于寄存器向量长度的倍数，你必须单独处理剩余的元素。  

例如，你想要使用 NEON 每次加载、处理、存储 8 个元素，但你的数组有 21 个元素的长度。前面 2 组能够正常处理，但对第 3 个，还剩下 5 个元素没有处理。你要怎么做呢？

## 修复数据(Fixing Up)

有三种方法来处理剩余的数据，三种方法的需求、性能和代码大小都不相同，分别是`Larger Arrays`、`Overlapping`、`Single Elements`，第一种方法效率最高。

### Larger Arrays

如何可以改变处理数组的大小，使用填充元素增加数组的长度到下一个向量大小的倍数，就可以读写超出数据本身的边界而不会影响相邻的存储。下面的例子中，增加元素到 24 个元素是的第三组可以很好地完成而不会有数据损坏。

{% img /images/neon_deal_leftovers/larger_array.png %}

#### Notes

* 分配更大的数组会消耗更大的内存。
* 新的填充数据需要在初始化时给定一个值，该值不能够影响最后的计算结果。例如，如果是求和，填充数据就只能填充为 0.如果是要找到数组里面的最小值，可以设置填充数据为可以获取的最大值。
* 某些情况下，没办法给定一个填充数据一个初始值，不影响最终结果，比如查找数据的范围时。

#### Code Fragment

{% codeblock %}
@ r0 = input array pointer
@ r1 = output array pointer
@ r2 = length of data in array

@ We can assume that the array length is greater than zero, is an integer
@ number of vectors, and is greater than or equal to the length of data
@ in the array.

    add r2, r2, #7      @ add (vector length - 1) to the data length
    lsr r2, r2, #3      @ divide the length of the array by the length
                        @ of a vector, 8, to find the number of
                        @ vectors of data to be processed
loop:
    subs r2, r2, #1     @ decrement the loop counter, and set flags
    vld1.8 {d0}, [r0]!  @ load eight elements from the array pointed to
                        @ by r0 into d0, and update r0 to point to the next vector
    ...
    ...                 @ process the input in d0
    ...
    vst1.8 {d0}, [r1]!  @ write eight elements to the output array, and 
                        @ update r1 to point to next vector
    bne loop            @ if r2 is not equal to 0, loop
{% endcodeblock %}

### Overlapping

如果操作合适，剩余元素可以使用重叠的方法来处理。这会对数组中的某些元素进行两次处理。

示例中，第一组处理元素从0-7，第二组处理元素从5-12，第三组处理元素是13-20。注意，第5-7个元素，在第一次和第二次处理的向量中有重合，它们处理了两次。

{% img /images/neon_deal_leftovers/neon_overlapping.png %}

#### Notes

* Overlapping 方法只有当输入数据的操作应用不会受操作次数的改变而改变时才能使用；例如，如果想要找到最大值可以使用该方法，而求和操作就不能使用该方法，因为 overlapping 会计算元素两次。
* 数组中的元素数量至少能够填充一个完整的向量。

#### Code Fragment

{% codeblock %}
@ r0 = input array pointer
@ r1 = output array pointer
@ r2 = length of data in array

@ We can assume that the operation is idempotent, and the array is greater
@ than or equal to one vector long.

    ands r3, r2, #7     @ calculate number of elements left over after
                        @ processing complete vectors using
                        @ data length & (vector length - 1)
    beq loopsetup       @ if the result of the ands is zero, the length
                        @ of the data is an integer number of vectors,
                        @ so there is no overlap, and processing can begin at the loop
                        @ handle the first vector separately
    vld1.8 {d0}, [r0], r3   @ load the first eight elements from the array,
                            @ and update the pointer by the number of elements left over
    ...
    ...                     @ process the input in d0
    ...
    vst1.8  {d0}, [r1], r3  @ wirte eight elements to the output array, and
                            @ update the pointer
                            @ now, set up the vector processing loop
 loopsetup:
     lsr  r2, r2, #3      @ divide the length of the array by the length
                             @  of a vector, 8, to find the number of
                             @  vectors of data to be processed
 
                             @ the loop can now be executed as normal. the
                             @  first few elements of the first vector will
                             @  overlap with some of those processed above
 loop:
     subs    r2, r2, #1      @ decrement the loop counter, and set flags
     vld1.8  {d0}, [r0]!  @ load eight elements from the array, and update
                             @  the pointer
     ...
     ...                  @ process the input in d0
     ...
 
     vst1.8  {d0}, [r1]!  @ write eight elements to the output array, and
                             @  update the pointer
     bne  loop            @ if r2 is not equal to 0, loop
 
{% endcodeblock %}

### Single Elements

NEON 提供的加载和存储指令可以对向量中的某个元素进行操作。使用这个操作，可以加载向量的单个元素，在上面执行操作，并把元素写会内存。

示例中的问题是，前面两组数据能够正常执行(0-7元素、8-15元素)。第三组需要处理剩余的 5 个元素，它们是单独的循环中处理的，每次都执行加载、处理和存储元素。

{% img /images/neon_deal_leftovers/neon_single_element.png %}

#### Notes

* 该方法比上面提到的方法要效率低，因为每个元素都单独执行加载、处理和存储。
* 处理剩余的元素需要两个循环——一个是向量、另一个是单个元素，这回增加函数中的代码量

{% codeblock %}

 @ r0 = input array pointer
 @ r1 = output array pointer
 @ r2 = length of data in array
 
     lsrs    r3, r2, #3      @ calculate the number of complete vectors to be
                             @  processed and set flags
     beq  singlesetup  @ if there are zero complete vectors, branch to
                             @  the single element handling code
 
                             @ process vector loop
 vectors:
     subs    r3, r3, #1      @ decrement the loop counter, and set flags
     vld1.8  {d0}, [r0]!  @ load eight elements from the array and update
                             @  the pointer
     ...
     ...                  @ process the input in d0
     ...
 
     vst1.8  {d0}, [r1]!  @ write eight elements to the output array, and
                             @  update the pointer
     bne  vectors      @ if r3 is not equal to zero, loop
 
 singlesetup:
     ands    r3, r2, #7      @ calculate the number of single elements to process
     beq  exit            @ if the number of single elements is zero, branch
                             @  to exit
 
                             @ process single element loop
 singles:
     subs    r3, r3, #1      @ decrement the loop counter, and set flags
     vld1.8  {d0[0]}, [r0]!  @ load single element into d0, and update the
                             @  pointer
     ...
     ...                  @ process the input in d0[0]
     ...
 
     vst1.8  {d0[0]}, [r1]!  @ write the single element to the output array,
                             @  and update the pointer
     bne  singles      @ if r3 is not equal to zero, loop
 
 exit:
 
{% endcodeblock %}

### Further Considerations

#### Beginning or End

Overlapping 和 single element 技术可以应用到处理数组的开始或结束位置。如何应用程序更适合处理结束端，上面的代码可以很容易的改成处理末端的元素。

#### Alignment

加载和存储地址应该与高速缓存线对齐，这样会使得内存访问更加高效。 

对于 Cortex-A8，至少要 16 字节对齐，如果在输入或输出数组的开始位置没有对齐，就必须在数组的开始和结束位置处理元素。

当对齐内存来加速时，记得使用加载和存储指令时加上`:64`或`:128`或`:256`。

#### Using Arm to Fix Up

在使用`single elements`方法时，你可以使用 Arm 指令来对每个元素进行单独处理。然而，同时使用 Arm 指令和 NEON 指令来存储相同的内存会降低效率，因为通过 Arm 管道来写必须在 NEON 管道写完后才能进行。

一般情况下，应该避免同时使用 Arm 和 NEON 代码写到相同的内存区域，尤其是同一个高速缓存区域。

