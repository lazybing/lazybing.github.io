---
layout: post
title: "FFmpeg 和 SDL 使用教程"
date: 2016-05-10 16:45:03 -0700
comments: true
categories: 项目实践
---

* list element with functor item
{:toc}

[FFmpeg](https://ffmpeg.org/) 是制作视频应用或一般工具的非常棒的库。[SDL](https://www.libsdl.org/) 通过封装复杂的视音频底层交互工作，降低了视音频的处理难度。

本文就记录一下利用 FFmpeg 和 SDL 制作简单播放器的详细步骤。<!--more-->

###介绍

对于一个视音频文件，可以从外到内的依次分为几个层面：container、stream、packets、frames.其中 container 就是平时说的`.avi` `.flv` `.mkv`等等。stream可能是 `video`、可能是 `audio`、也可能是 `subtitle`，一个文件里面可能包含多个 `video` `audio` `subtitle`。packets 是从 stream 里得到的，通常会包含一个 `video frame` 或多个 `audio frame`。

视音频的处理就是按照这几个层级处理的，以 `.avi` 为例大概步骤如下：

        1. OPEN video_stream FROM video.avi

        2. READ packet FROM video_stream INTO frame

        3. IF frame NOT COMPLETE GOTO 2

        4. DO SOMETHING WITH frame

        5. GOTO 2

当然，步骤 4 中的"DO SOMETHING"可能非常复杂，我们先简单的把得到的 frames 写到一个 PPM 文件中。

------------

###打开文件

想要利用FFmpeg，你必须首先初始化库。
{% codeblock lang:c %}
int main(int argc, char *argv[]){
av_register_all();
{% endcodeblock %}
`av_register_all()`用于注册所有编译过的`muxers` `demuxers`和`protocols`，同时，该函数还会调用`avcodec_register_all()`注册所有的音视频 codec。

现在就可以打开视频文件了。
{% codeblock lang:c %}
AVFormatContext *pFormatCtx = NULL;

//open video file
if(avformat_open_input(&pFormatCtx, argv[1], NULL, 0, NUL) != 0)
        return -1; //Couldn't open file
{% endcodeblock %}
调用函数 `avformat_open_input`,该函数读取文件头部，并将文件的格式信息存储到`AVFormatContext`结构中。最后的三个参数分别用于指定文件格式、内存大小和格式选项，此处设为`NULL`或 0，`libavformat`能够自动侦测到。

该函数只是简单的查看头部信息，接下来我们需要文件中码流的信息：
{% codeblock lang:c %}
//Retrieve stream information
if(avformat_find_stream_info(pFormatCtx, NULL) < 0)
        return -1;      //Couldn't find stream information
{% endcodeblock %}
该函数用适当的信息填充`pFormatCtx->streams`。此处介绍一个便于调试的函数来看一下里面的内容：
{% codeblock lang:c %}
//Dump information about file onto standard error
av_dump_format(pFormatCtx, 0, argv[1], 0);
{% endcodeblock %}
现在`pFormatCtx->streams`仅仅是一个数组指针，数组大小为`pFormatCtx->nb_streams`,遍历该数组直到找到一个视频流。
{% codeblock lang:c %}
int i;
AVCodecContext *pCodecCtxOrig = NULL;
AVCodecContext *pCodecCtx     = NULL;

//Find the first video stream
videoStream = -1;
for(i = 0; i < pFormatCtx->nb_streams; i++)
	if(pFormatCtx->streams[i]->codec->codec_type = AVMEDIA_TYPE_VIDEO){
		videoStream = i;
		break;
	}
if(videoStream == -1)
	return -1; //Didn't find a video stream
	
// Get a pointer to the codec context for the video stream
pCodecCtx = pFormatCtx->streams[videoStream]->codec;
{% endcodeblock %}
关于`codec`的流信息我们称之为`codec context`。它包含了关于流使用的该`codec`的所有信息，并且我们有一个指针指向它。但我们必须找到实际的codec并打开它：
{% codeblock lang:c %}
AVCodec *pCodec = NULL;

// Find the decoder for the video stream
pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
if(pCodec == NULL){
	fprintf(stderr, "Unsupported codec!\n");
	return -1;	// Codec not found
}

// Copy context
pCodecCtx = avcodec_alloc_context3(pCodec);
if(avcodecc_copy_context(pCodecCtx, pCodecCtxOrig) != 0){
	fprintf(stderr, "Couldn't copy codec context");
	return -1;	// Error copying codec context
}

//Open codec
if(avcodec_open2(pCodecCtx, pCodec) < 0)
	return -1;	// Could not open codec
{% endcodeblock %}
因为不能直接使用视频流的`AVCodecContext`！因此必须使用`avcodec_copy_context()`来 copy 该 context 到一个新位置。

----

###存储数据

现在我们需要一块内存来真实的存储这些帧：
{% codeblock lang:c %}
AVFrame *pFrame = NULL;

//Allocate video frame
pFrame = av_frame_alloc();
{% endcodeblock %}
既然我们想要输出 PPM 文件（被存储为 24-bit RGB），我们必须将帧从它原本格式转换为 RGB。FFmpeg 可以为我们做这种转换。对于大多数项目，会将初始帧转换为特定格式。让我们分配一帧来为转换帧。
{% codeblock lang:c %}
// Allocate an AVFrame structure
pFrameRGB = av_frame_alloc();
if(pFrameRGB == NULL)
	return -1;
{% endcodeblock %}
尽管我们已经分配了帧，仍然需要一块内存存放 raw data 信息。我们使用 avpicture_get_size 来获得我们需要的大小，并手动分配该内存。
{% codeblock lang:c %}
uint8_t *buffer = NULL;
int numBytes;
//Determine required buffer size and allocate buffer
numBytes = avpicture_get_size(PIX_FMT_RGB24, pCodecCtx->width, pCodecCtx->height);
buffer = (uint8_t *)av_malloc(numBytes * sizeof(uint8_t));
{% endcodeblock %}
`av_malloc`是 FFmpeg 的分配函数，它简单封装了 malloc 函数并做内存对齐，并不会保护内存泄漏、多次释放内存或者其他分配问题。

现在我们使用`avpicture_fill`来将帧和新分配的内存联系起来。关于`AVPicture`强制转换：`AVPicture`结构是`AVFrame`结构体的子集——`AVFrame`结构的开始对于`AVPicture`结构来说是唯一的。
{% codeblock lang:c %}
// Assign appropriate parts of buffer to image planes in pFrameRGB
// Note that pFrameRGB is an AVFrame, but AVFrame is a superset of AVPicture
avpicture_fill((AVPicture *)pFrameRGB, buffer, PIX_FMT_RGB24, pCodecCtx->width, pCodecCtx->height);
{% endcodeblock %}
最后，我们读取码流。

----

###读取数据

我们接下来要做的就是通过读`packet`中的整个视频流，解码到帧，一旦我们的帧完成后，就转换并保存它。
{% codeblock lang:c %}
struct SwsContext *sws_ctx = NULL;
int frameFinished;
AVPacket packet;
// initialize SWS context for software scaling
sws_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, PIX_FMT_RGB24, SWS_BILINEAR, NULL, NULL, NULL);

i = 0;
while(av_read_frame(pFormatCtx, &packet) >= 0){
	// Is this a packet from the video stream?
	if(packet.stream_index == videoStream){
		//Decode video frame
		avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);
		
		//Did we get a video frame?
		if(frameFinished){
			//Convert the image from its native format to RGB
			sws_scale(sws_ctx, (uint8_t const * contst *)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameRGB->data, pFrameRGB->linesize);
			
			// Save the frame to disk
			if(++i <= 5)
			SaveFrame(pFrameRGB, pCodecCtx->widht, pCodecCtx->height, i);
		}
	}
	// Free the packet that was allocated by av_read_frame
	av_free_packet(&packet);
}
{% endcodeblock %}

