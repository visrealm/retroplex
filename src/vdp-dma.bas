' VDP DMA Helper - CVBasic Interface
' Provides CPU-side interface to GPU DMA operations
'
' Usage:
'   DMA_INIT($1800, $4100, 255, 8)  ' Set params and trigger DMA
'   DMA_WAIT                        ' Wait for completion

' DMA parameter block address (CPU-accessible VRAM)
CONST #DMA_PARAM_BLOCK          = $2F00

' GPU DMA entry point (adjust based on actual GPU code layout)
CONST #GPU_DMA_COPY             = $3F80

' Module variables for DMA operations
DIM #DMA_SRC ' Source VRAM address
DIM #DMA_DST ' Destination VRAM address
DIM DMA_WIDTH ' Width (bytes per row)
DIM DMA_HEIGHT ' Height (number of rows)

' Internal parameter buffer
DIM dmaParams(8)

' Lazy initialization flag
DIM dmaGpuLoaded

' Initialize DMA and trigger transfer (non-blocking)
DEF FN DMA_INIT(#S, #D, W, H) = #DMA_SRC = #S : #DMA_DST = #D : DMA_WIDTH = W : DMA_HEIGHT = H : GOSUB dmaCopy

' Wait for DMA completion
DEF FN DMA_WAIT = GOSUB gpuWait

' Internal: Trigger DMA copy (non-blocking)
dmaCopy: PROCEDURE
  ' Lazy load GPU DMA code on first use
  IF dmaGpuLoaded = 0 THEN
    DEFINE VRAM #GPU_DMA_COPY, VARPTR vdpDmaEnd(0) - VARPTR vdpDma(0), vdpDma
    dmaGpuLoaded = 1
  END IF

  ' Pack parameters (big-endian addresses)
  dmaParams(0) = #DMA_SRC / 256
  dmaParams(1) = #DMA_SRC
  dmaParams(2) = #DMA_DST / 256
  dmaParams(3) = #DMA_DST
  dmaParams(4) = DMA_WIDTH
  dmaParams(5) = DMA_HEIGHT
  dmaParams(6) = DMA_WIDTH ' stride = width
  dmaParams(7) = 0 ' params: normal copy

  ' Write parameters to VRAM
  DEFINE VRAM #DMA_PARAM_BLOCK, 8, VARPTR dmaParams(0)

  ' Trigger GPU DMA routine (non-blocking)
  VDP_REG($36) = #GPU_DMA_COPY / 256
  VDP_REG($37) = #GPU_DMA_COPY
END

' Include generated GPU binary
include "gen/gpu/vdp-dma.bin.bas"
