//The code below is adapted from this [github repository](https://github.com/haydenridd/stm32-baremetal-zig/tree/main)

comptime {
    @export(&g_pfnVectors, .{
        .name = "g_pfnVectors",
        .section = ".isr_vector",
        .linkage = .strong,
    });
}

//----------------------------------------------------------------------------
//  Linker generated Symbols
//----------------------------------------------------------------------------
/// Note is given the type "anyopaque" as this symbol is
/// only ever meant to be used by taking the address with &. It doesn't actually "point"
/// to anything valid at all!
extern const _estack: anyopaque;

//----------------------------------------------------------------------------
//  Exception / Interrupt Handler Function Prototype
//----------------------------------------------------------------------------
const IsrFunction = *const fn () callconv(.c) void;
const ResetHandlerFunction = *const fn () callconv(.naked) noreturn;

//----------------------------------------------------------------------------
//  External References
//----------------------------------------------------------------------------
const resetHandler = @import("startup.zig").resetHandler;

//----------------------------------------------------------------------------
//  Default Handler for Exceptions / Interrupts
//----------------------------------------------------------------------------
fn defaultHandler() callconv(.c) noreturn {
    @breakpoint();
    while (true) {}
}

//----------------------------------------------------------------------------
//  Exception / Interrupt Handler
//----------------------------------------------------------------------------
const NMI_Handler = @extern(IsrFunction, .{ .name = "NMI_Handler", .linkage = .weak });
const HardFault_Handler = @extern(IsrFunction, .{ .name = "HardFault_Handler", .linkage = .weak });
const MemManage_Handler = @extern(IsrFunction, .{ .name = "MemManage_Handler", .linkage = .weak });
const BusFault_Handler = @extern(IsrFunction, .{ .name = "BusFault_Handler", .linkage = .weak });
const UsageFault_Handler = @extern(IsrFunction, .{ .name = "UsageFault_Handler", .linkage = .weak });
const SVC_Handler = @extern(IsrFunction, .{ .name = "SVC_Handler", .linkage = .weak });
const DebugMon_Handler = @extern(IsrFunction, .{ .name = "DebugMon_Handler", .linkage = .weak });
const PendSV_Handler = @extern(IsrFunction, .{ .name = "PendSV_Handler", .linkage = .weak });
const SysTick_Handler = @extern(IsrFunction, .{ .name = "SysTick_Handler", .linkage = .weak });

