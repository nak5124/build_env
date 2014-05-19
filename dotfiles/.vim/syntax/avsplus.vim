" vim syntax file
" Filename:       avsplus.vim
" Language:       AviSynth+
" Maintainer:     Takuan <k4095 dot takuan at live dot jp>
" Version:        0.06
" Last Change:    2014 May 6

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

if exists("g:avs_operator")
    let s:avs_operator = g:avs_operator
else
    let s:avs_operator = 0
endif

" case insensitive
syn case ignore

" special variable
syn keyword avsSpecialVariable last

" operator "/"
syn match avsOperator "\%(/[;:@.]\=\|\^\=:\==\)"

" comment
syn keyword avsCommentTodo        TODO FIXME XXX TBD contained
syn region  avsCommentLine        start=/\%(^\|\s\+\)#/ end=/$/ contains=avsCommentTodo keepend oneline
syn region  avsCommentBlock       start="/\*" end="\*/"   contains=avsCommentTodo
syn region  avsCommentNestedBlock start=/\[\*/ end=/\*\]/ contains=avsCommentTodo,avsCommentNestedBlock
syn region  avsCommentEnd         start=/__END__/ skip=/./ end=/./ contains=avsCommentTodo

" global variable
syn keyword avsGlobalVariable global

" statements
syn keyword avsStatement            return break
syn keyword avsConditionalStatement if else
syn keyword avsRepeatStatement      for while

" line continuation
syn match avsLineContinueEnd   /\\\n/   contains=avsLineContinue
syn match avsLineContinueStart /^\s*\\/ contains=avsLineContinue
syn match avsLineContinue      /\\/     display contained

" boolean
syn keyword avsBoolean true false yes no

" number
syn match avsNumDecimal     /[+-]\=\<\d\+\%(\.\d\+\)\=\>/ display
syn match avsNumHexadecimal /\<0x\x\+\>/                  display
syn match avsNumHexColor    /\$\x\{1,8}\>/                display

" string
syn match  avsStringDoubleQuotation   /"[^"]*"/
syn region avsString3DoubleQuotations start=/"""/ end=/"""/

" operator
syn match avsOperator "[*+=:?-]"
syn match avsOperator "\%(!\|||\|&&\|%\)"
syn match avsOperator "\%([-:=]\=>\|<=\=\)"

" clip properties
syn keyword avsClipProperties
            \ Width Height FrameCount FrameRate FrameRateNumerator FrameRateDenominator
            \ AudioRate AudioLength AudioLengthLo AudioLengthHi AudioLengthF
            \ AudioLengthS AudioDuration AudioChannels AudioBits IsAudioFloat IsAudioInt
            \ IsRGB IsRGB24 IsRGB32 IsYUV IsYUY2 IsY8 IsYV12 IsYV16 IsYV24 IsYV411
            \ PixelType IsFieldBased IsFrameBased IsPlanar IsInterleaved
            \ GetParity HasAudio HasVideo

" try...error
syn keyword avsException    try catch
syn keyword avsErrorMessage err_msg

" internal functions
syn keyword avsBoolenFunctions
            \ IsBool IsClip IsFloat IsInt IsString
            \ Exist Defined FunctionExists
syn keyword avsControlFunctions
            \ Apply Eval Import Select Default Assert NOP UnDefined
            \ SetMemoryMax SetWorkingDir SetPlanarLegacyAlignment
            \ OPT_AllowFloatAudio OPT_UseWaveExtensible
            \ OPT_VDubPlanarHack OPT_dwChannelMask OPT_AVIPadScanlines
syn keyword avsConversionFunctions Value HexValue Hex String
syn keyword avsNumericFunctions
            \ Max Min MulDiv Floor Ceil Round Int Float
            \ Sin Cos Tan Asin Acos Atan Atan2 Sinh Cosh Tanh
            \ Fmod Pi Exp Log Log10 Pow Sqrt Abs
            \ Sign Frac Rand Spline ContinuedNumerator ContinuedDenominator
            \ BitAnd BitNot BitOr BitXor BitLShift BitShl BitSal
            \ BitRShiftL BitRShiftU BitShr BitRShiftA BitRShiftS BitSar
            \ BitLRotate BitRol BitRRotate BitRor BitTest BitTst
            \ BitSet BitClear BitClr BitChange BitChg
syn keyword avsRuntimeFunctions
            \ AverageLuma AverageChromaU AverageChromaV
            \ RGBDifference LumaDifference ChromaUDifference ChromaVDifference
            \ RGBDifferenceFromPrevious YDifferenceFromPrevious
            \ UDifferenceFromPrevious VDifferenceFromPrevious
            \ RGBDifferenceToNext YDifferenceToNext
            \ UDifferenceToNext VDifferenceToNext
            \ YPlaneMax UPlaneMax VPlaneMax YPlaneMin UPlaneMin VPlaneMin
            \ YPlaneMedian UPlaneMedian VPlaneMedian
            \ YPlaneMinMaxDifference UPlaneMinMaxDifference VPlaneMinMaxDifference
