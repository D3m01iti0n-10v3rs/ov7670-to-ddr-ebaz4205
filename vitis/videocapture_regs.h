#ifndef VIDEOCAPTURE_REGS_H
#define VIDEOCAPTURE_REGS_H

#include "xil_io.h"
#include "xil_types.h"

#define VIDEOCAPTURE_0_BASEADDR   0x40000000U

// register offset
#define VC_REG_CTRL_OFFSET       0x0U   // ctrl
#define VC_REG_MCLK_DIV_OFFSET   0x4U   // resets to 4, mclk_freq = ACLK/(N+2)
#define VC_REG_HWORDS_OFFSET     0x8U   // HWORDS, resets to 0, write before capture
// 0xc reserved

// ctrl bit pos
#define VC_CTRL_CAM_RST_BIT      0U   // passthrough
#define VC_CTRL_CAM_PWNN_BIT     1U   // passthrough
#define VC_CTRL_MCLK_EN_BIT      2U   // 1 = mclk toggling per MCLK_DIV, 0 = held low

// ctrl bit mask
#define VC_CTRL_CAM_RST_MASK     (1U << VC_CTRL_CAM_RST_BIT)
#define VC_CTRL_CAM_PWNN_MASK    (1U << VC_CTRL_CAM_PWNN_BIT)
#define VC_CTRL_MCLK_EN_MASK     (1U << VC_CTRL_MCLK_EN_BIT)

// VGA RGB565: HWORDS = pixel_width * 2 bytes / 4 bytes-per-word = 320 */
#define VC_HWORDS_VGA_RGB565     320U

static inline u32 VC_ReadReg(u32 Offset)
{
    return Xil_In32(VIDEOCAPTURE_0_BASEADDR + Offset);
}

static inline void VC_WriteReg(u32 Offset, u32 Value)
{
    Xil_Out32(VIDEOCAPTURE_0_BASEADDR + Offset, Value);
}

#endif