// ARM CM4 Specific Interrupts
const WWDG_IRQHandler = @extern(IsrFunction, .{ .name = "WWDG_IRQHandler", .linkage = .weak });
const PVD_IRQHandler = @extern(IsrFunction, .{ .name = "PVD_IRQHandler", .linkage = .weak });
const TAMP_STAMP_IRQHandler = @extern(IsrFunction, .{ .name = "TAMP_STAMP_IRQHandler", .linkage = .weak });
const RTC_WKUP_IRQHandler = @extern(IsrFunction, .{ .name = "RTC_WKUP_IRQHandler", .linkage = .weak });
const FLASH_IRQHandler = @extern(IsrFunction, .{ .name = "FLASH_IRQHandler", .linkage = .weak });
const RCC_IRQHandler = @extern(IsrFunction, .{ .name = "RCC_IRQHandler", .linkage = .weak });
const EXTI0_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI0_IRQHandler", .linkage = .weak });
const EXTI1_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI1_IRQHandler", .linkage = .weak });
const EXTI2_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI2_IRQHandler", .linkage = .weak });
const EXTI3_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI3_IRQHandler", .linkage = .weak });
const EXTI4_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI4_IRQHandler", .linkage = .weak });
const DMA1_Stream0_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream0_IRQHandler", .linkage = .weak });
const DMA1_Stream1_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream1_IRQHandler", .linkage = .weak });
const DMA1_Stream2_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream2_IRQHandler", .linkage = .weak });
const DMA1_Stream3_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream3_IRQHandler", .linkage = .weak });
const DMA1_Stream4_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream4_IRQHandler", .linkage = .weak });
const DMA1_Stream5_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream5_IRQHandler", .linkage = .weak });
const DMA1_Stream6_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream6_IRQHandler", .linkage = .weak });
const ADC_IRQHandler = @extern(IsrFunction, .{ .name = "ADC_IRQHandler", .linkage = .weak });
const CAN1_TX_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_TX_IRQHandler", .linkage = .weak });
const CAN1_RX0_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_RX0_IRQHandler", .linkage = .weak });
const CAN1_RX1_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_RX1_IRQHandler", .linkage = .weak });
const CAN1_SCE_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_SCE_IRQHandler", .linkage = .weak });
const EXTI9_5_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI9_5_IRQHandler", .linkage = .weak });
const TIM1_BRK_TIM9_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_BRK_TIM9_IRQHandler", .linkage = .weak });
const TIM1_UP_TIM10_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_UP_TIM10_IRQHandler", .linkage = .weak });
const TIM1_TRG_COM_TIM11_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_TRG_COM_TIM11_IRQHandler", .linkage = .weak });
const TIM1_CC_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_CC_IRQHandler", .linkage = .weak });
const TIM2_IRQHandler = @extern(IsrFunction, .{ .name = "TIM2_IRQHandler", .linkage = .weak });
const TIM3_IRQHandler = @extern(IsrFunction, .{ .name = "TIM3_IRQHandler", .linkage = .weak });
const TIM4_IRQHandler = @extern(IsrFunction, .{ .name = "TIM4_IRQHandler", .linkage = .weak });
const I2C1_EV_IRQHandler = @extern(IsrFunction, .{ .name = "I2C1_EV_IRQHandler", .linkage = .weak });
const I2C1_ER_IRQHandler = @extern(IsrFunction, .{ .name = "I2C1_ER_IRQHandler", .linkage = .weak });
const I2C2_EV_IRQHandler = @extern(IsrFunction, .{ .name = "I2C2_EV_IRQHandler", .linkage = .weak });
const I2C2_ER_IRQHandler = @extern(IsrFunction, .{ .name = "I2C2_ER_IRQHandler", .linkage = .weak });
const SPI1_IRQHandler = @extern(IsrFunction, .{ .name = "SPI1_IRQHandler", .linkage = .weak });
const SPI2_IRQHandler = @extern(IsrFunction, .{ .name = "SPI2_IRQHandler", .linkage = .weak });
const USART1_IRQHandler = @extern(IsrFunction, .{ .name = "USART1_IRQHandler", .linkage = .weak });
const USART2_IRQHandler = @extern(IsrFunction, .{ .name = "USART2_IRQHandler", .linkage = .weak });
const USART3_IRQHandler = @extern(IsrFunction, .{ .name = "USART3_IRQHandler", .linkage = .weak });
const EXTI15_10_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI15_10_IRQHandler", .linkage = .weak });
const RTC_Alarm_IRQHandler = @extern(IsrFunction, .{ .name = "RTC_Alarm_IRQHandler", .linkage = .weak });
const OTG_FS_WKUP_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_FS_WKUP_IRQHandler", .linkage = .weak });
const TIM8_BRK_TIM12_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_BRK_TIM12_IRQHandler", .linkage = .weak });
const TIM8_UP_TIM13_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_UP_TIM13_IRQHandler", .linkage = .weak });
const TIM8_TRG_COM_TIM14_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_TRG_COM_TIM14_IRQHandler", .linkage = .weak });
const TIM8_CC_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_CC_IRQHandler", .linkage = .weak });
const DMA1_Stream7_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Stream7_IRQHandler", .linkage = .weak });
const FSMC_IRQHandler = @extern(IsrFunction, .{ .name = "FSMC_IRQHandler", .linkage = .weak });
const SDIO_IRQHandler = @extern(IsrFunction, .{ .name = "SDIO_IRQHandler", .linkage = .weak });
const TIM5_IRQHandler = @extern(IsrFunction, .{ .name = "TIM5_IRQHandler", .linkage = .weak });
const SPI3_IRQHandler = @extern(IsrFunction, .{ .name = "SPI3_IRQHandler", .linkage = .weak });
const UART4_IRQHandler = @extern(IsrFunction, .{ .name = "UART4_IRQHandler", .linkage = .weak });
const UART5_IRQHandler = @extern(IsrFunction, .{ .name = "UART5_IRQHandler", .linkage = .weak });
const TIM6_DAC_IRQHandler = @extern(IsrFunction, .{ .name = "TIM6_DAC_IRQHandler", .linkage = .weak });
const TIM7_IRQHandler = @extern(IsrFunction, .{ .name = "TIM7_IRQHandler", .linkage = .weak });
const DMA2_Stream0_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream0_IRQHandler", .linkage = .weak });
const DMA2_Stream1_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream1_IRQHandler", .linkage = .weak });
const DMA2_Stream2_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream2_IRQHandler", .linkage = .weak });
const DMA2_Stream3_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream3_IRQHandler", .linkage = .weak });
const DMA2_Stream4_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream4_IRQHandler", .linkage = .weak });
const ETH_IRQHandler = @extern(IsrFunction, .{ .name = "ETH_IRQHandler", .linkage = .weak });
const ETH_WKUP_IRQHandler = @extern(IsrFunction, .{ .name = "ETH_WKUP_IRQHandler", .linkage = .weak });
const CAN2_TX_IRQHandler = @extern(IsrFunction, .{ .name = "CAN2_TX_IRQHandler", .linkage = .weak });
const CAN2_RX0_IRQHandler = @extern(IsrFunction, .{ .name = "CAN2_RX0_IRQHandler", .linkage = .weak });
const CAN2_RX1_IRQHandler = @extern(IsrFunction, .{ .name = "CAN2_RX1_IRQHandler", .linkage = .weak });
const CAN2_SCE_IRQHandler = @extern(IsrFunction, .{ .name = "CAN2_SCE_IRQHandler", .linkage = .weak });
const OTG_FS_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_FS_IRQHandler", .linkage = .weak });
const DMA2_Stream5_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream5_IRQHandler", .linkage = .weak });
const DMA2_Stream6_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream6_IRQHandler", .linkage = .weak });
const DMA2_Stream7_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Stream7_IRQHandler", .linkage = .weak });
const USART6_IRQHandler = @extern(IsrFunction, .{ .name = "USART6_IRQHandler", .linkage = .weak });
const I2C3_EV_IRQHandler = @extern(IsrFunction, .{ .name = "I2C3_EV_IRQHandler", .linkage = .weak });
const I2C3_ER_IRQHandler = @extern(IsrFunction, .{ .name = "I2C3_ER_IRQHandler", .linkage = .weak });
const OTG_HS_EP1_OUT_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_HS_EP1_OUT_IRQHandler", .linkage = .weak });
const OTG_HS_EP1_IN_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_HS_EP1_IN_IRQHandler", .linkage = .weak });
const OTG_HS_WKUP_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_HS_WKUP_IRQHandler", .linkage = .weak });
const OTG_HS_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_HS_IRQHandler", .linkage = .weak });
const DCMI_IRQHandler = @extern(IsrFunction, .{ .name = "DCMI_IRQHandler", .linkage = .weak });
const HASH_RNG_IRQHandler = @extern(IsrFunction, .{ .name = "HASH_RNG_IRQHandler", .linkage = .weak });
const FPU_IRQHandler = @extern(IsrFunction, .{ .name = "FPU_IRQHandler", .linkage = .weak });