syn keyword avsScriptFunctions ScriptName ScriptFile ScriptDir
syn keyword avsStringFunctions
            \ LCase UCase StrLen RevStr LeftStr RightStr MidStr FindStr FillStr
            \ StrCmp StrCmpi Chr Orad Time
syn keyword avsVersionFunctions VersionNumber VersionString

" AviSynth+ specific
syn keyword avsPlusFunctions
            \ AddAutoloadDir ClearAutoloadDirs AutoloadPlugins
            \ SetFilterMTMode Prefetch
syn case match
"syn keyword avsPlusSpecialDirs
"            \ SCRIPTDIR MAINSCRIPTDIR PROGRAMDIR USER_PLUS_PLUGINS
"            \ MACHINE_PLUS_PLUGINS USER_CLASSIC_PLUGINS MACHINE_CLASSIC_PLUGINS
syn keyword avsPlusMTLevel MT_NICE_FILTER MT_MULTI_INSTANCE MT_SERIALIZED
syn case ignore

" internal filters
syn keyword avsMediaFileFilters
            \ AviSource OpenDMLSource AviFileSource DirectShowSource
            \ ImageReader ImageSource ImageSourceAnime ImageWriter
            \ SegmentedAviSource SegmentedDirectShowSource
            \ WavSource SoundOut
syn keyword avsColorFilters
            \ ColorYUV ConvertBackToYUY2 ConvertToRGB ConvertToRGB24 ConvertToRGB32
            \ ConvertToYUY2 ConvertToY8 ConvertToYV411 ConvertToYV12
            \ ConvertToYV16 ConvertToYV24 FixLuminance GreyScale GrayScale
            \ Invert Levels Limiter MergeARGB MergeRGB MergeChroma MergeLuma Merge
            \ RGBAdjust ShowAlpha ShowRed ShowGreen ShowBlue SwapUV Tweak
            \ UToY VToY UToY8 VToY8 YToUV
syn keyword avsOverlayMaskFilters
            \ ColorKeyMask Layer Mask MaskHS Overlay ResetMask Subtract
syn keyword avsGeometricFilters
            \ AddBorders Crop CropBottom FlipHorizonal FlipVertical
            \ Letterbox HorizontalReduceBy2 VerticalReduceBy2 ReduceBy2
            \ BicubicResize BilinearResize BlackmanResize GaussResize
            \ LanczosResize Lanczos4Resize PointResize SincResize
            \ Spline16Resize Spline36Resize Spline64Resize
            \ SkewRows TurnLeft TurnRight Turn180
syn keyword avsPixelRestorationFilters
            \ Blur Sharpen GeneralConvolution SpatialSoften
            \ TemporalSoften FixBrokenChromaUpsampling
syn keyword avsTimelineFilters
            \ AlignedSplice UnalignedSplice AssumeFPS AssumeScaledFPS
            \ ChangeFPS ConvertFPS DeleteFrame Dissolve DuplicateFrame
            \ FadeIn0 FadeIn FadeIn2 FadeOut0 FadeOut FadeOut2
            \ FadeIO0 FadeIO FadeIO2 FreezeFrame Interleave Loop Reverse
            \ SelectEven SelectOdd SelectEvery SelectRangeEvely Trim
syn keyword avsInterlaceFilters
            \ AssumeFrameBased AssumeFieldBased AssumeBFF AssumeTFF
            \ Bob ComplementParity DoubleWeave PeculiarBlend Pulldown
            \ SeparateColumns SeparateRows SeparateFields
            \ SwapFields Weave WeaveColumns WeaveRows
syn keyword avsAudioFilters
            \ Amplify AmplifydB AssumeSampleRate AudioDub AudioDubEx AudioTrim
            \ ConvertAudioTo8bit ConvertAudioTo16bit ConvertAudioTo24bit
            \ ConvertAudioTo32bit ConvertAudioToFloat ConvertToMono
            \ DelayAudio EnsureVBRMP3Sync GetChannel GetLeftChannel GetRightChannel
            \ KillAudio KillVideo MergeChannels MixAudio MonoToStereo
            \ Normalize ResampleAudio SuperEQ SSRC TimeStretch
syn keyword avsConditionalFilters
            \ ConditionalFilter FrameEvaluate ScriptClip ConditionalSelect
            \ ConditionalReader WriteFile WriteFileIf WriteFileStart WriteFileEnd
            \ Animate ApplyRange TCPServer TCPSource
