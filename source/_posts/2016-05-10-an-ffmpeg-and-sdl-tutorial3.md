---
layout: post
title: "FFmpeg 和 SDL 使用教程（三）"
date: 2016-05-10 17:22:59 -0700
comments: true
categories: 项目实践
---

* list element with functor item
{:toc}

接下来继续实现播放器的另一个功能：音频播放。  

<!--more-->

## 音频

接下来需要添加音频。`SDL`同样给了我们输出音频的方法，`SDL_OpenAudio()`函数用来打开音频设备，它接收`SDL_AudioSpec()`结构体作为函数的参数，该结构体包含了输出的音频的所有信息。  

开始之前，我们先来看一下音频是如何被计算机处理的。数字音频包含一些列的长流的采样，每个采样代表着音频波的大小。声音按照一个固定的采样率被记录，该采样率代表着播放的速度，表示每秒钟的采样个数。比如
采样率是每秒钟 22050 和 44100，它们分别是无线电广播和 CD 的采样率。此外，很多立体声可能包含不止一个音频频道。  

## 创建音频  

暂时把这些都记在脑子里，因为现在我们还没有任何关于音频流的信息。让我们回到代码中关于寻找视频流的地方，并找到那个流是音频流。  

{% codeblock lang:c find_audio_video_stream %}
// Find the first video stream
videoStream = -1;
audioStream = -1;
for(i = 0; i < pFormatCtx->nb_streams; i++){
    if(pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO
       && videoStream < 0){
        videoStream = i;
    }
    if(pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO
       && audioStream < 0){
        audioStream = i;
    }
}

if(videoStream == -1)
    return -1; //Didn't find a video stream
if(audioStream == -1)
    return -1;
{% endcodeblock %}

找到音频流后，就可以从音频流里获取我们所需要的`AVCodecContext`的所有信息，就像获取视频流的信息类似：  

{% codeblock lang:c %}
AVCodecContext *aCodecCtxOrig;
AVCodecContext *aCodecCtx;
aCodecCtxOrig = pFormatCtx->streams[audioStream]->codec;
{% endcodeblock %}

同样的，与视频相似，我们同样需要打开音频。  

{% codeblock lang:c %}
AVCodec *aCodec;
aCodec = avcodec_find_decoder(aCodecCtx->codec_id);
if(!aCodec){
    fprintf(stderr, "Unsupported codec!\n");
    return -1;
}
//copy context
aCodecCtx = avcodec_alloc_context3(aCodec);
if(avcodec_copy_context(aCodecCtx, aCodecCtxOrig) != 0){
    fprintf(stderr, "Couldn't copy codec context");
    return -1; //Error copying codec context
}

/*set up SDL Audio here*/

avcodec_open2(aCodecCtx, aCodec, NULL);
{% endcodeblock %}

`Codec Context`中的信息包含了所有我们需要用于初始化音频的信息：  

{% codeblock lang:c %}
wanted_spec.freq = aCodecCtx->sample_rate;
wanted_spec.format = AUDIO_S16SYS;
wanted_spec.channels = aCodecCtx->channels;
wanted_spec.silence = 0;
wanted_spec.samples = SDL_AUDIO_BUFFER_SIZE;
wanted_spec.callback = audio_callback;
wanted_spec.userdata = aCodecCtx;

if(SDL_OpenAudio(&wanted_spec, &spec) < 0){
    fprintf(stderr, "SDL_OpenAudio:%s\n", SDL_GetError());
    return -1;
}
{% endcodeblock %}

其中：  

* freq:采样率。
* format：告诉`SDL`我们将采用的格式。`S16SYS`中的`S`是`signed`的缩写。数字 16 表示每个采样占 16 位;`SYS`指大小端与系统本身有关。
* channels: 声道数。  
* silence:
* samples:音频空间的大小，一般大小控制在 512 至 8192,`ffplay`使用 1024。
* callback:此处给真实的回调函数，稍后会详细的介绍该函数。
* userdata:

最后，使用`SDL_OpenAudio`打开音频。  

## Queues

现在我们需要从流中获取音频信息，接下来，我们将不断的从电影文件中获取数据包，但同时`SDL`会调用回调函数。我们需要做的是创建数据包队列。
`FFMpeg`有一个数据结构`AVPacketList`帮助我们，它是一个数据包的链表。队列数据结构体为：  

```
typedef struct PacketQueue{
    AVPacketList *first_pkt, *last_pkt;
    int nb_packets;
    int size;
    SDL_mutex *mutex;
    SDL_cond *cond;
}PacketQueue;
```

