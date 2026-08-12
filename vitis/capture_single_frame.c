#include <string.h>
#include "xaxivdma.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xstatus.h"
#include "sleep.h"

#include "ov7670_init.h"
#include "videocapture_regs.h"

#define FRAME_HSIZE_BYTES   1280U   // 640 px * 2 bytes/px
#define FRAME_VSIZE_LINES   480U
#define FRAME_STRIDE_BYTES  1280U

#define FRAME_BUF_ADDR      0x00100000U

// long wait after starting vdma before assuming the frame has arrived
#define FRAME_WAIT_MS       200U

static XAxiVdma AxiVdma;

static int ConfigureVdmaSingleFrame(void)
{
    XAxiVdma_Config *Config;
    XAxiVdma_DmaSetup WriteCfg;
    UINTPTR FrameAddr[1];
    int Status;

    Config = XAxiVdma_LookupConfig(XPAR_XAXIVDMA_0_BASEADDR);
    if (Config == NULL) {
        xil_printf("VDMA config lookup failed\r\n");
        return XST_FAILURE;
    }

    Status = XAxiVdma_CfgInitialize(&AxiVdma, Config, Config->BaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA CfgInitialize failed (status %d)\r\n", Status);
        return Status;
    }

    memset(&WriteCfg, 0, sizeof(WriteCfg));
    WriteCfg.VertSizeInput   = FRAME_VSIZE_LINES;
    WriteCfg.HoriSizeInput   = FRAME_HSIZE_BYTES;
    WriteCfg.Stride          = FRAME_STRIDE_BYTES;
    WriteCfg.FrameDelay      = 0;
    WriteCfg.EnableCircularBuf = 0;  // park mode
    WriteCfg.EnableSync      = 0;
    WriteCfg.PointNum        = 0;
    WriteCfg.EnableFrameCounter = 0;
    WriteCfg.FixedFrameStoreAddr = 0;

    Status = XAxiVdma_DmaConfig(&AxiVdma, XAXIVDMA_WRITE, &WriteCfg);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA DmaConfig (S2MM) failed (status %d)\r\n", Status);
        return Status;
    }

    FrameAddr[0] = FRAME_BUF_ADDR;
    Status = XAxiVdma_DmaSetBufferAddr(&AxiVdma, XAXIVDMA_WRITE, FrameAddr);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA DmaSetBufferAddr (S2MM) failed (status %d)\r\n", Status);
        return Status;
    }

    return XST_SUCCESS;
}

int main(void)
{
    int Status;

    // conf cam
    Status = OV7670_Init();
    if (Status != XST_SUCCESS) {
        xil_printf("Camera init failed, aborting.\r\n");
        return XST_FAILURE;
    }

    // conf vdma
    Status = ConfigureVdmaSingleFrame();
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA configuration failed, aborting.\r\n");
        return XST_FAILURE;
    }

    // start vdma
    xil_printf("Starting VDMA S2MM (Park mode, single frame)...\r\n");
    Status = XAxiVdma_DmaStart(&AxiVdma, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS) {
        xil_printf("VDMA DmaStart (S2MM) failed (status %d)\r\n", Status);
        return XST_FAILURE;
    }

    usleep(FRAME_WAIT_MS * 1000U);

    xil_printf("Done. Frame at DDR address 0x%08x,\r\n", FRAME_BUF_ADDR);
    xil_printf("%d bytes (640x480 RGB565, %d bytes/line, %d lines).\r\n", (int)(FRAME_HSIZE_BYTES * FRAME_VSIZE_LINES), (int)FRAME_HSIZE_BYTES, (int)FRAME_VSIZE_LINES);

    return XST_SUCCESS;
}