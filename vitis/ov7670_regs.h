#ifndef OV7670_REGS_H
#define OV7670_REGS_H

#include "xil_types.h"

#define OV7670_SCCB_ADDR_7BIT           0x21U

// register addresses
#define OV7670_REG_COM3                 0x0CU
#define OV7670_REG_COM7                 0x12U
#define OV7670_REG_COM13                0x3DU
#define OV7670_REG_COM14                0x3EU
#define OV7670_REG_COM15                0x40U
#define OV7670_REG_CLKRC                0x11U
#define OV7670_REG_DBLV                 0x6BU
#define OV7670_REG_TSLB                 0x3AU

// color correction registeers
#define OV7670_REG_MTX1                 0x4FU
#define OV7670_REG_MTX2                 0x50U
#define OV7670_REG_MTX3                 0x51U
#define OV7670_REG_MTX4                 0x52U
#define OV7670_REG_MTX5                 0x53U
#define OV7670_REG_MTX6                 0x54U
#define OV7670_REG_MTXS                 0x58U

// these makes the colors look normal for some reason???
#define OV7670_REG_RSVD_B0              0xB0U
#define OV7670_REG_SCALING_XSC          0x70U
#define OV7670_REG_SCALING_YSC          0x71U
#define OV7670_REG_SCALING_DCWCTR       0x72U
#define OV7670_REG_SCALING_PCLK_DIV     0x73U
#define OV7670_REG_SCALING_PCLK_DELAY   0xA2U

// auto white balance, fixes everything is a bit green
#define OV7670_REG_COM8                 0x13U
#define OV7670_REG_COM9                 0x14U
#define OV7670_REG_AWBC1                0x43U
#define OV7670_REG_AWBC2                0x44U
#define OV7670_REG_AWBC3                0x45U
#define OV7670_REG_AWBC4                0x46U
#define OV7670_REG_AWBC5                0x47U
#define OV7670_REG_AWBC6                0x48U
#define OV7670_REG_AWBCTR3              0x6CU
#define OV7670_REG_AWBCTR2              0x6DU
#define OV7670_REG_AWBCTR1              0x6EU
#define OV7670_REG_AWBCTR0              0x6FU

/* COM7 bit values */
#define OV7670_COM7_RESET               0x80U  // reset all registers
#define OV7670_COM7_RGB_VGA             0x04U  // bit2=1 RGB, no CIF/QVGA/QCIF bits = full VGA

#define OV7670_COM15_RGB565_FULLRANGE   0xD0U // [7:6]=11 full 0x00-0xff range, [5:4]=01 RGB565

//#define OV7670_REG_PSHFT                0x1BU

// these 3 registers fixes the black stripe on the left of the frame issue
#define OV7670_REG_HSTART               0x17U
#define OV7670_REG_HSTOP                0x18U
#define OV7670_REG_HREF                 0x32U

typedef struct {
    u8 reg;
    u8 val;
} OV7670_RegVal;

static const OV7670_RegVal OV7670_VgaRgb565Recipe[] = {
    { OV7670_REG_DBLV,                  0x3AU },
    { OV7670_REG_CLKRC,                 0x01U }, // vga baseline
    { OV7670_REG_COM3,                  0x00U }, // no scaling
    { OV7670_REG_COM14,                 0x00U }, // no manual pclk divide
    { OV7670_REG_TSLB,                  0x04U }, // correct RGB565 byte order

    //{ OV7670_REG_PSHFT,                 0x00U },

    // values i got from the linux driver for this camera
    { OV7670_REG_HSTART,                0x13U },
    { OV7670_REG_HSTOP,                 0x01U },
    { OV7670_REG_HREF,                  0xB6U },
    
    { OV7670_REG_SCALING_XSC,           0x3AU },
    { OV7670_REG_SCALING_YSC,           0x35U },
    { OV7670_REG_SCALING_DCWCTR,        0x11U },
    { OV7670_REG_SCALING_PCLK_DIV,      0xF0U },
    { OV7670_REG_SCALING_PCLK_DELAY,    0x02U },
    { OV7670_REG_COM7,                  OV7670_COM7_RGB_VGA },
    { OV7670_REG_COM15,                 OV7670_COM15_RGB565_FULLRANGE },

    // color correction
    { OV7670_REG_MTX1,                  0xB3U },
    { OV7670_REG_MTX2,                  0xB3U },
    { OV7670_REG_MTX3,                  0x00U },
    { OV7670_REG_MTX4,                  0x3DU },
    { OV7670_REG_MTX5,                  0xA7U },
    { OV7670_REG_MTX6,                  0xE4U },
    { OV7670_REG_COM13,                 0x40U }, // UV saturation auto-adjust
    { OV7670_REG_RSVD_B0,               0x84U }, 
    { OV7670_REG_COM8,                  0xE7U },  // AGC+AWB+AEC enable
    { OV7670_REG_COM9,                  0x6AU },  // 128x AGC gain ceiling
    { OV7670_REG_AWBC1,                 0x0AU },
    { OV7670_REG_AWBC2,                 0xF0U },
    { OV7670_REG_AWBC3,                 0x34U },
    { OV7670_REG_AWBC4,                 0x58U },
    { OV7670_REG_AWBC5,                 0x28U },
    { OV7670_REG_AWBC6,                 0x3AU },
    { OV7670_REG_AWBCTR3,               0x0AU },
    { OV7670_REG_AWBCTR2,               0x55U },
    { OV7670_REG_AWBCTR1,               0x11U },
    { OV7670_REG_AWBCTR0,               0x9EU },
};

#define OV7670_VGA_RGB565_RECIPE_LEN \
    (sizeof(OV7670_VgaRgb565Recipe) / sizeof(OV7670_VgaRgb565Recipe[0]))

#endif