注意，`nb_packets`与`size`不同，`size`是从`packet->size`中获取的字节大小。该结构体中有`mutex`和`condition variable`，因为`SDL`处理音频是一个独立分开的线程。
如果不锁住该队列，会有死锁等问题。后面会有队列的实现。

首先，初始化队列：  

{% codeblock lang:c %}
void packet_queue_init(PacketQueue *q){
    memset(q, 0, sizeof(PacketQueue));
    q->mutext = SDL_CreateMutex();
    q->cond   = SDL_CreateCond();
}
{% endcodeblock %}

之后，填充初始化的队列：  

{% codeblock lang:c %}
int packet_queue_put(PacketQueue *q, AVPacket *pkt){
    AVPacketList *pkt1;
    if(av_dup_packet(pkt) < 0){
        return -1;
    }
    pkt1 = av_malloc(sizeof(AVPacketList));
    if(!pkt1)
        return -1;
    pkt1->pkt = *pkt;
    pkt1->next = NULL;

    SDL_LockMutex(q->mutex);

    if(!q->last_pkt)
        q->first_pkt = pkt1;
    else
        q->last_pkt->next = pkt1;
    q->last_pkt = pkt1;
    q->nb_packets++;
    q->size += pkt1->pkt.size;
    SDL_CondSignal(q->cond);

    SDL_UnlockMutex(q->mutex);
    return 0;
}
{% endcodeblock %}

`SDL_LockMutex()`锁住队列中的互斥体，此时可以往队列中添加信息；之后用`SDL_CondSignal()`通过条件变量发送信号给获取函数，通知它有数据可以处理，之后释放互斥体。

获取函数定义如下：  

{% codeblock lang:c %}
int quit = 0;
static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block){
    AVPacketList *pkt1;
    int ret;

    SDL_LockMutex(q->mutex);

    for(;;){
        if(quit){
            ret = -1;
            break;
        }

        pkt1 = q->first_pkt;
        if(pkt1){
            q->first_pkt = pkt1->next;
            if(!q->first_pkt)
                q->last_pkt = NULL;
            q->nb_packets--;
            q->size -= pkt1->pkt.size;
            *pkt = pkt1->pkt;
            av_free(pkt1);
            ret = 1;
            break;
        }else if(!block){
            ret = 0;
            break;
        }else{
            SDL_CondWait(q->cond, q->mutex);
        }
    }
    SDL_UnlockMutex(q->mutex);
    return ret;
}
{% endcodeblock %}

如上面所示，将函数封装为一个死循环中，目的是如果要 block 住，就一定要获取数据。为避免陷入死循环，我们使用了`SDL_CondWait()`函数，它的基本作用就是等待`SDL_CondSignal()`给的信号，之后继续。
如果我们此处拿着锁，put 函数就无法向队列中添加任何东西，看起来此时处于死锁状态，其实`SDL_CondWait()`同样会解锁互斥体，一旦获得信号量，之后会再次锁住.  

## In Case of Fire

我们有一个全局变量`quit`，可以通过检测该变量的来确认是否设置了程序的退出信号。如果未设置，程序将一直运行下去。  

{% codeblock lang:c %}
SDL_PollEvent(&event);
switch(event.type){
    case SDL_QUIT:
        quit = 1;
}
{% endcodeblock %}

## Feeding Packets

剩下的唯一事情就是启动队列：  

{% codeblock lang:c %}
PacketQueue audioq;
main(){
    ...
    avcodec_open2(aCodecCtx, aCodec, NULL);

    packet_queue_init(&audioq);
    SDL_PauseAudio(0);
}
{% endcodeblock %}

`SDL_PauseAudio()`最后启动音频设备，如果没有得到数据，它就不会播放声音。  

现在已经初始化了队列，接下来就可以向队列中填充数据包。数据包读取循环如下：  

{% codeblock lang:c %}
while(av_read_frame(pFormatCtx, &packet) >= 0){
    if(packet.stream_index == videoStream){
        //Decode video frame
    }else if(packet.stream_index == audioStream){
        packet_queue_put(&audioq, &packet);
    }else{
        av_free_packet(&packet);
    }
}
{% endcodeblock %}
注意，此处将数据包`packet`放到队列后，并没有立即释放。该`packet`会在稍后的解码时释放掉。  

## Fetching Packets

最后，让我们完成`audio_callback`函数来从队列中拉取数据包。回调函数必须是如下格式`void callback(void *userdata, Uint8 *stream, int len)`,此处的`userdata`是我们给 SDL 的指针，`stream`是将音频数据写到的缓存，`len`是缓存的长度。代码如下：  

