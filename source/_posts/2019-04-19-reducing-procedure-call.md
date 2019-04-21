---
layout: post
title: "性能优化之减少调用"
date: 2019-04-19 09:59:18 -0700
comments: true
categories: 性能优化
---

* list element with functor item
{:toc}

函数调用会带来相当大的开销，而且它会阻碍其他形式的程序优化。单独的较少调用次数可能对性能提升并不明显，但考虑到减少调用后，可以进一步进行其他形式的优化，减少函数调用还是很有必要的。

<!--more-->

## 简单函数处理

* 直接将函数展开，写入调用函数处，去掉调用函数。

* 使用**inline**关键字，将经常调用的函数写成内联函数。

* 使用**define**关键字，使得代码在编译时将其展开。

例如，下面的函数调用

{% codeblock lang:c %}
int imin(const int a, const int b){
    return a < b ? a : b;
}

c = imin(a, b);
{% endcodeblock %}

可以使用上面提到的三种优化方式：

{% codeblock lang:c %}
// method 1
c = a < b ? a : b;
//method 2
static inline int imin(const int a const int b){
    return a < b ? a : b;
}
c = imin(a, b);
//method 3
#define IMIN(a, b) return ((a) < (b) ? (a) : (b))
c = IMIN(a, b);
{% endcodeblock %}

## 函数处理

上面的方法针对小函数、频繁调用的情况较试用，当函数较复杂时，我们就不适合直接展开了，那样会显得整个代码特别繁琐；另外如果被调用函数并不是我们自己的代码，就更没办法用上面提到的方法了。此时，就要分析函数的功能，选择替代方案减少调用。举个例子： 

{% codeblock lang:c %}
typedef struct{
    long int len;
    data_t *data;
}vec_rec, *vec_ptr;

vec_ptr new_vec(long int len)
{
    vec_ptr result = (vec_ptr)malloc(sizeof(vec_rec));
    if(!result)
        return NULL;
    result->len = len;
    if(len > 0){
        data_t *data = (data_t *)malloc(len, sizeof(data_t));
        if(!data){
            free((void *)result);
            return NULL;
        }
        result->data = data;
    }else{
        result->data = NULL;
    }
    return result;
}

int get_vec_element(vec_ptr v, long int index, data_t *dest)
{
    if(index < 0 || index >= v->len)
        return 0;
    *dest = v->data[index];
    return 1;
}

long int vec_length(vec_ptr v)
{
    return v->len;
}

void combine2(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);

    *dest = IDENT;
    for (i = 0; i < length; i++) {
        data_t val;
        get_vec_element(v, i, &val);
        *dest = *dest + val;
    }
}
{% endcodeblock %}

上面的`combine2`函数的 for 循环中会一直调用 **get_vec_element**函数来获取一个元素，通过分析该函数可以看出，它获取的其实是**vec_rec.v->data**数组的元素，该元素也是随着循环索引**i**来递增的，因此可以把该函数提到**for**循环的外面，减少函数调用，修改后的函数如下：  
{% codeblock lang:c %}
data_t *get_vec_start(vec_ptr v)
{
    return v->data;
}

void combine2_reducing_proc_call(vec_ptr v, data_t *dest)
{
    long int i;
    long int length = vec_length(v);
    data_t *data = get_vec_start(v);

    *dest = IDENT;
    for (i = 0; i < length; i++) {
        *dest = *dest + val;
    }
}
{% endcodeblock %}

分析上面的优化，其实它是破坏了函数的结构的，这种方法会损害函数的模块性和抽象性，上面的例子中，我们是通过分析`get_vec_element`函数和`for`循环才确定的减少调用是可用的。

### 减少调用后续优化

上面提到的都是针对减少调用本身来提升性能的，减少调用本身对系统性能的提升非常有限，但减少调用后，可以方便的进行进一步的优化，而进一步的优化可能效果非常显著。例如上面提到的 combine 函数，将调用函数提取到 for 循环外后，可以对整个 for 循环进行 NEON 优化，效率的提升会更加明显。

在做 AV1 效率优化时，也遇到过类似的优化案例：

{% codeblock lang:c %}
#define add_noise_y(x, y, grain)    \
    pixel *src = src_row + (y) * stride + (bx + x);  \
    pixel *dst = dst_row + (y) * stride + (bx + x);  \
    int noise  = round2(scaling[ *src ] * (grain), data->scaling_shift); \
    *dst = iclip(*src + noise, min_value max_value);

    for (int y = 0; y < bh; y++) {
        for (int x = 0; x < bw; x++) {
            int grain = sample_lut(grain_lut, offsets, 0, 0, 0, 0, x, y);
            add_noise_y(x, y, grain);
        }
    }
{% endcodeblock %}

未优化前，此段代码在解码过程中，大概耗时 8ms，优化完成后，降低到 7ms，效率提升了 12.5%。提升还是很大的。

## 总结

## 参考资料

