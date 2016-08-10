---
layout: post
title: "AVCodecContext 结构体解析"
date: 2016-07-01 10:16:42 -0700
comments: true
categories: FFMPEG源码分析
---

AVCodecContext 可能是最复杂的结构体了。
<!--more-->

{% codeblock lang:c %}
typedef struct AVCodecContext{
	const AVClass *av_class;
	int log_level_offset;
	enum AVMediaType codec_type;
	const struct AVCodec *codec;
	enum AVCodecID     codec_id;
	unsigned int codec_tag;
	void *priv_data;
	struct AVCodecInternal *internal;
	void *opaque;
	int bit_rate;
	int bit_rate_tolerance;
	int global_quality;
	int compression_level;
	int flags;
	int flags2;
	uint8_t *extradata;
	int extradata_size;
	AVRational time_base;
	int ticks_per_frame;
	int delay;
	int width, height;
	int coded_width, coded_height;
	int gop_size;
	enum AVPixelFormat pix_fmt;
	void (*draw_horiz_band)(struct AVCodecContext *s,
                            const AVFrame *src, int offset[AV_NUM_DATA_POINTERS],
                            int y, int type, int height);
	enum AVPixelFormat (*get_format)(struct AVCodecContext *s, const enum AVPixelFormat * fmt);
	int max_b_frames;
	float b_quant_factor;
	int b_frame_strategy;
	float b_quant_offset;
	int has_b_frames;
	int mpeg_quant; 		/*decoding: unused*/
	float i_quant_factor; 	/*decoding: unused*/
	float i_quant_offset; 	/*decoding: unused*/
	float lumi_masking;		/*decoding: unused*/
	float temporal_cplx_masking; /*decoding: unused*/
	float spatial_cplx_masking;  /*decoding: unused*/
	float p_masking;		/*decoding: unused*/
	float dark_masking;		/*decoding: unused*/
	int slice_count;
	int prediction_method;	/*decoding: unused*/
	int *slice_offset;
	AVRational sample_aspect_ratio;
	int me_cmp;				/*decoding: unused*/
	int me_sub_cmp;			/*decoding: unused*/
	int mb_cmp;				/*decoding: unused*/
	int ildct_cmp;			/*decoding: unused*/
	int dia_size;			/*decoding: unused*/
	int last_predictor_count;	/*decoding: unused*/
	int pre_me;				/*decoding: unused*/
	int me_pre_cmp;			/*decoding: unused*/
	int pre_dia_size;		/*decoding: unused*/
	int me_subpel_quality;	/*decoding: unused*/
	int me_range;			/*decoding: unused*/
	int slice_flags;
	int mb_decision;
	uint16_t *intra_matrix;
	uint16_t *inter_matrix;
	int scenechange_threshold;	/*decoding: unused*/
	int noise_reduction;		/*decoding: unused*/
	int intra_dc_precision;
	int skip_top;
	int skip_bottom;
	int mb_lmin;			/*decoding: unused*/
	int mb_lmax;			/*decoding: unused*/
	int me_penalty_compensation;	/*decoding: unused*/
	int bidir_refine;		/*decoding: unused*/
	int brd_scale;			/*decoding: unused*/
	int keyint_min;			/*decoding: unused*/
	int refs;
	int chromaoffset;		/*decoding: unused*/
	int mv0_threshold;		/*decoding: unused*/
	int b_sensitivity;		/*decoding: unused*/
	enum AVColorPrimaries color_primaries;
	enum AVColorTransferCharacteristic color_trc;
	enum AVColorSpace colorspace;
	enum AVColorRange color_range;
	enum AVChromaLocation chroma_sample_location;
	int slices;				/*decoding: unused*/
	enum AVFieldOrder field_order;
	int sample_rate;		/* audio only */
	int channels; 			/* audio only */
	enum AVSampleFormat sample_fmt;
	int frame_size;
	int frame_number;
	int block_align;
	int cutoff;				/*decoding: unused*/
	uint64_t channel_layout;	/* audio */
	uint64_t request_channel_layout;
	enum AVAudioServiceType audio_service_type;
	enum AVSampleFormat request_sample_fmt;
	int (*get_buffer2)(struct AVCodecContext *s, AVFrame *frame, int flags);
	int refcounted_frames;
	float qcompress;	/* - encoding parameters */
	float qblur; 		/* - encoding parameters */
	int qmin;			/*decoding: unused*/
	int qmax;			/*decoding: unused*/
	int max_qdiff; 		/*decoding: unused*/
	int rc_buffer_size;		/*decoding: unused*/
	int rc_override_count;	/*decoding: unused*/
	RcOverride *rc_override;/*decoding: unused*/
	int rc_max_rate;
	float rc_max_available_vbv_use;	/*decoding: unused*/
	float rc_min_vbv_overflow_use;	/*decoding: unused*/
	int rc_initial_buffer_occupancy;/*decoding: unused*/
	int coder_type;				/*decoding: unused*/
	int context_model;			/*decoding: unused*/
	int frame_skip_threshold;	/*decoding: unused*/
	int frame_skip_factor;		/*decoding: unused*/
	int frame_skip_exp;			/*decoding: unused*/
	int frame_skip_cmp;			/*decoding: unused*/
	int trellis;				/*decoding: unused*/
	int min_prediction_order;	/*decoding: unused*/
	int max_prediction_order;	/*decoding: unused*/
	int64_t timecode_frame_start;
	void (*rtp_callback)(struct AVCodecContext *avctx, void *data, int size, int mb_nb);
	int rtp_payload_size;
    
	/* statistics, used for 2-pass encoding */
    int mv_bits;
    int header_bits;
    int i_tex_bits;
    int p_tex_bits;
    int i_count;
    int p_count;
    int skip_count;
    int misc_bits;

	int frame_bits;		/*decoding: unused*/
	char *stats_out;	/*decoding: unused*/
	char *stats_in;		/*decoding: unused*/
	
	int workaround_bugs;
	int strict_std_compliance;
	int error_concealment;
	int debug;
	int64_t reordered_opaque;
	struct AVHWAccel *hwaccel;
	void *hwaccel_context;
	uint64_t error[AV_NUM_DATA_POINTERS]; /*decoding: unused*/
	int dct_algo;	/*decoding: unused*/
	int idct_algo;
	int bits_per_coded_sample;
	int bits_per_raw_sample;
	int thread_count;
	int thread_type;
	int active_thread_type;
	int thread_safe_callbacks;
	int (*execute)(struct AVCodecContext *c, int (*func)(struct AVCodecContext *c2, void *arg), void *arg2, int *ret, int count, int size);
	int (*execute2)(struct AVCodecContext *c, int (*func)(struct AVCodecContext *c2, void *arg, int jobnr, int threadnr), void *arg2, int *ret, int count);
	int nsse_weight;	/*decoding: unused*/
	int profile;
	int level;
	enum AVDiscard skip_loop_filter;
	enum AVDiscard skip_idct;
	enum AVDiscard skip_frame;
	uint8_t *subtitle_header;
	int subtitle_header_size;
	uint64_t vbv_delay;		/*decoding: unused*/
	int side_data_only_packets;
	int initial_padding;
	AVRational framerate;
	enum AVPixelFormat sw_pix_fmt;
	AVRational pkt_timebase;
	const AVCodecDescriptor *codec_descriptor;

    int64_t pts_correction_num_faulty_pts; /// Number of incorrect PTS values so far
    int64_t pts_correction_num_faulty_dts; /// Number of incorrect DTS values so far
    int64_t pts_correction_last_pts;       /// PTS of the last frame
    int64_t pts_correction_last_dts;       /// DTS of the last frame

	char *sub_charenc;
	int sub_charenc_mode;
	int skip_alpha;
	int seek_preroll;
	int debug_mv;
	uint16_t *chroma_intra_matrix;
	uint8_t *dump_separator;
	char *codec_whitelist;
	unsigned properties;
		
}
{% endcodeblock %}