{% codeblock lang:c %}
void audio_callback(void *userdata, Uint8 *stream, int len){
    AVCodecContext *aCodecCtx = (AVCodecContext *)userdata;
    int len1, audio_size;

    static uint8_t audio_buf[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3)/2];
    static unsigned int audio_buf_size = 0;
    static unsigned int audio_buf_index = 0;

    while(len > 0){
        if(audio_buf_index >= audio_buf_size){
            /*we have already sent all our data; get more*/
            audio_size = audio_decode_frame(aCodecCtx, audio_buf, sizeof(audio_buf));

            if(audio_size < 0){
                /*If error, output silence*/
                audio_buf_size = 1024;
                memset(audio_buf, 0, audio_buf_size);
            }else{
                audio_buf_size = audio_size;
            }
            audio_buf_index = 0;
        }
        len1 = audio_buf_size - audio_buf_index;
        if(len1 > len)
            len1 = len;
        memcpy(stream, (uint8_t *)audio_buf + audio_buf_index, len1);
        len -= len1;
        stream += len1;
        audio_buf_index += len1;
    }
}
{% endcodeblock %}

这是简单的循环，从`audio_decode_frame()`中拉取数据，存储结果到一个中间缓存中，并写`len`字节到`stream`中。如果没有足够的数据，就获取更多数据。如果有剩余的数据，同样要保存下来。
`audio_buf`的大小是 1.5 倍的最大音频帧的大小，这样会有一个更好的缓冲效果。  


## Finally Decoding the Audio

最后让我们看一下真真的音频解码器`audio_decode_frame`的实现：

{% codeblock lang:c %}
int audio_decode_frame(AVCodecContext *aCodecCtx, uint8_t *audio_buf, 
                       int buf_size){
    static AVPacket pkt;
    static uint8_t *audio_pkt_data = NULL;
    static int audio_pkt_size = 0;
    static AVFrame frame;

    int len1, data_size = 0;

    for(;;){
        while(audio_pkt_size > 0){
            int go_frame = 0;
            len1 = avcodec_decode_audio4(aCodecCtx, $frame, &got_frame, &pkt);
            if(len1 < 0){
                /*if error, skip frame*/ 
                audio_pkt_size = 0;
                break;
            }
            audio_pkt_data += len1;
            audio_pkt_size -= len1;
            data_size = 0;
            if(got_frame){
                data_size = av_samples_get_buffer_size(NULL,
                                                       aCodecCtx->channels,
                                                       frame.nb_samples,
                                                       aCodecCtx->sample_fmt,
                                                       1);    
                assert(data_size <= buf_size);
                memcpy(audio_buf, frame_data[0], data_size);
            }
            if(data_size <= 0){
                /*No data yet, get more frames*/
                continue;
            }
            /*we have data, return it and come back for more later*/
            return data_size;
        }

        if(pkt.data)
            av_free_packet(&pkt);

        if(quit){
            return -1;
        }

        if(packet_queue_get(&audioq, &pkt, 1) < 0){
            return -1;
        }
        audio_pkt_data = pkt.data;
        audio_pkt_size = pkt.size;
    }
}
{% endcodeblock %}

整个函数实际上从函数的末尾开始，调用`packet_queue_get()`，从队列中挑选数据包，并保存其信息。一旦有了可以处理的数据包，就调用
`avcodec_decode_audio4()`,它的功能与函数`avcodec_decod_video()`类似，只有一点略微不同，即当数据包中包含多帧时,此时必须多次调用该函数以得到数据包的所有数据。一旦获取帧，就将获取的数据拷贝到音频缓存，但要确保`data_size`比音频缓存小。
记得计算`audio_buf`的大小，因为`SDL`给出了一个 8bit 的缓存，而`ffmpeg`给出了一个 16bit 的缓存。而且要注意，`len1`和`data_size.len1`的差值就是我们已经消耗的数据的大小，而`data_size`即为返回的原始数据的大小。  

一旦得到数据，立即查看是否需要从队列中获取更多的数据。如果需要更多的数据包处理，就先保存下来以便后续处理。一旦完成了一个数据包，就释放掉它。  

总结，首先通过读循环获取音频数据到队列，之后通过`audio_callback`函数读数据，它处理数据到`SDL`，最后`SDL`将收到的数据送到声卡。

编译：

```
gcc -o tutorial03 tutorial03.c -lavutil -lavformat -lavcodec -lswscale -lz -lm  `sdl-config --cflags --libs`
```

现在，视频仍然播放非常快，而音频按照实际的时间在播放。原因是音频信息里会有采样率的标识。接下来，就可以同步音视频的数据了，但在此之前，我们需要
重新组织该程序，单独的使用一个线程来处理音频数据是个非常好的主意，它使得程序更易于管理、更加模块化。因此，在对音视频进行同步之前，首先要使得代码更易于处理，下一步：`Spawning Threads!`;

