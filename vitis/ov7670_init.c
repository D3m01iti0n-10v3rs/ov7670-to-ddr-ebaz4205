#include "ov7670_init.h"
#include "ov7670_regs.h"
#include "videocapture_regs.h"

#include "xiicps.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xparameters.h"

#define SCCB_CLK_HZ   100000U

static XIicPs Iic;

static int SCCB_WriteReg(u8 RegAddr, u8 Value)
{
    u8 Buf[2];
    int Status;

    Buf[0] = RegAddr;
    Buf[1] = Value;

    Status = XIicPs_MasterSendPolled(&Iic, Buf, 2, OV7670_SCCB_ADDR_7BIT);
    if (Status != XST_SUCCESS) {
        xil_printf("SCCB write failed: reg 0x%02x val 0x%02x (status %d)\r\n",
                   RegAddr, Value, Status);
        return Status;
    }

    // wait for bus to go idle
    while (XIicPs_BusIsBusy(&Iic)) { }

    return XST_SUCCESS;
}

static int SCCB_Init(void)
{
    XIicPs_Config *Config;
    int Status;

    Config = XIicPs_LookupConfig(XPAR_XIICPS_0_BASEADDR);
    if (Config == NULL) {
        return XST_FAILURE;
    }

    Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);
    if (Status != XST_SUCCESS) {
        return Status;
    }

    Status = XIicPs_SetSClk(&Iic, SCCB_CLK_HZ);
    if (Status != XST_SUCCESS) {
        return Status;
    }

    return XST_SUCCESS;
}

int OV7670_Init(void)
{
    int Status;
    u32 i;

    // bring up MCLK before touching reset
    VC_WriteReg(VC_REG_MCLK_DIV_OFFSET, 2U);
    VC_WriteReg(VC_REG_CTRL_OFFSET, VC_CTRL_MCLK_EN_MASK);
    usleep(1000);

    // pwdn active high, reset actiev low
    VC_WriteReg(VC_REG_CTRL_OFFSET, VC_CTRL_MCLK_EN_MASK | VC_CTRL_CAM_RST_MASK); // pwdn =0, rst = 1
    usleep(1000);
    VC_WriteReg(VC_REG_CTRL_OFFSET, VC_CTRL_MCLK_EN_MASK); // pwdn = 0, rst = 0
    usleep(1000);

    // write hword before capture
    VC_WriteReg(VC_REG_HWORDS_OFFSET, VC_HWORDS_VGA_RGB565);

    // start i2c
    Status = SCCB_Init();
    if (Status != XST_SUCCESS) {
        xil_printf("I2C0 init failed (status %d)\r\n", Status);
        return Status;
    }

    // i2c soft reset
    Status = SCCB_WriteReg(OV7670_REG_COM7, OV7670_COM7_RESET);
    if (Status != XST_SUCCESS) {
        return Status;
    }
    // SCCB ACK only confirms the bus transaction landed not the chip's internal reset actually finished
    usleep(100000);

    // conf the camera
    for (i = 0; i < OV7670_VGA_RGB565_RECIPE_LEN; i++) {
        Status = SCCB_WriteReg(OV7670_VgaRgb565Recipe[i].reg,
                                OV7670_VgaRgb565Recipe[i].val);
        if (Status != XST_SUCCESS) {
            xil_printf("Recipe write %d/%d failed\r\n",
                       (int)i, (int)OV7670_VGA_RGB565_RECIPE_LEN);
            return Status;
        }
    }

    xil_printf("OV7670 SCCB init complete (%d registers written)\r\n",
               (int)OV7670_VGA_RGB565_RECIPE_LEN);

    return XST_SUCCESS;
}