这一过程仍然比较简单：`av_read_frame` 读取`packet`并把它保存到`AVPacket`结构体内。注意我们已经分配了`packet`结构体，它是用`packet.data`指针指出的，它由`av_free_packet`释放。`avcodec_decode_video`将`packets`转换为`frame`。最后，使用`sws_scale`转换原始格式为`RGB`。记住，你可以将`AVFrame`强制类型转换为`AVPicture`指针。最后要做的就是把`frame`和宽高信息传递给`SaveFrame`函数。

{% codeblock lang:c %}
void SaveFrame(AVFrame *pFrame, int width, int height, int iFrame){
    FILE *pFile;
    char szFilename[32];
    int y;

    //Open file
    sprintf(szFilename, "frame%d.ppm", iFrame);
    pFile = fopen(szFilename, "wb");
    if(pFile == NULL)
        return;

    //Wirte header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);

    //Write piexl data
    for(y = 0; y < height; y++)
        fwrite(pFrame->data[0] + y*pFrame->linesize[0], 1, width*3, pFile);

    //Close file
    fclose(pFile);
}
{% endcodeblock %}

### 清除工作

{% codeblock lang:c %}
//Free the RGB image
av_free(buffer);
av_free(pFrameRGB);

//Free the YUV frame
av_free(pFrame);

//Close the codecs
avcodec_close(pCodecCtx);
avcodec_close(pCodecCtxOrig);

//Close the video file
avformat_close_input(&pFormatCtx);

return 0;
{% endcodeblock %}

### 程序编译

```
gcc -o tutorial01 tutorial01.c -lavutil -lavformt -lavcodec -lswscale-lz -lm
```

### 注意事项

本文主要参考`FFmpeg`官方文档[An ffmpeg and SDL Tutorial](http://dranger.com/ffmpeg/tutorial01.html), 改动有：1.将其中的`PIX_FMT_RGB24`改为`AV_PIX_FMT_RGB24`; 2.编译选项添加了`-lswscale`。