syn keyword avsDebugFilters
            \ BlankClip Blackness ColorBars ColorBarsHD Compare Echo
            \ Histogram Info MessageClip ShowFiveVersions ShowFrameNumber
            \ ShowSMPTE ShowTime StackHorizontal StackVertical Subtitle Tone Version

" user defined script functions
syn region  avsUserDefinedFunctions start=/function/ end=/)/
            \ contains=avsFunction,avsVariableType,avsStringDoubleQuotation,avsLineContinue
syn keyword avsFunction     function contained
syn match   avsVariableType /\<\%(clip\|string\|int\|float\|bool\|val\)\>/ contained

" loading
syn keyword avsPluginLoad
            \ LoadPlugin LoadVirtualDubPlugin LoadVFAPIPlugin
            \ LoadCPlugin Load_Stdcall_Plugin

" runtime variable
syn keyword avsRuntimeVariable current_frame

" external filters
syn keyword avsExternalFilters
            \ LSMASHVideoSource LSMASHAudioSource LWLibavVideoSource LWLibavAudioSource
            \ flash3kyuu_deband f3kdb
            \ DGSource DGSourceIM
            \ CombMask IsCombed MaskedMerge
            \ nnedi3 TMM TDeint
            \ MSuper MAnalyse MFlowInter MDegrain1
            \ Dither_out DitherPost Dither_limit_dif16 Dither_resize16 Dither_repair16
            \ Dither_merge16
            \ mt_edge mt_expand mt_inflate mt_merge mt_lut
            \ RemoveGrain VerticalCleaner Repair
            \ tmaskcleaner
            \ FFT3DGPU fft3dfilter
            \ MosquitoNR
            \ SangNom2
            \ GetProgramName
            \ vinverse vinverse2
            \ Average

" user defined functios
syn keyword avsUserDefinedFunctions
            \ initialize_global_variables is_program get_src_path is_x86_64
            \ check_pulldown_cadence check_combed
            \ mosquitonr_wrapper resample_resize
            \ sangnom2_aa deband_10_or_16 add_black_frames detect_combed_frame
            \ check_fullrange detect_scene_change debug_view edge_msk
            \ post_denoise freezeframe_adjust trim_wrapper splice_wrapper
            \ replace_frame range_vincomb
            \ reverse_telecine_5 reverse_telecine_10 reverse_telecine_reconstruct_last_frame
            \ last_field_weave merge_reverse_telecine td_nnedi3 convert_60i_to_24p
            \ Dither_convert_yuv_to_rgb Dither_y_gamma_to_linear
            \ Dither_resize16nr Dither_y_linear_to_gamma
            \ Dither_convert_rgb_to_yuv

hi def link avsSpecialVariable         SpecialChar
hi def link avsCommentLine             Comment
hi def link avsCommentBlock            Comment
hi def link avsCommentNestedBlock      Comment
hi def link avsCommentEndD             Comment
hi def link avsCommentTodo             Todo
hi def link avsGlobalVariable          Keyword
hi def link avsStatement               Statement
hi def link avsConditionalStatement    Conditional
hi def link avsRepeatStatement         Repeat
hi def link avsLineContinue            Special
hi def link avsBoolean                 Boolean
hi def link avsNumDecimal              Number
hi def link avsHexadecimal             Number
hi def link avsNumHexColor             Special
hi def link avsStringDoubleQuotation   String
hi def link avsString3DoubleQuotations String
if s:avs_operator == 1
    hi def link avsOperator            Operator
end
hi def link avsClipProperties          Identifier
hi def link avsException               Exception
hi def link avsErrorMessage            Error
hi def link avsBoolenFunctions         Identifier
hi def link avsControlFunctions        Identifier
hi def link avsConversionFunctions     Identifier
hi def link avsNumericFunctions        Identifier
hi def link avsRuntimeFunctions        Identifier
hi def link avsScriptFunctions         Identifier
hi def link avsStringFunctions         Identifier
hi def link avsVersionFunctions        Identifier
hi def link avsPlusFunctions           Identifier
hi def link avsPlusMTLevel             SpecialChar
hi def link avsMediaFileFilters        Function
hi def link avsColorFilters            Function
hi def link avsOverlayMaskFilters      Function
hi def link avsGeometricFilters        Function
hi def link avsPixelRestorationFilters Function
hi def link avsTimelineFilters         Function
hi def link avsInterlaceFilters        Function
hi def link avsAudioFilters            Function
hi def link avsConditionalFilters      Function
hi def link avsDebugFilters            Debug
hi def link avsFunction                Statement
hi def link avsVariableType            Type
hi def link avsPluginLoad              Include
hi def link avsRuntimeVariable         SpecialChar
hi def link avsExternalFilters         Title "SpecialKey
hi def link avsUserDefinedFunctions    Macro

syn sync minlines=200
syn sync maxlines=500

let b:current_syntax = "avs"