//----------------------------------------------------------------------------
// Exception / Interrupt Vector table
//----------------------------------------------------------------------------
const g_pfnVectors: VectorTable = .{};

const VectorTable = extern struct {
    initial_stack_pointer: *const anyopaque = &_estack,
    resetHandler: ResetHandlerFunction = resetHandler,
    NMI_Handler: IsrFunction = NMI_Handler orelse defaultHandler,
    HardFault_Handler: IsrFunction = HardFault_Handler orelse defaultHandler,
    MemManage_Handler: IsrFunction = MemManage_Handler orelse defaultHandler,
    BusFault_Handler: IsrFunction = BusFault_Handler orelse defaultHandler,
    UsageFault_Handler: IsrFunction = UsageFault_Handler orelse defaultHandler,
    reserved1: [4]u32 = undefined,
    SVC_Handler: IsrFunction = SVC_Handler orelse defaultHandler,
    DebugMon_Handler: IsrFunction = DebugMon_Handler orelse defaultHandler,
    reserved2: u32 = undefined,
    PendSV_Handler: IsrFunction = PendSV_Handler orelse defaultHandler,
    SysTick_Handler: IsrFunction = SysTick_Handler orelse defaultHandler,
    WWDG_IRQHandler: IsrFunction = WWDG_IRQHandler orelse defaultHandler,
    PVD_IRQHandler: IsrFunction = PVD_IRQHandler orelse defaultHandler,
    TAMP_STAMP_IRQHandler: IsrFunction = TAMP_STAMP_IRQHandler orelse defaultHandler,
    RTC_WKUP_IRQHandler: IsrFunction = RTC_WKUP_IRQHandler orelse defaultHandler,
    FLASH_IRQHandler: IsrFunction = FLASH_IRQHandler orelse defaultHandler,
    RCC_IRQHandler: IsrFunction = RCC_IRQHandler orelse defaultHandler,
    EXTI0_IRQHandler: IsrFunction = EXTI0_IRQHandler orelse defaultHandler,
    EXTI1_IRQHandler: IsrFunction = EXTI1_IRQHandler orelse defaultHandler,
    EXTI2_IRQHandler: IsrFunction = EXTI2_IRQHandler orelse defaultHandler,
    EXTI3_IRQHandler: IsrFunction = EXTI3_IRQHandler orelse defaultHandler,
    EXTI4_IRQHandler: IsrFunction = EXTI4_IRQHandler orelse defaultHandler,
    DMA1_Stream0_IRQHandler: IsrFunction = DMA1_Stream0_IRQHandler orelse defaultHandler,
    DMA1_Stream1_IRQHandler: IsrFunction = DMA1_Stream1_IRQHandler orelse defaultHandler,
    DMA1_Stream2_IRQHandler: IsrFunction = DMA1_Stream2_IRQHandler orelse defaultHandler,
    DMA1_Stream3_IRQHandler: IsrFunction = DMA1_Stream3_IRQHandler orelse defaultHandler,
    DMA1_Stream4_IRQHandler: IsrFunction = DMA1_Stream4_IRQHandler orelse defaultHandler,
    DMA1_Stream5_IRQHandler: IsrFunction = DMA1_Stream5_IRQHandler orelse defaultHandler,
    DMA1_Stream6_IRQHandler: IsrFunction = DMA1_Stream6_IRQHandler orelse defaultHandler,
    ADC_IRQHandler: IsrFunction = ADC_IRQHandler orelse defaultHandler,
    CAN1_TX_IRQHandler: IsrFunction = CAN1_TX_IRQHandler orelse defaultHandler,
    CAN1_RX0_IRQHandler: IsrFunction = CAN1_RX0_IRQHandler orelse defaultHandler,
    CAN1_RX1_IRQHandler: IsrFunction = CAN1_RX1_IRQHandler orelse defaultHandler,
    CAN1_SCE_IRQHandler: IsrFunction = CAN1_SCE_IRQHandler orelse defaultHandler,
    EXTI9_5_IRQHandler: IsrFunction = EXTI9_5_IRQHandler orelse defaultHandler,
    TIM1_BRK_TIM9_IRQHandler: IsrFunction = TIM1_BRK_TIM9_IRQHandler orelse defaultHandler,
    TIM1_UP_TIM10_IRQHandler: IsrFunction = TIM1_UP_TIM10_IRQHandler orelse defaultHandler,
    TIM1_TRG_COM_TIM11_IRQHandler: IsrFunction = TIM1_TRG_COM_TIM11_IRQHandler orelse defaultHandler,
    TIM1_CC_IRQHandler: IsrFunction = TIM1_CC_IRQHandler orelse defaultHandler,
    TIM2_IRQHandler: IsrFunction = TIM2_IRQHandler orelse defaultHandler,
    TIM3_IRQHandler: IsrFunction = TIM3_IRQHandler orelse defaultHandler,
    TIM4_IRQHandler: IsrFunction = TIM4_IRQHandler orelse defaultHandler,
    I2C1_EV_IRQHandler: IsrFunction = I2C1_EV_IRQHandler orelse defaultHandler,
    I2C1_ER_IRQHandler: IsrFunction = I2C1_ER_IRQHandler orelse defaultHandler,
    I2C2_EV_IRQHandler: IsrFunction = I2C2_EV_IRQHandler orelse defaultHandler,
    I2C2_ER_IRQHandler: IsrFunction = I2C2_ER_IRQHandler orelse defaultHandler,
    SPI1_IRQHandler: IsrFunction = SPI1_IRQHandler orelse defaultHandler,
    SPI2_IRQHandler: IsrFunction = SPI2_IRQHandler orelse defaultHandler,
    USART1_IRQHandler: IsrFunction = USART1_IRQHandler orelse defaultHandler,
    USART2_IRQHandler: IsrFunction = USART2_IRQHandler orelse defaultHandler,
    USART3_IRQHandler: IsrFunction = USART3_IRQHandler orelse defaultHandler,
    EXTI15_10_IRQHandler: IsrFunction = EXTI15_10_IRQHandler orelse defaultHandler,
    RTC_Alarm_IRQHandler: IsrFunction = RTC_Alarm_IRQHandler orelse defaultHandler,
    OTG_FS_WKUP_IRQHandler: IsrFunction = OTG_FS_WKUP_IRQHandler orelse defaultHandler,
    TIM8_BRK_TIM12_IRQHandler: IsrFunction = TIM8_BRK_TIM12_IRQHandler orelse defaultHandler,
    TIM8_UP_TIM13_IRQHandler: IsrFunction = TIM8_UP_TIM13_IRQHandler orelse defaultHandler,
    TIM8_TRG_COM_TIM14_IRQHandler: IsrFunction = TIM8_TRG_COM_TIM14_IRQHandler orelse defaultHandler,
    TIM8_CC_IRQHandler: IsrFunction = TIM8_CC_IRQHandler orelse defaultHandler,
    DMA1_Stream7_IRQHandler: IsrFunction = DMA1_Stream7_IRQHandler orelse defaultHandler,
    FSMC_IRQHandler: IsrFunction = FSMC_IRQHandler orelse defaultHandler,
    SDIO_IRQHandler: IsrFunction = SDIO_IRQHandler orelse defaultHandler,
    TIM5_IRQHandler: IsrFunction = TIM5_IRQHandler orelse defaultHandler,
    SPI3_IRQHandler: IsrFunction = SPI3_IRQHandler orelse defaultHandler,
    UART4_IRQHandler: IsrFunction = UART4_IRQHandler orelse defaultHandler,
    UART5_IRQHandler: IsrFunction = UART5_IRQHandler orelse defaultHandler,
    TIM6_DAC_IRQHandler: IsrFunction = TIM6_DAC_IRQHandler orelse defaultHandler,
    TIM7_IRQHandler: IsrFunction = TIM7_IRQHandler orelse defaultHandler,
    DMA2_Stream0_IRQHandler: IsrFunction = DMA2_Stream0_IRQHandler orelse defaultHandler,
    DMA2_Stream1_IRQHandler: IsrFunction = DMA2_Stream1_IRQHandler orelse defaultHandler,
    DMA2_Stream2_IRQHandler: IsrFunction = DMA2_Stream2_IRQHandler orelse defaultHandler,
    DMA2_Stream3_IRQHandler: IsrFunction = DMA2_Stream3_IRQHandler orelse defaultHandler,
    DMA2_Stream4_IRQHandler: IsrFunction = DMA2_Stream4_IRQHandler orelse defaultHandler,
    ETH_IRQHandler: IsrFunction = ETH_IRQHandler orelse defaultHandler,
    ETH_WKUP_IRQHandler: IsrFunction = ETH_WKUP_IRQHandler orelse defaultHandler,
    CAN2_TX_IRQHandler: IsrFunction = CAN2_TX_IRQHandler orelse defaultHandler,
    CAN2_RX0_IRQHandler: IsrFunction = CAN2_RX0_IRQHandler orelse defaultHandler,
    CAN2_RX1_IRQHandler: IsrFunction = CAN2_RX1_IRQHandler orelse defaultHandler,
    CAN2_SCE_IRQHandler: IsrFunction = CAN2_SCE_IRQHandler orelse defaultHandler,
    OTG_FS_IRQHandler: IsrFunction = OTG_FS_IRQHandler orelse defaultHandler,
    DMA2_Stream5_IRQHandler: IsrFunction = DMA2_Stream5_IRQHandler orelse defaultHandler,
    DMA2_Stream6_IRQHandler: IsrFunction = DMA2_Stream6_IRQHandler orelse defaultHandler,
    DMA2_Stream7_IRQHandler: IsrFunction = DMA2_Stream7_IRQHandler orelse defaultHandler,
    USART6_IRQHandler: IsrFunction = USART6_IRQHandler orelse defaultHandler,
    I2C3_EV_IRQHandler: IsrFunction = I2C3_EV_IRQHandler orelse defaultHandler,
    I2C3_ER_IRQHandler: IsrFunction = I2C3_ER_IRQHandler orelse defaultHandler,
    OTG_HS_EP1_OUT_IRQHandler: IsrFunction = OTG_HS_EP1_OUT_IRQHandler orelse defaultHandler,
    OTG_HS_EP1_IN_IRQHandler: IsrFunction = OTG_HS_EP1_IN_IRQHandler orelse defaultHandler,
    OTG_HS_WKUP_IRQHandler: IsrFunction = OTG_HS_WKUP_IRQHandler orelse defaultHandler,
    OTG_HS_IRQHandler: IsrFunction = OTG_HS_IRQHandler orelse defaultHandler,
    DCMI_IRQHandler: IsrFunction = DCMI_IRQHandler orelse defaultHandler,
    reserved3: u32 = undefined,
    HASH_RNG_IRQHandler: IsrFunction = HASH_RNG_IRQHandler orelse defaultHandler,
    FPU_IRQHandler: IsrFunction = FPU_IRQHandler orelse defaultHandler,
};
